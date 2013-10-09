#include <tads.h>
#include <httpsrv.h>
#include <httpreq.h>
#include <file.h>
#include <date.h>

/*
 * Provides the web-based menu-driven user interface for your TADS game.  
 * Requires skald.h, but you could possibly modify it to use a different 
 * UI with this same (primitive) server.
 *
 * To include this server in your game, do the following:
 * 
 * 1) Use the normal adv3/adv3 library
 *
 * 2) Close any open TADS workbench and open your .t3m file in a plain 
 * text-editor.  Make the following changes:
 * 
 *   a) Add -D TADS_INCLUDE_NET near the top, after comments, before any 
 *      other options.  (If you get compile errors about NetEvRequest 
 *      not defined, you probably forgot this step.)
 *
 *   b) Add -source tadsnet as your last source file. 
 *      (If you get a couple warnings about evRequest property not being
 *       defined and then your resulting server is unresponsive, you 
 *       probably forgot this step.)
 *
 * 3) Copy the tads-skald subfolder into your project.  The Skald web
 * files go in the tads-skald/htdocs folder.  (You can change this name 
 * by modifying skaldServer.ROOT.)  
 * Then add this folder as a resource to your .t3m file:  
 *   -res tads-skald/htdocs
 *
 * See skald.h for the configuration required and how to call 
 * skaldServer.start() to get the server going.
 *
 *  Author: Zach Tomaszewski
 *  Version: May 2013
 */
 
/* Write to server buffer if server is running, else to normal tadsSay fn.*/
replace aioSay(txt) {
    if (skaldServer.server && skaldServer.buffer) {
        skaldServer.buffer.append(txt);
    }else {
        tadsSay(txt); 
    }
}

replace checkHtmlMode() {
  return true;
}

//#define AHREF_Command 0x0004
/* 
 *   Modified to add required ? in front of link by default. 
 *   If not href is not a command, override flags.
 *   Also, link has no javascript embedded.
 */
/*
replace aHref(href, txt?, title?, flags=AHREF_Command) {

    if (skaldServer.server) {
        // must be in HTML mode
        // (code based on browser.t's aHref)
        local props = '';
        if (flags & AHREF_Plain)
            props += 'class="plain" ';

        local str = '<a <<props>> href="';
        str += '<<flags & AHREF_Command ? '?' : ''>>';
        str += href.findReplace('"', '%22') + '"';
        str += (title != nil 
                ? ' title="' + title.findReplace('"', '&#34;') + '"' 
                : '');
        str += '><<txt != nil ? '<.a>' + txt + '<./a>' : ''>></a>';
        return str;
    }else {        
        //plain text mode
        return txt;
    }
}
*/
    
/*
 *   TADS is fairly complicated in terms of turn-taking.  Actors are
 *   Schedulable, and more that one may need to be managed. The main game loop
 *   then calls runScheduler to handle these different requirements.  For the
 *   PC, this boils down to calling executeTurn() -> executeActorTurn()
 *   (assuming the PC is currently idle and does not have other requirements to
 *   fulfill).  Even executeActorTurn does a fair amount of work.
 *
 *   In order to avoid potential problems from trashing this whole cycle, Skald
 *   hooks in at this low level: when executeActorTurn() for the PC finally
 *   prompts the user for a string of input.  "which" specifies what kind of
 *   prompt to use.
 *
 *   This replacement for readMainCommand instead lets the server process
 *   requests until it receive a cmd sent from the GUI.  The side-effect of then
 *   running the cmd through the normal TADS parser is that the sent cmd must be
 *   parse unambiguously under normal TADS conditions.
 */    
replace readMainCommand(which)
{
    if (skaldServer.server && which != rmcCommand) {
        tadsSay('Prompting for something other than normal rmcCommand input: ' + 
                toString(which) + '\n');
    }
    // execute any pre-command-prompt daemons 
    eventManager.executePrompt();  //as per original readMainCommand
    if (skaldServer.server) {
      return skaldServer.processRequests();  //waits until next cmd text recv'd
    }else {
      //ORIGINAL rMC behavior
      return inputManager.getInputLine(true, {: gLibMessages.mainCommandPrompt(which)});
    }
}

