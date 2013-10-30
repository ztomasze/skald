/*
 *   A game plugin that connects to a Skald web front end.  This is the logic
 *   required to determine what actions are currently afforded by the current
 *   game state.  Also provides three verbs for command line use: objects,
 *   verbs, and affordances.
 *
 *   To use, first include skald.h and skaldserver.h from your main .t class:
 *
 *     #include "skald.h"
 *     #include "skaldserver.h"
 *
 *   Then, in your main .t file, create a SkaldUI object.  Set the verbNames 
 *   property to contain a dictionary (LookupTable) of the verbs you want to 
 *   support.  The value for each verb should be an array with these details:
 *   order (avalue between 1 and 10000, used in sorting verbs in the UI; 
 *   each 1000 forms a new verb group), verb name, and preposition name 
 *   (for TIActions only).
 *
 *   An example:
 *
 *      skald: SkaldUI 
 *         verbNames = [ 
 *              //Actions 
 *              InventoryAction -> [4010, 'Inventory'],
 *              LookAction -> [1010, 'Look'], 
 *              //TActions
 *              TravelDirAction -> [1100, 'Go']
 *              ExamineAction -> [2010, 'Examine'], 
 *              TakeAction -> [2020, 'Get'], 
 *              DropAction -> [2030, 'Drop'], 
 *              AttackAction -> [2040, 'Attack'], 
 *              //TIActions 
 *              AttackWithAction -> [3010, 'Kill', 'with'],
 *      ]
 *   ;
 *
 *   Note that TADS does not model directions like other objects.  They are 
 *   largely just grammar artifacts.  As a consequence, travel actions are 
 *   handled by using macros to produce a different action for every direction.
 *   One way to handle this is to list each of these possible direction actions
 *   as a separate IActions: NorthAction, UpAction, etc.  This is currently your 
 *   only option for the PushDirActions.  However, Skald offers a shortcut if 
 *   you want to afford a single travel action that takes a direction as dobj:  
 *   Use TraveDirAction. When computing affordances, any TravelDirAction will be 
 *   expanded into each direction action that is supported by the currently 
 *   obvious exits (as per ExitsAction logic).  (Technically, TravelDirAction 
 *   is an IAction, so you may get some odd behaviors in other contexts.)
 *
 *   Completing the steps described above will give you the 3 Skald verbs 
 *   (verbs, objects, affordances) in your console game.  You may also want to 
 *   change some of the config CONSTANTS below.
 * 
 *   To actually run the web interface, you also need to start the server and
 *   allow skald to perform any other UI-optimizations. To do this, 
 *   call skald.start() from your gameMain's newGame() method.
 *
 *   Example:
 *
 *      gameMain: GameMainDef
 *
 *          newGame() {
 *            skald.start();  //or: skald.start(libGlobal.commandLineArgs);
 *            inherited();    //or other newGame content
 *          }
 *    
 *          //...other gameMain content, such as setting initialPlayerChar...
 *      ;
 *
 *    See also skaldserver.h for details about skaldserver.h dependencies and
 *    configuration.
 *
 *    The affordances are determined using TADS's normal verify routine.  See
 *    TADS documentation, such as verify in "Getting Started in TADS3" and 
 *    "Learning TADS3".  In particular, these macros will be helpful:
 *
 *    logical - clearly afforded
 *    illogical - never a logical action
 *    illogicalAlready - action would accomplish the currently existing state
 *    illogicalNow - currently illogical, but not always so
 *    illogicalSelf - means using one object to apply the action to itself
 *    inaccessible - required object can't be reached
 *    dangerous - obviously dangerous and best avoided
 *    nonObvious - logical, but not intuitively afforded 
 *                 (may be a puzzle solution, tho).
 *    logicalRank - lets you specify the rank between logical and illogical
 *
 *
 *    Author: Zach Tomaszewski
 *    Version: May 2013
 */    

