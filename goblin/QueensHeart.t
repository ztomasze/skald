#charset "us-ascii"

/*
 * The Queen's Heart, by Zach Tomaszewski.
 * Written as part of Global Game Jam, 2013.
 * Created: 25-27 Jan 2013.
 * Revised: Feb 2013.
 *
 * Requires TADS, and built from TADS starting files:
 * Copyright (c) 1999, 2002 by Michael J. Roberts.  Permission is granted to
 * anyone to copy and use this file for any purpose.
 *
 */
#include <adv3.h>
#include <en_us.h>
#include "tads-skald/skald.h"
#include "tads-skald/skaldserver.h"

/*
 * Game credits and version information.
 */
versionInfo: GameID
    IFID = '6f350921-e90b-419a-b82f-7df4be590a4d'
    name = 'The Queen\'s Heart'
    byline = 'by Zach Tomaszewski'
    htmlByline = 'by <a href="mailto:zach.tomaszewski@gmail.com">
                  Zach Tomaszewski</a>'
    version = '2'
    authorEmail = 'Zach Tomaszewski <zach.tomaszewski@gmail.com>'
    desc = 'Through the long years, a lone goblin knight tends to his
        slumbering queen... until a little human girl falls down a well
        and into his world.'
    htmlDesc = 'Through the long years, a lone goblin knight tends to his
        slumbering queen... until a little human girl falls down a well
        and into his world.'
;

skald : SkaldUI
    // order, verb, prep
    verbNames = [
        LookAction -> [1010, 'Look'],
        InventoryAction -> [1100, 'Inventory'],

        ExamineAction -> [2010, 'Examine'],
        TakeAction -> [2020, 'Get'],
        DropAction -> [2030, 'Drop'],
        AttackAction -> [2040, 'Attack'],

        AttackWithAction -> [3010, 'Kill', 'with'],   //TIAaction
        ListenToAction -> [3000, 'Listen', 'to'],

        TravelDirAction -> [4010, 'Go'],
        WaitAction -> [4020, 'Wait']
    ]

    exitDirVerbs = [
        TravelViaAction -> [true]
    ]
;

gameMain: GameMainDef
    /* the initial player character is 'me' */
    initialPlayerChar = me

    newGame() {
        skald.start();
        inherited();
    }

    setAboutBox()
    {
      "<ABOUTBOX>
       <CENTER>\b
       <<versionInfo.name.toUpper()>>\b
       <<versionInfo.byline>>\b
       Version <<versionInfo.version>>\b
       </CENTER>
       </ABOUTBOX>";
    }

    showIntro() {
        """You stand alone in the dark, <<skald.a(sorrow)>> in
        your heart and <<skald.a(worms, 'earthworms')>> in your hand.
        \b
        You stand listening.
        \b
        You can hear a faint scratching... a sort of scurrying... No, it is a
        <i>burrowing</i>... Yes, it is definitely a burrowing sound... though a
        rather small one.  Too small for a badger, too steady for a rabbit,
        which leaves only one thing: a mole.  There is a mole burrowing through
        the soft earth to your right.
        \b
        You look down at the earthworms in your hand.  "A bit of mole-fishing,
        then?" you ask yourself.  "A fresh mole for the Queen, my love, to
        grant her the strength she needs?" You feel the warmth of a blush
        on your face, a rush of blood.  You only call the queen "your love" in
        the most secret and lonely of places, like down here in the tunnels.
        \b
        You glance around carefully, first down the tunnel one way and then
        the other.  No one to see you, and no one to hear.  No one else in a
        long long time.
        \b
        You see dimly but well enough in the dark, though you could walk and
        hunt through these tunnels blindfolded if you wanted to.
        You've guarded them for so long that you know every twist and turn,
        every bump of moist soil.  As the last of the Goblin Guard, this is
        your domain: The Warren of the Eternal Queen (may she protect us all).
        \b
        The earthworms are wriggling, and they bring you back to the task at
        hand.  "Right then.  Worms or mole for dinner?"
        \b
        No one answers.
        \b""";

        "<hr><center><b><<versionInfo.name>></b>\n <<versionInfo.byline>>\n";
        if (!skald.isOn()) {
            "[Type HELP for instructions on how to play.]\b";
        }
        "</center><hr>";

        new Daemon(knot, &tighten, 5);
    }
;


/*
 * New verbs
 */
DefineIAction(Help)
    execAction() {
        mainReport('This game is an example of interactive fiction.
      Read the descriptions of what is happening and then type in commands
      specifying what you want your character (the goblin) to do next.
      \b
      Some sample commands include: LOOK, EXAMINE SORROW, GO EAST, and GET MOLE.
      The directions you can move from the current location are listed in the
      header above the game text.
      \b
      You can complete all actions supported by this game using only these
      verbs/commands: LOOK, INVENTORY, WAIT, GO (direction), EXAMINE (object),
      GET (object), DROP (object), KILL (creature), LISTEN to (object),
      TRACE (object), CLIMB (object)
      \b
      Stuck? EXAMINE everything that might be interesting.  The resulting object
      descriptions will sometimes give you hint as to what you might do next.');
    }
;
VerbRule(Help)
     'help' : HelpAction
;

DefineTAction(Trace);
VerbRule(Trace)
     ('trace' | 'retrace' | 'fix' | 'repair') singleDobj : TraceAction
     verbPhrase = 'trace/tracing (what)'
;

VerbRule(Listen)
    ('check' | 'check' 'on') singleDobj : ListenToAction
;
modify Thing
     dobjFor(Trace)
     {
       verify()
       {
         illogical('Tracing {that dobj/him} would achieve very little. ');
       }
     }
;