/*
 *   This is a crude server implementation.  It does not currently run in a
 *   separate thread.  Instead, it trades control back and forth between the 
 *   main runGame/schedule loop.  Whenever the game is waiting for user input, 
 *   the server is free to handle the HTTP request queue.  Once a cmd is 
 *   received from the Skald GUI, the server passes that cmd to the game 
 *   loop as user input.  When the game loop reaches the next prompt for input 
 *   and control returns to the server, the server will send a reply to the 
 *   user's cmd containing all of that turn's output and then wait for new cmd 
 *   inputs.
 */
skaldServer : object 
    
    server = nil    //should be activated by calling skaldServer.start()
    buffer = nil
    pendingRequest = nil  //a previous (cmd) request that we need to send output for
    hostname = getLocalIP() //getLaunchHostAddr()  //or getLocalIP()getLaunchHostAddr()
    port = 49000
    quit = nil      //once true, the server will shutdown next chance it has
    connectionTimeout = nil  //if no UI requests received after this time, 
                               //shuts down the server.  Set to nil to never timeout.
    
    /*
     *   What level of detail to print to stdout.  The steps are cumulative 
     *   0 - None.
     *   1 - Errors, warnings, and essential info such as server start/end.
     *   2 - Each CMD or INIT request.
     *   3 - Each server GET request.
     *   4 - Additional debug info
     */
    LOG_LEVEL = 3
    
    /* 
     *   Folder the holds the files that the web server should serve up.
     *   As a URL relative to the server root, this must begin but not end 
     *   with a / character.  For '/', just use ''.
     */
    ROOT = '/tads-skald/htdocs'    
    
    /*
     *   The module or folder in which the UI files are located.  Requests sent
     *   to the server will be relative to these originally-served UI files.
     *   Should begin and end with a / or just be '/'.
     */
    MODULE = '/skald/'
    
    /* Start the server. */
    start() {
//        local now = new Date();
//        local timestamp = now.formatDate('%Y-%m-%dT%H:%M:%S');
        if (self.LOG_LEVEL >= 1) "HTTP Server starting... ";
        self.server = new HTTPServer(self.hostname, self.port); 
        if (self.LOG_LEVEL >= 1) "listening on port <<server.getPortNum()>>\n";
        buffer = new StringBuffer();
        quit = nil;
    }
    
    /* 
     * Given a turn's HTML output, returns the contents that should be sent instead.
     * This can be used to handle a variety of different last minute tweaks, hacks,
     * or work-arounds.
     */
    filterHtmlOutput(htmlStr) {
      //replace all tags for debug viewing
      //htmlStr = rexReplace(R'<langle>', htmlStr, '&lt;', ReplaceAll);
      //htmlStr = rexReplace(R'<rangle>', htmlStr, '&gt;', ReplaceAll);
      
      // remove initial <br> from responses
      htmlStr = rexReplace(R'^<langle>br<rangle>', htmlStr, '', ReplaceOnce);
      
      // change Exit links to be object references 
      // \v lowercases the next char
      htmlStr = rexReplace([R'%<a +href="North"', R'%<a +href="South"',
                            R'%<a +href="East"', R'%<a +href="West"',
                            R'%<a +href="Up"', R'%<a +href="Down"',
                            R'%<a +href="Northwest"', R'%<a +href="Southwest"',
                            R'%<a +href="Northeast"', R'%<a +href="Southeast"'],
                            htmlStr, 
                            ['a href="?north"', 'a href="?south"',
                            'a href="?east"', 'a href="?west"',
                            'a href="?up"', 'a href="?down"',
                            'a href="?northwest"', 'a href="?southwest"',
                            'a href="?northeast"', 'a href="?southeast"'], 
                            ReplaceAll);
      
      return htmlStr;
    }
     
    /*
     *   Wraps the given str in the normal Skald header/footer and sends it as a
     *   a reply to the given evtRequest.
     */
    sendReply(request, str) {
        local contents = skald.getHeader();
        contents += self.filterHtmlOutput(str.specialsToHtml());
        contents += (self.quit) ? skald.getGameOverFooter() : skald.getFooter(); 
        request.sendReply(contents);
    }
    
    /* 
     *   As sendReply using the contents of the output buffer.  This will also
     *   clear the buffer.
     */
    sendOutputAsReply(request) {
        self.sendReply(request, toString(self.buffer));
        buffer.deleteChars(1); //clear all
    }
    
    /*
     * If there is a pending request that has not yet recieved a reply, 
     * send the current output as a reply.  The pending request is then 
     * marked as satisfied.  
     * 
     * If there is currently no pending request, this call does nothing.
     */
    sendAnyPendingOutput() {     
        if (self.pendingRequest) {
            self.sendOutputAsReply(self.pendingRequest);
            self.pendingRequest = nil;
        }
    }
    
    /*
     *   Processes web requests until a cmd is received.  Returns the contents
     *   as a string.
     */
    processRequests() {
        //handle any pending cmd request from last cycle
        sendAnyPendingOutput();
        
        if (self.quit) {
            if (self.LOG_LEVEL >= 2) tadsSay('HTTP Server: Game over, so quitting...\n');
            throw new QuittingException(); //shut it all down
        }

        for (;;) {  //until we get a cmd
            
            local evt = getNetEvent(); //self.connectionTimeout);  //timeout in ms
            if (evt.evType == NetEvTimeout) {
                if (self.LOG_LEVEL >= 1) {
                    tadsSay('HTTP Server connection timed out (' + self.connectionTimeout + 
                            'ms without a UI request)\n');
                    throw new QuittingException(); //shut it all down
                }
            } else if (evt.evType == NetEvRequest && evt.evRequest.ofKind(HTTPRequest)) {
                local req = evt.evRequest;
                local query = req.parseQuery();
                //init
                if (req.getQuery() == self.MODULE + 'init') {
                    if (self.buffer.length() == 0) {
                        //probably due to a browser refresh.  Should send something...
                        if (self.LOG_LEVEL >= 2) tadsSay('INIT: No contents to send, so Looking.\n');
                        self.pendingRequest = req;
                        return 'Look';
                    }else {
                        if (self.LOG_LEVEL >= 2) tadsSay('INIT\n');
                    }
                    self.sendOutputAsReply(req);

                //cmd (by POST)
                }else if (req.getQuery() == self.MODULE + 'cmd') {
                    local f = req.getBody();
                    if (f != nil) {
                        local contents = '';
                        local line = f.readFile();
                        while (line != nil) {
                            contents += line;
                            line = f.readFile();
                        }
                        if (self.LOG_LEVEL >= 2) tadsSay('CMD: ' + contents + '\n');
                        self.pendingRequest = req;
                        return contents;
                    }else {
                        if (self.LOG_LEVEL >= 2) tadsSay('CMD: [empty body]\n');
                    }
                    
                //a request for web file or other resource
                }else {
                    if (self.LOG_LEVEL >= 3) tadsSay('GET: <<query[1]>>\n');
                    if (query[1] == '/') {
                        query[1] = '/index.html';
                        if (self.LOG_LEVEL >= 4) tadsSay('GET converted: / -> /index.html\n');
                    }
                    query[1] = self.ROOT + query[1];
                    webResources.processRequest(req, query);
                }
            }//end HTTP request
        }//end for
    }//end processRequests
    
    /*
     *   Kill the server.  This will direct all future output to console again.
     *   If server is not active, can be safely called with no effect.
     */
    shutdown() {
        if (self.server) {
            self.server.shutdown();
            self.server = nil;
            if (self.LOG_LEVEL >= 1) "HTTP Server shutdown.\n";
        }
    }