class SkaldUI: object
    
    /* 
     *   When determining affordances, should TAD's NonObviousVerifyResult be
     *   treated as obviously afforded?  If false, then non-obvious actions will
     *   appear likely to fail (ie, weakly afforded).
     */
    NON_OBVIOUS_IS_OBVIOUS = nil
    
    /*
     *   Filters the current room from the object scope list.  This room object
     *   is assumed to be equal to gPlayerChar's current location.
     */
    IGNORE_ROOM_AS_OBJECT = true
    
    /*
     *   TADS Topics can have more than one matchObject, meaning that all of those
     *   objects are covered by this single Topic.  This is handy in a command
     *   line environment, where the user can ask about many different things.
     *   However, in a menu-driven environment, it might be tedious or redundant
     *   to list all of these as topics since they all lead back to the same
     *   response.
     *
     *   When this variable is true, only the first element in any matchObject
     *   list is treated as the true subject of the topic and the rest are
     *   ignored.  When false, the full list is processed.
     */
    SINGLE_MATCH_OBJ_PER_TOPIC = true  //FIXME: Unimplemented!
    
    /*
     *   List obvious exits in room descriptions.  This uses TADS's normal exit
     *   mode.
     */
    EXITS_LOOK = true
    
    /* 
     *   A LookupTable matching Action objects to a corresponding [order, 'name',
     *   'preposition'].  The 'preposition' field is optional, but it is usual
     *   for TIActions.
     */
    verbNames = new LookupTable()  
    // Could extract this from Action class names instead, but there would be
    // weird verbs like VagueAsk, and Travel rather than Go.  Instead, author-
    // specified.  Also, want to support author-specified ordering.
    
    /*
     *   The list of objects that should never be afforded for any action. This
     *   can be handy for certain common objects, such as default walls, that
     *   you may not want to support.
     * 
     *   By default, this filters out default walls and ceilings.
     */
    objectsFilter = [defaultCeiling, defaultSky, defaultFloor, defaultGround,
                     defaultWestWall, defaultNorthWall, defaultEastWall,
                     defaultSouthWall]
    
    /* 
     *   Starts the server and performs other setup work.
     *
     *   Without arguments, simply starts skald on the default port.
     *   You can set skaldServer.port before calling skald.start() to change
     *   this.
     *
     *   The optional args parameter is intended for default handling of 
     *   command line args. In this case, you can call: 
     *       
     *          skald.start(libGlobal.commandLineArgs);
     *
     *   from gameMain.newGame().  Behavior various depending on the 
     *   args given:
     *
     *   [1] = name of program
     *   [2] = 'skald' or some other value, such as 'text'
     *   [3] = ID.  If given, will log commands to a file with this prefix- before program name. 
     *         If in webmode and ID is parsable as an integer, will also use this as port number.
     *         (Side-effect: Impossible to run on non-default port without logging.)
     */
    start(args?) {

        if (args) {
            local progName = (args.length() > 0) ? args[1] : nil;  //safety check for not-real cmd line args
            local mode = (args.length() > 1) ? args[2] : nil;
            local id = (args.length() > 2) ? args[3] : nil;
            local logName =  (id) ? ('' + id + '-' + progName) : nil;

            if (mode && mode == 'skald') {
                // skald mode
                if (id) {
                    local idAsPort = toInteger(id);
                    if (idAsPort) skaldServer.port = idAsPort;
                }
                skald.start();  // this time without processed args
                // LogTypes = Transcript: all in/out, Command: only cmd-line in, Script: all input
                if (logName) {
                    setLogFile(logName + '.web.log', LogTypeTranscript);
                }
            }else {
                // text mode
                if (logName) {
                    setLogFile(logName + '.log', LogTypeTranscript);
                }
            }
        }else {            
            // normal default start
            skaldServer.start();
            exitsMode.inRoomDesc = self.EXITS_LOOK;
        }
    }
    
    /*
     *   Shuts down the server.
     */
    shutdown() {
        skaldServer.shutdown();
    }
    
    /*
     *   If the server is active, produces a <a href="?obj.name">text</a> tag.
     *   If text is omitted, obj.name is used there as well.  If the server is
     *   not active, returns only text (or obj.name if text is omitted).  In
     *   this way, objects can be turned into links, but only when the server is
     *   ready to handle them.
     */
    a(obj, text?) {
        if (!text) {
            text = obj.name;
        }
        if (self.isOn()) {
            return '<a href="?<<obj.name>>"><<text>></a>';
        }else {
            return text;
        }
    }
    
    /** Whether the server is currently running. */
    isOn() {
        return skaldServer.server;
    }
    
    /*
     *   Excutes the given command string, similarly to as if it had been typed
     *   at the command prompt.
     */
    executeCmd(cmdText) {
        //see: TADS3 > Technical Manual > "The Command Execution Cycle"
        local toks = Tokenizer.tokenize(cmdText);
        executeCommand(gPlayerChar, gPlayerChar, toks, true);
    }
    
    /*
     *   HTML content that should be appended to the output (after any
     *   conversion to HTML) when the game ends.  Override this method to
     *   customize.
     */
    gameOverMsg() {
        return '<p><b>THE END</b><br><br>(Disconnected from game server)</p>';
    }
    
    /*
     *   Returns a JSON list of the affordances supported by the current
     *   gameworld state.
     */
    getAffordances() {
        local affs = [];        
        foreach (local verb in skald.verbNames.keysToList()) {
            if (!verb.ofKind(TAction)) {
                // special handling for travel actions
                if (verb == TravelDirAction) {
                    local dirNames = skald.getExits().mapAll({x : x.name});
                    affs += skald.toJsonAffordance(verb, dirNames, nil, nil);
                    continue; //done with this verb
                }
                
                //only an IAction with no objects
                local verified = skald.isAfforded(gPlayerChar, verb, nil, nil);
                if (verified) {
                    affs += skald.toJsonAffordance(verb, nil, nil, verified < 0);
                }
                
            }else if (verb.ofKind(TopicTAction)) {
                // special handling for topics
                local dobjs = skald.getObjectsInScope();
                foreach (local dobj in dobjs) {
                    local topics = skald.getTopics(dobj, verb);
                    if (topics && topics.length() > 0) {
                        affs += skald.toJsonAffordance(verb, dobj, topics, nil);
                    }
                }
                
            }else if (!verb.ofKind(TIAction)) {  //general TAction
                // for efficient packing, build a list of strong and weak affordings
                local dobjs = skald.getObjectsInScope();
                local strong = [];
                local weak = [];                    
                foreach (local dobj in dobjs) {
                    local verified = skald.isAfforded(gPlayerChar, verb, dobj, nil);
                    if (verified > 0) {
                        strong += dobj;
                    }else if (verified < 0){
                        weak += dobj;
                    }
                }
                if (strong.length() > 0) {
                    affs += skald.toJsonAffordance(verb, strong, nil, nil);
                }
                if (weak.length() > 0) {
                    affs += skald.toJsonAffordance(verb, weak, nil, true);
                }               
            }else { //TIaction
                local dobjs = skald.getObjectsInScope();
                local iobjs = dobjs;  //actually the same list
                foreach (local dobj in dobjs) {
                    local strong = [];
                    local weak = [];                    
                    foreach (local iobj in iobjs) {
                        local verified = skald.isAfforded(gPlayerChar, verb, dobj, iobj);
                        if (verified > 0) {
                            strong += iobj;
                        }else if (verified < 0){
                            weak += iobj;
                        }
                    }
                    //XXX: if only one iobj element in strong+weak, could be compacted
                    //with all dobjs, rather than having each dobj separate. Hard to
                    //do here, so will leave this for a later optimization.
                    if (strong.length() > 0) {
                        affs += skald.toJsonAffordance(verb, dobj, strong, nil);
                    }
                    if (weak.length() > 0) {
                        affs += skald.toJsonAffordance(verb, dobj, weak, true);
                    }
                }                
            }
        }         
        return toJsonList(affs, true);
    }
    
    /*
     *   Returns the appropriate header for a response to the UI client.
     */
    getHeader() {
        return '<script class="header"></script>\n';
    }
    
    /*
     *   Return the appropriate footer, including current affordances, for a
     *   response to the client.
     */
    getFooter() {
        return '\n<script class="footer">{"affordances": ' + 
            self.getAffordances() + ',\n"objects": ' +
            self.toJsonList(self.getObjectsInScope()) +
            '}</script>\n';
    }
    
    /*
     *   Returns no affordances or objects, but instead indicates that the game
     *   has ended.
     *
     *   In future, could conceivably return meta-level affordances or objects,
     *   or other game controls such as restart, restore, etc.  So UIs should
     *   look for "gameOver": true for the definitive sign that the game has 
     *   ended.
     */
    getGameOverFooter() {
        return gameOverMsg() + 
            '\n<script class="footer">{"gameOver": true}</script>\n';
    }
    
    /*
     *   Returns the current directions that point to obvious exits, according
     *   to TADS's normal exit detection logic.
     */
    getExits() {
        exitLister.showExitsWithLister(gPlayerChar, gPlayerChar.location, 
                skaldExitLister, gPlayerChar.location.wouldBeLitFor(gPlayerChar));
        return skaldExitLister.getList();
    }
    
    /* 
     *   Returns a list of all object currently in scope of the current
     *   playerChar, which is the same as gPlayerChar.  Filters objects
     *   and adds objects in accordance with objectsFilter and
     *   IGNORE_ROOM_AS_OBJECT.  Also drops any objects that have no
     *   name.
     */
    getObjectsInScope() {
        local objects = libGlobal.playerChar.scopeList();
        //filter out those objects in filterObjects
        objects = objects.subset({x: self.objectsFilter.indexOf(x) == nil});
        if (self.IGNORE_ROOM_AS_OBJECT && objects.indexOf(gPlayerChar.location)) {
            //may not be there if in the dark
            objects = objects.removeElementAt(objects.indexOf(gPlayerChar.location));
        }
        objects = objects.subset({x: x.name != nil && x.name.length() > 0});
        return objects;
    }

    /* 
     *   As getObjectsInScope(), but returns a list of the .name of the object.
     */
    getObjectNamesInScope() {
        return getObjectsInScope().mapAll({obj: obj.name});
    }
    
    /*
     *   Given an NPC recipient and a topic-related verb (such as AskFor,
     *   AskAbout, etc.), returns the names of the topics currently supported
     *   for that verb by that NPC.  These usually map to existing objects,
     *   according to SINGLE_MATCH_OBJ_PER_TOPIC.  Grabs topics from both the 
     *   NPC and their curState.
     *
     *   If NPC is not an Actor or if there are not topics, returns an empty
     *   list.  If asObjs is true, return the game objects rather than their 
     *   names.
     */
    getTopics(npc, verb, asObjs?) {
        // XXX: Does not yet support misc, command, or self-initiated topics
        local topics = [];
        if (!npc || !npc.ofKind(Actor)) {
            return topics;   
        }        
        switch (verb) {
        case AskAboutAction:
            topics += npc.askTopics;
            topics += npc.curState.askTopics;
            break;
        case AskForAction:
            topics += npc.askForTopics;
            topics += npc.curState.askForTopics;
            break;
        case TellAboutAction:
            topics += npc.tellTopics;
            topics += npc.curState.tellTopics;
            break;
        case ShowToAction:
            topics += npc.showTopics;
            topics += npc.curState.showTopics;
            break;
        case GiveToAction:
            topics += npc.giveTopics;
            topics += npc.curState.giveTopics;
            break;
//      miscTopics = nil
//      commandTopics = nil
//      initiateTopics = nil        
        }
        
        // convert to the matchObjs (may be nil), then filter out nils
        topics = topics.subset({x: x != nil});
        topics = topics.mapAll({x: x.matchObj});
        topics = topics.subset({x: x != nil});
        if (!asObjs) {
            topics = topics.mapAll({x: x.name});
        }
        return topics;
    }
    
    /*  
     *   Returns whether this verb requires 0, 1, or 2 objects. This is useful
     *   because it "converts" certain kinds of verbs. For example,
     *   TravelDirAction as used here is a IAction (arity: 0) in TADS, but is
     *   considered an arity 1 verb by Skald.  Similarly, the various
     *   topic-based verbs are technically TActions, but need to be afforded as
     *   arity 3 actions.
     *
     *   If arity is uncertain, returns -1.
     */
    getVerbArity(verb) {
        if (verb.ofKind(TIAction) || verb.ofKind(TopicTAction)) {
            return 3;
        }else if (verb.ofKind(TAction) || verb == TravelDirAction) {
            return 2;
        }else if (verb.ofKind(IAction)) {
            return 0;
        }else {
            return -1;
        }
    }
    
    /*
     *   Returns whether the following action is currently logically possible.
     *   This taps into TADS's verify cycle at a low (and somewhat hacky) level.
     *
     *   Uses dobj and iobj only for TAction and TIActions, as appropriate.
     *
     *   Returns 0 if the action is clearly not afforded (TADS: "illogical",
     *   "illogicalSelf", or "inaccessible"). 
     * 
     *   Returns > 0 if the action is clearly afforded ("logical"
     *   in some manner, even if the ranking is low).  
     * 
     *   Returns < 0 if the action is only weakly afforded in
     *   some way (any of the other TADS classes: "illogicalNow", "dangerous", 
     *   etc.).
     *
     *   Note that this does not map directly to TADS's .allowAction property.
     *   For example, an illogicalNow action would not be allowed by TADS, but
     *   it makes sense to partially afford it since it might be possible later.
     *
     *   Using this scheme, it is possible to see if action is afforded in
     *   some way (!= 0), not afforded (== 0), clearly afforded (> 0) or 
     *   only partially/possibly afforded (< 0).
     *
     *   See in TADS: Action.verifyAction, VerifyResult, VerifyResultList.
     *   Also, verify in "Getting Started in TADS3", "Learning TADS3"
     */         
    isAfforded(actor, action, dobj, iobj) {
        
        action.actor_ = actor;
        if (action.ofKind(TAction)) {
            action.dobjCur_ = dobj;
        }
        if (action.ofKind(TIAction)) {
            action.iobjCur_ = iobj;
            action.tentativeDobj_ = [dobj];
            action.tentativeIobj_ = [iobj];
        }
        
        gAction = action;
        gActor = actor;
        
        local results = action.verifyAction();
        
        if (!results) {
            return 1; //no objections to the command
        }
        
        local mostLimiting = results.getEffectiveResult();
        local rank = mostLimiting.resultRank;
        if (mostLimiting.ofKind(InaccessibleVerifyResult) ||
            mostLimiting.ofKind(IllogicalVerifyResult)) {
            return 0;  //includes IllogicalSelf too
        }else if (mostLimiting.ofKind(LogicalVerifyResult)) {
            if (rank <= 0) rank = 1;
            return rank;   //+: allowed to degree of logical rank
        }else {
            //only partially afforded
            if (rank >= 0) rank = (rank * -1) - 1;
            return rank;   //-: weak affordance
        }
    }
        
    /* 
     *   Returns a Skald-based JSON-formatted string of the given affordance.
     *   dobj and iobj may be strings or lists of strings.  Uses verbNames to
     *   find verb name and (for TIActions with iobjs given) prepositions.
     *   If weak is not nil, will add "weak": true to the affordance.
     */
    toJsonAffordance(verb, dobj, iobj, weak) {
        local json = '{"affordance": ["' + self.verbNames[verb][2] + '"';
        if (dobj) {
            json += ', ' + self.toJsonList(dobj);
        }
        if (iobj) {
            if (skald.getVerbArity(verb) >= 3) {
               //add preposition
               json += ', "' + self.verbNames[verb][3] + '"';
            }
            json += ', ' + self.toJsonList(iobj);
        }
        json += ']';  //end affordances: []
        if (weak) {
            json += ', "weak": true';
        }
        json += ', "order": ' + self.verbNames[verb][1];
        json += '}';
        return json;
    }
    
    /*
     *   Converts objs to a JSON list format.  If objs is a list, grabs .name
     *   for each of its elements.  If not a list, throws objs into a list of a
     *   single element and does the same thing.  Will handle Strings too. 
     * 
     *   If jsonObj is true, objs already contains {json objects}, so does not
     *   wrap each obj in "quotes" and adds a newline after each comma.
     *
     *   If objs is an empty list, returns an empty list: '[]'.
     */
    toJsonList(objs, jsonObj?) {
        local sep = (jsonObj) ? ',\n' : '", "';
        if (!objs.ofKind(List)) {
            objs = [objs];
        }
        if (objs.length() == 0) {
            return '[]';
        }
        if (!objs[1].ofKind(String)) {
            objs = objs.mapAll({o: o.name}); //convert to object names
        }
        local json = objs.join(sep);
        return (jsonObj) ? '[' + json + ']' : '["' + json + '"]';
    }
