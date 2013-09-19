#include <adv3.h>
#include <en_us.h>

/*
 * Our goblin protagonist and his gear.
 */
me: Actor 
    name = 'yourself'
    location = the_western_tunnels
    deluded = true
    
    dobjFor(ListenTo) {
        verify() {
            logical;
        }
        action() {
            "You hear yourself muttering under your breath.  \"Stop that!\" you hiss crossly.
            The mumbling stops. 
            \b
            After a moment, your mind wanders, and you begin to whisper to yourself once more.";
        }
    }
;

+ sorrow: Thing 'sorrow' 'sorrow'
    "Sometimes your sorrow is a dark void in your chest, sometimes it
    is a gray weight between your shoulders, and sometimes it is a
    languid emptiness everywhere. At the moment, it is 
    <<if self.weight <= 0>> not so heavy.
    <<else if self.weight == 1>> a heavy burden.
    <<else if self.weight == 2>> very heavy.
    <<else>> a crushing weight.<<end>>"
    
    isQualifiedName = true
    weight = 1
    
    dobjFor(Drop) {
        verify() {illogicalNow('If only it were that easy to be free of your sorrow.');}
    }
    dobjFor(Feel) remapTo(Examine, self);
;

+ worms: Food 'earth worms/earthworms' 'earthworms'
    "Cool and glistening, the earthworms slowly writhe in their consternation.  
     It tickles a little when they do that."
    isPlural = true
    dobjFor(Attack) {
        verify() {return true;}
        action() {
            "You smoosh and smear the worms into a paste between your palms.
            Then you lick the paste off.
            \b
            \"Ick. I always seem to forget that worms taste better whole.\"
            \b
            You sigh quietly to yourself.";
            self.moveInto(nil);
        }
    }
    dobjFor(Drop) {
        action() {
            inherited;
            if (me.location == the_eastern_tunnels && mole.inHole) {
                mole.inHole = nil;
                mole.moved = true;
                extraReport('\bThe worms wriggle there for a while.
                    \b
                    After a moment, the mole pushes his nose a little
                    farther out of his hole.  He twitches it in your direction,
                    but goblins are not easily detected when they don\'t want 
                    to be.\b
                    The mole pushes its plump body out of the hole and 
                    hurries over to the earthworms.');
            }
        }
    }
    dobjFor(Eat) {
        action() { 
            inherited;
            "You slurp them down one a time.  They are better that way,
            like cold fat snotty noodles.  Sometimes they can be bitter or gritty if
            you chew them first.";          
        }
    }
;

+ sword : Thing 'bronze tarnished sword/blade' '<<if me.deluded>>bronze<<else>>tarnished<<end>> sword'
    "It is <<me.deluded ? 
      "one of the rare ever-shiny bronze blades of the Goblin Royal Guard." :
      "a tarnished old sword, pitted with age and green with patina.">>"
    iobjFor(AttackWith) {
        verify() { return true;}
    }
    dobjFor(Drop) {
        check() { 
            if (me.deluded) 
                failCheck('"A goblin knight should be ever-ready and ever-armed," you
                repeat to yourself.  Your sword is a symbol of your station.
                You cannot bear to part with it so casually.');
        }
    }
;

knot: Thing 'knot in my your stomach/knot' 'knot in your stomach'
    //TODO: expand desc
    "It is a tightening sense of unease. You often feel this way when you are
    away from the Queen for too long.  What if something should happen to her?
    What if... what if she wasn't there?  What if you were alone?"
    tightness = 0
    
    tighten() {
        if (me.location == the_queens_chambers && self.tightness < 2) {
            //ignore increment
            return;
        }
        self.tightness++;
        "\b...\n";
        if (self.tightness <= 0) {
            //ignore
        }else if (self.tightness == 1) {
            self.moveInto(me);
            "You begin to feel a little nervous... as if you've forgotten something
            important.";
        }else if (self.tightness == 2) {
            "Your stomach tightens.  You wonder if everything is 
            okay...\n Of course, the Queen makes everything okay.";
        }else if (self.tightness == 3) {
            "Your palms are getting sweaty now.  Why do you feel like this?
            Something must surely be wrong... wrong with the Queen, perhaps?
            The urge to look upon her once more is very strong.";
        }else {
            "<<one of>>Your armpits are slick, and your back is sweaty.
            <<or>>You feel weak and dizzy.
            <<or>>You suddenly gag and shiver.<<shuffled>> 
            The sense of doom is nearly crushing you.  The Queen!  Does she
            still live?  Does her heart still beat in the darkness?\b
            <<one of>>\"Stupid, useless goblin!\" you sob at yourself.<<or>>
            \"One job!  You only have one job!\" you scream at yourself.  Then
            your vision blurs with tears.<<shuffled>>.\b            
            You have gone so long without checking, you fear what you might 
            find... but check you must!";
        }
    }
    
    relax() {
        self.tightness = 0;
        self.moveInto(nil);
        "The tension pours out of you.  Your breathing slows, and the knot in 
         your stomach loosens and disappears once more.";
    }
    
    dobjFor(Drop) {
        verify() {illogical('This agony is part of you.');}
    }
;
