/*
 *   Used in evaluation study to control game modes, which port is used, 
 *   and what sort of logging a game does.
 *
 *   Author: Zach Tomaszewski 
 *   Created: 31 Oct 2013
 */

// true = TADS's default WebUI, nil = Skald
// If true, must compile along with adv3web and webui.t.
//#define WEB_UI_MODE nil  -- define in .t3m file

#ifdef WEB_UI_MODE
replace initUI() {
    startup.init();
    // from WebUI's browser.t:  (changed to used assigned port)
    local srv = browserGlobals.httpServer = new HTTPServer(
        getLaunchHostAddr(), startup.port, 1024*1024);
    webSession.connectUI(srv);
}
#endif

/*
 *   The game startup preprocessor that does the actual configuring.
 */
startup : object
    
    // defaults
    port = nil      // mil = system assigned
    logName = nil
   
    
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
        self.port = (args.length() > 1) ? toInteger(args[2]) : self.port;
        self.logName =  (self.port) ? ('' + self.port + '-' + progName) : nil;
    }
    
    /*
     *   If running in Skald mode, will initialize skaldServer correctly and
     *   start it up.  Regardless of model, will start logging.
     *
     *   Calls init before anything else.
     */
    start() {
        self.init();
        #ifdef WEB_UI_MODE
            if (self.logName) {
                setLogFile(self.logName + '.log', LogTypeScript);
            }
        #else
            // skald mode
            // LogTypes = Transcript: all in/out, Command: only cmd-line in, Script: all input
            if (self.logName) {
                setLogFile(self.logName + '.log', LogTypeTranscript);
            }
            skaldServer.connectionTimeout = 1 * (60 * 1000);  // ms to minutes 
            skaldServer.port = self.port;
            skald.start();  // this time without processed args
        #endif        
    }
;