;
   
  
/* ------------------------------------------------------------------------ */
//FROM TADS's webui.t:

/*
 *   A WebResource is a virtual file accessible via the HTTP server.  Each
 *   resource object has a path, which can be given as a simple string that
 *   must be matched exactly, or as a RexPattern object with a regular
 *   expression to be matched.  Each object also has a "processRequest"
 *   method, which the server invokes to answer the request when the path
 *   is matched.
 */
class WebResource: object
    /*
     *   The virtual path to the resource.  This is the apparent URL path
     *   to this resource, as seen by the client.
     *
     *   URL paths follow the Unix file system conventions in terms of
     *   format, but don't confuse the virtual path with an actual file
     *   system path.  The vpath doesn't have anything to do with the disk
     *   file system on the server machine or anywhere else.  That's why we
     *   call it "virtual" - it's merely the apparent location, from the
     *   client's perspective.
     *
     *   When the server receives a request from the client, it looks at
     *   the URL sent by the client to determine which WebResource object
     *   should handle the request.  The server does this by matching the
     *   resource path portion of the URL to the virtual path of each
     *   WebResource, until it finds a WebResource that matches.  The
     *   resource path in the URL is the part of the URL following the
     *   domain, and continuing up to but not including any "?" query
     *   parameters.  The resource path always starts with a slash "/".
     *   For example, for the URL "http://192.168.1.15/test/path?param=1",
     *   the resource path would be "/test/path".
     *
     *   The virtual path can be given as a string or as a RexPattern.  If
     *   it's a string, a URL resource path must match the virtual path
     *   exactly, including upper/lower case.  If the virtual path is given
     *   as a RexPattern, the URL resource path will be matched to the
     *   pattern with the usual regular expression rules.
     */
    vpath = ''

    /*
     *   Process the request.  This is invoked when we determine that this
     *   is the highest priority resource object matching the request.
     *   'req' is the HTTPRequest object; 'query' is the parsed query data
     *   as returned by req.parseQuery().  The query information is
     *   provided for convenience, in case the result depends on the query
     *   parameters.
     */
    processRequest(req, query)
    {
        /* by default, just send an empty HTML page */
        req.sendReply('<html><title>TADS</title></html>', 'text/html', 200);
    }

    /*
     *   The priority of this resource.  If the path is given as a regular
     *   expression, a given request might match more than one resource.
     *   In such cases, the matching resource with the highest priority is
     *   the one that's actually used to process the request.
     */
    priority = 100

    /*
     *   The group this resource is part of.  This is the object that
     *   "contains" the resource, via its 'contents' property; any object
     *   will work here, since it's just a place to put the contents list
     *   for the resource group.
     *
     *   By default, we put all resources into the mainWebGroup object.
     *
     *   The point of the group is to allow different servers to use
     *   different sets of resources, or to allow one server to use
     *   different resource sets under different circumstances.  When a
     *   server processes a request, it does so by looking through the
     *   'contents' list for a group of its choice.
     */
