#include <adv3.h>
#include <en_us.h>

/*
 * The Queen's resting place.  Includes the queen herself.
 */
the_queens_chambers: Room 'The Queen\'s Chambers'
    "This round room is lined in stone.  Although it is just as dark in here
    as the rest of the Warren, it always feels brighter to you.
    \b
    In the center of the room is a <<skald.a(bier)>>, 
    surrounded by a protective <<skald.a(mandala)>> etched upon the floor."

    east = the_western_tunnels

    enteringRoom(traveler) {
        "You stop and bow low as you enter the room.";
    }
;

+ bier: Decoration 'bier/fur*furs' 'bier'
    "The bier is a hewn stone slab covered in multiple layers of furs.";

+ mandala: Fixture 'magic magical protective circle/mandala/ward' 'mandala'
    "The mandala is a protective Ward formed of swirls, runes, and glyphs etched
    upon the floor in a large circle around the <<skald.a(bier)>>.  This ancient goblin magic
    hides the queen from the ravages of time and iron.  You have spent countless
    hours--sometimes whole days--carefully tracing and retracing the lines in
    chalk or in blood.  Of course, material rich in iron works best,
    for \"like repels like.\""

    dobjFor(Trace) {
        verify() { logical; }
        action() {
            if (mole.location == me) {
                "You drive your fingers into the limp body of the <<skald.a(mole)>>, coating
                them with its cooling, tingling blood.  You trace the lines of the
                <<skald.a(mandala)>>, murmuring the well-practice incantations.  You feel
                the mandala growing warmer and stronger, protecting the Queen from the 
                passage of time. It calms you to know that she is safe.";
            }else {
                "You trace your fingers over the lines of the <<skald.a(mandala)>>, murmuring
                the incantations written there from memory.  This does not make the
                Ward any stronger, but it calms you a little.";
            }
            if (knot.tightness > 0) {
                 knot.tightness = knot.tightness - 2;
                if (knot.tightness <= 0) {
                    knot.tightness = 0;
                    knot.moveInto(nil);
                    "\bThe <<knot.name>> loosens. ";
                }
            }
        }
    }
;

+ queen: Fixture 'upon queen' 'Queen'
    "The <<skald.a(queen)>> lies pale and slender beneath a fur blanket.  Her eyes are closed,
    so you gaze upon her for a while.  As always, her serenity fills your chest
    with a bittersweet ache.
    \b
    The Queen sleeps.  She will sleep until Man recedes from the Earth, until
    all cold iron rusts, until Nature calls the goblins once more into the
    Green.
    \b
    You alone protect her while she slumbers.  You, alone.
    \b
    Her breath is so faint now that you cannot see the blanket rise or fall.
    Over her chest, there is a faint <<skald.a(depression)>> in the <<skald.a(blanket)>> 
    where you have so often laid your head, listening for the beating of her heart."

    properName = true
    initSpecialDesc = "The <<skald.a(queen)>> slumbers still upon the bier."

    dobjFor(Attack) {
        verify() { dangerous; }
        check() {
            failCheck('You ball up your fists... and then punch yourself.  "Stupid stupid goblin!" you wail.
                "How could you think of doing such a thing! What would you be without the Queen?
                Where would you go?  What would you do?  Alone!"
                \b
                You whimper at the thought, and so you suck on your fingers for a while.');
        }
    }

    dobjFor(AttackWith) {
        verify() { dangerous; }
        check() {
            failCheck('You stand over the Queen, {the iobj/him} raised in one hand.  Then your vision blurs with tears.
                \b
                "I\'m sorry, my Queen! Sometimes I grow so weary that I want it to end.  I want to be 
                done with you!  And with me.  But what else is there except for service and waiting?  
                What is there but time?"
                \b
                You sniffle to yourself.  There is no answer in the ensuing silence.
                \b
                You step back, lowering {the iobj/him} and wiping the tears from your cheeks.');
        }
    }

    
    dobjFor(Kiss) {
        check() {
            failCheck('You sigh.  Despite your love, you are no Prince Charming. 
                You are but a lowly Goblin Guard, ever-faithful. 
                It is not your place to touch the Queen, as much as you desire it.
                She will wake... in time.');
        }
    }
    iobjFor(GiveTo) {
        verify() {
            illogicalNow('The Queen is in no state to accept your gifts.');
        }
    }

    dobjFor(ListenTo) remapTo(ListenTo, heartbeat)
    
    dobjFor(Wake) {
        verify() { 
            illogicalNow('This is no ordinary slumber.  
                The Queen will sleep until the world is ready for goblins to take once more to the Green.'); 
        }
    }

    dobjFor(Feel) {
        action() {
            "You lay your hand upon the blanket at the edge of the bier for a while.";
        }
    }
    iobjFor(ThrowAt) {
        check() {
            failCheck('That would be disrespectful and might hurt the Queen.');
        }
    }
;

+ blanket: Decoration 'fur blanket' 'blanket'
    "The blanket, once luxurious, is now getting tattered and thin in places.  
    You have patched it where you could with mole pelts. ";

++ depression: Decoration 'queen\'s chest/depression' 'depression'
    "Despite your best efforts to be gentle when you listen for the Queen's heartbeat, 
    the long repetition has left a very faint head-sized depression in the blanket 
    over the Queen's chest.";


++ heartbeat: SimpleNoise 'heart/heartbeat' 'heartbeat'
    desc {
      if (me.deluded) {
        "You take a deep breath, hold it tightly, and lay your head ever so gently
        upon the Queen's chest.
        \b
        Straining your ears, you feel her heart faintly beating.";
        if (knot.tightness > 0) {
            " She lives! ";
            knot.relax();
        }
        if (!the_well.open) {
            the_well.open = true;
            new Fuse(the_well, &introGirl, 2);
        }
        if (!girl.alive) {
            "\b\"I have protected you, my Queen.  I will always protect you.
            Until Man recedes from the Earth, until all cold iron rusts,
            until Nature calls us once more into the Green, I will protect you.
            \b
            And I will never be alone.\"";
            finishGameMsg('The End', []);
        }
      }else {
        "Carefully, reverently, you lay your head upon the chest of the queen,
        as you have done so many times before.  You let out a long sigh and
        listen... but you hear nothing.
        \b
        Quivering, you repeat the well-practiced ritual: 
        you take a deep breath, hold it, and listen again.  And now
        you feel it once more, faintly, that beating you know so well, 
        the beating of the Queen's heart... the beating of your own blood in 
        your ears.
        \b
        Puzzled, you exhale.  The beating stops.
        \b
        Your glammer is gone, the illusion broken.
        \b
        You are a goblin, alone.  Your sorrow has never been so heavy.";
            finishGameMsg('The End', []);
      }
    }
;
