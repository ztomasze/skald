/*
 *   Used in evaluation study to control game modes, which port is used, 
 *   and what sort of logging a game does.
 *
 *   Author: Zach Tomaszewski 
 *   Created: 31 Oct 2013
 */


// Set this to true if using TADS's default WebUI.
// This requires compiling with adv3web and webui.t.
// If nil, then will run in Skald mode instead.
WEB_UI_MODE = true 


replace initUI() {
    startup.init();
    if (WEB_UI_MODE) {
        // from WebUI's browser.t:  (changed to used assigned port)
        local srv = browserGlobals.httpServer = new HTTPServer(
            getLaunchHostAddr(), startup.port, 1024*1024);
        webSession.connectUI(srv);
    }
}

/*
 *   The game startup preprocessor that does the actual configuring.
 */
startup : object

    // defaults
    port = nil      // system assigned
    
    
    /*
     *   Processes command line arguments to override the default instance
     *   variable values.
     *
     *   Cmd line args:
     *
     *   [1] = name of program
     *   [2] = port to run on
     *
     *   Always logs to a file based on game name, port number, and game mode.
     */
    init() {
        local args = libGlobal.commandLineArgs;
        local progName = args[1];
        // will be nil if arg is not an int
        local self.port = (args.length() > 2) ? toInteger(args[3]) : self.port;
        local logName =  (self.port) ? ('' + self.port + '-' + progName) : nil;
    }
    
    /*
     *   If running in Skald mode, will initialize skaldServer correctly and
     *   start it up.  Regardless of model, will start logging.
     *
     *   Calls init before anything else.
     */
    start() {
        self.init()
        if (WEB_UI_MODE) {
            if (logName) {
                setLogFile(logName + 'webui.log', LogTypeTranscript);
            }
        }else {
            // skald mode
            // LogTypes = Transcript: all in/out, Command: only cmd-line in, Script: all input
            if (logName) {
                setLogFile(logName + '.skald.log', LogTypeTranscript);
            }            
            skaldServer.port = self.port
            skald.start();  // this time without processed args
        }        
    }
;