//    group = mainWebGroup

    /*
     *   Determine if this resource matches the given request.  'query' is
     *   the parsed query from the request, as returned by
     *   req.parseQuery().  'req' is the HTTPRequest object representing
     *   the request; you can use this to extract more information from the
     *   request, such as cookies or the client's network address.
     *
     *   This method returns true if the request matches this resource, nil
     *   if not.
     *
     *   You can override this to specify more complex matching rules than
     *   you could achieve just by specifying the path string or
     *   RexPattern.  For example, you could make the request conditional
     *   on the time of day, past request history, cookies in the request,
     *   parameters, etc.
     */
    matchRequest(query, req)
    {
        /* get the query path */
        local qpath = query[1];

        /* by default, we match GET */
        local verb = req.getVerb().toUpper();
        if (verb != 'GET' && verb != 'POST')
            return nil;

        /* if the virtual path a string, simply match the string exactly */
        if (dataType(vpath) == TypeSString)
            return vpath == qpath;

        /* if it's a regular expression, match the pattern */
        if (dataType(vpath) == TypeObject && vpath.ofKind(RexPattern))
            return rexMatch(vpath, qpath) != nil;

        /* we can't match other path types */
        return nil;
    }

    /*
     *   Send a generic request acknowledgment or reply.  This wraps the
     *   given XML fragment in an XML document with the root type given by
     *   the last element in our path name.  If the 'xml' value is omitted,
     *   we send "<ok/>" by default.
     */
    sendAck(req, xml = '<ok/>')
    {
        /*
         *   Figure the XML document root element.  If we have a non-empty
         *   path, use the last element of the path (as delimited by '/'
         *   characters).  Otherwise, use a default root of <reply>.
         */
        local root = 'reply';
        if (dataType(vpath) == TypeSString
            && vpath.length() > 0
            && rexSearch(vpath, '/([^/]+)$') != nil)
            root = rexGroup(1)[3];

        /* send the reply, wrapping the fragment in a proper XML document */
        sendXML(req, root, xml);
    }

    /*
     *   Send an XML reply.  This wraps the given XML fragment in an XML
     *   document with the given root element.
     */
    sendXML(req, root, xml)
    {
        req.sendReply('<?xml version="1.0"?>\<<<root>>><<xml>></<<root>>>',
                      'text/xml', 200);
    }
;