;

/* 
 *   A hijacked lister used to collect the visible exits according to existing
 *   logic.
 */
skaldExitLister : ExitLister 
    
    exits = nil
    
    /* Updates the current list with the given list of objects. */
    showListAll(lst, options, indent) {
        // x.dir_ trick learned from ExitLister source code.
        // Each x should be a Direction, but 
        // I still don't know where dir_ comes from.  Direction.dirProp, perhaps?
        self.exits = lst.mapAll({x: x.dir_});
        // no output produced
    }
    
    /* Returns the list saved by the last call to showListAll */
    getList() {
        return self.exits;
    }
;

DefineIAction(Affordances)
    execAction() {
        //XXX: Would be nice to have a console-formatted option, rather than
        // the noisy JSON.
        "<<skald.getAffordances()>>";
    }
;
VerbRule(Affordances)
     'affordances' : AffordancesAction
;

DefineIAction(Objects)
    execAction() {
        //XXX: Could definitely format this better!
        objectLister.showSimpleList(skald.getObjectsInScope());
    }
;
VerbRule(Objects)
     ('objs' | 'objects') : ObjectsAction
;

DefineIAction(Verbs)
    execAction() {
        // prints in author-listed order
        "Verbs supported by this game:\n";
        skald.verbNames.forEachAssoc({act, desc: "* <<desc[2]>>
            <<if (skald.getVerbArity(act) > 0)>>[x] 
            <<if (desc.length > 2)>><<desc[3]>> [y]<<end>>
            <<end>>\n"});
    }
;
VerbRule(Verbs)
     'verbs' : VerbsAction
;

/*
 *   This function lists the valid options at the end of a game, including quit,
 *   restart, restore, and others (undo, score, etc).  We replace it here so
 *   that, if skald is running through the server, we don't print these options.
 *   Also, we need to process the final output and shutdown the server.
 */
modify processOptions(lst) {
    if (skald.isOn()) {
        // do not print normal options, but game is now over
        skaldServer.quit = true;
        // terminate the current command with no further processing (so no Look)
        throw new TerminateCommandException();
    }else {
        replaced(lst);  // run as normal
    }
}