/* ------------------------------------------------------------------------ */
/*
 *   A resource file request handler.  This handles a request by sending
 *   the contents of the resource file matching the given name.
 *
 *   To expose a bundled game resource as a Web object that the client can
 *   access and download via HTTP, simply create an instance of this class,
 *   and set the virtual path (the vpath property) to the resource name.
 *   See coverArtResource below for an example - that object creates a URL
 *   for the Cover Art image so that the browser can download and display
 *   it.
 *
 *   You can expose *all* bundled resources in the entire game simply by
 *   creating an object like this:
 *
 *.     WebResourceFile
 *.         vpath = static new RexPattern('/')
 *.     ;
 *
 *   That creates a URL mapping that matches *any* URL path that
 *   corresponds to a bundled resource name.  The library intentionally
 *   doesn't provide an object like this by default, as a security measure;
 *   the default configuration as a rule tries to err on the side of
 *   caution, and in this case the cautious thing to do is to hide
 *   everything by default.  There's really no system-level security risk
 *   in exposing all resources, since the only files available as resources
 *   are files you explicitly bundle into the build anyway; but even so,
 *   some resources might be for internal use within the game, so we don't
 *   want to just assume that everything should be downloadable.
 *
 *   You can also expose resources on a directory-by-directory basis,
 *   simply by specifying a longer path prefix:
 *
 *.     WebResourceFile
 *.         vpath = static new RexPattern('/graphics/')
 *.     ;
 *
 *   Again, the library doesn't define anything like this by default, since
 *   we don't want to impose any assumptions about how your resources are
 *   organized.
 */
class WebResourceResFile: WebResource
    /*
     *   Match a request.  A resource file resource matches if we match the
     *   virtual path setting for the resource, and the requested resource
     *   file exists.
     */
    matchRequest(query, req)
    {
        return inherited(query, req) && resExists(processName(query[1]));
    }

    /* process the request: send the resource file's contents */
    processRequest(req, query)
    {
        /* get the local resource name */ 
        // after prepending folder location of all server files
        local name = processName(query[1]);

        /* get the filename suffix (extension) */
        local ext = nil;
        if (rexSearch('%.([^.]+)$', name) != nil)
            ext = rexGroup(1)[3];

        local fp = nil;
        try
        {
            /* open the file in the appropriate mode */
            if (isTextFile(name))
                fp = File.openTextResource(name);
            else
                fp = File.openRawResource(name);            
        }
        catch (FileException exc)
        {
            /* send a 404 error */
            req.sendReply(404);
            return;
        }

        /*
         *   If the file suffix implies a particular mime type, set it.
         *   There are some media types that are significant to browsers,
         *   but which the HTTPRequest object can't infer based on the
         *   contents, so as a fallback infer the media type from the
         *   filename suffix if possible.
         */
        local mimeType = browserExtToMime[ext];

        /* send the file's contents */
        req.sendReply(fp, mimeType);

        /* done with the file */
        fp.closeFile();
    }

    /* extension to MIME type map for important browser file types */
    browserExtToMime = static [
        'html' -> 'text/html',
        'css' -> 'text/css',
        'js' -> 'text/javascript'
    ]

    /*
     *   Process the name.  This takes the path string from the query, and
     *   returns the resource file name to look for.  By default, we simply
     *   return the same name specified by the client, minus the leading
     *   '/' (since resource paths are always relative).
     */
    processName(n) { return n.substr(2); }

    /*
     *   Determine if the given file is a text file or a binary file.  By
     *   default, we base the determination solely on the filename suffix,
     *   checking the extension against a list of common file types.
     */
    isTextFile(fname)
    {
        /* get the extension */
        if (rexMatch('.*%.([^.]+)$', fname) != nil)
        {
            /* pull out the extension */
            local ext = rexGroup(1)[3].toLower();

            /*
             *   check against common binary types - if it's not there,
             *   assume it's text
             */
            return (binaryExts.indexOf(ext) == nil);
        }
        else
        {
            /* no extension - assume binary */
            return nil;
        }
    }

    /* table of common binary file extensions */
    binaryExts = ['jpg', 'jpeg', 'png', 'mng', 'bmp', 'gif',
                  'mpg', 'mp3', 'mid', 'ogg', 'wav',
                  'pdf', 'doc', 'docx', 'swf',
                  'dat', 'sav', 'bin', 'gam', 't3', 't3v'];
;

// END: from webui.t

/*
 *   The resource handler for our standard library resources.  All of the
 *   library resources are in the /htdocs resource folder.  This exposes
 *   everything in that folder as a downloadable Web object.
 */
webResources: WebResourceResFile
    vpath = static new RexPattern('/htdocs')
;

// XXX: It'd be nice to have a containingFolder variable so we could hide
// the initial /skald/ part of the URL from all queries. Nicer, but doesn't 
// change basic functionality, so will come back to this...  maybe.

