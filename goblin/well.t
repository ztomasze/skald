#include <adv3.h>
#include <en_us.h>

/*
 * The well, though the goblin thinks of it as the pool.
 * Includes the little girl and outside.
 */
the_well: Room 'The Pool'
    "You stand at the mouth of a narrow tunnel that opens into a wide vertical shaft.
    A few feet below you, the shaft is filled with still <<skald.a(water)>>.  The walls
    of the shaft are lined with old <<skald.a(stones)>>, rounded by age.  The stones
    are slick with moisture near the water, but further up the shaft, stray 
    <<skald.a(roots)>> have poked between the stones.\b
    <<if self.open>><<self.dark ? " Stars glint through the <<skald.a(wellHole)>> at the 
        top of the shaft." : " A beam of sunlight pours through a <<skald.a(wellHole)>> above,
        reflecting off the water below and burning your eyes.">><<else>>
         Above you is only darkness.<<end>>"  //"
    
    west = the_eastern_tunnels
    up: NoTravelMessage { "There seems no point to that: there is only darkness up there." }
    dark = nil
    open = nil
    
    introGirl() {
        the_well.open = true;
        wellHole.moveInto(the_well);
        girl.moveInto(the_well);
        girl.moved = nil;
        the_well.up = outside;
        girl.motionDaemon = new Daemon(girl, &motion, 1);
        "\b...\n
        Suddenly, to the east, you hear a distant crack, a scream, and a splash!";
        
    }
;
+ shaft: Fixture 'shaft/wall*walls' 'shaft' 
    dobjFor(Examine) remapTo(Examine, the_well)
    dobjFor(Climb) remapTo(Up)
;
++ stones: Decoration 'slick old flag flagstone*flagstones/stone*stones' 'flagstones'
    "Time has worn smooth the edges of the flagstones.  Each one has settled down into its place in the world,
    like an old man settles into a favorite over-stuffed chair. "
;

++ roots: Decoration 'root*roots' 'roots'
    "In the past, you have occasionally found a green root to nibble on here.  Today, the roots 
    are all old and hard and woody."
;

+ water: Decoration 'water/pool' 'water' 
    "You come here for drinking water sometimes.  The water is too far away for
    you to reach from here.  When you need water, you lower down a rag and then
    squeeze the water out of the rag.  You seem to have mislaid your rag 
    somewhere... but no matter.  You are not thirsty at the moment."
; 

+ rock : Heavy 'large rock/stone/boulder' 'large rock'
    "This large rough grey stone once blocked the entrance to the tunnel.
     It is nearly as big as you are, and it takes all of your strength to move.
     It sits on the edge of the ledge."
    initSpecialDesc = "A <<skald.a(rock, 'large stone')>> partly hides the entrance to the tunnel."
    dobjFor(Push) {
        verify() {
            if (girl.location != the_well) {
                illogicalNow('At the moment, there seems little reason to push the <<skald.a(rock, 'stone')>> 
                    either into the tunnel entrance behind you or into the <<skald.a(water, 'pool')>> below.');
            }
        }
        
        action() {
            if (girl.location == the_well) {
                "You quietly get behind the stone and wait... wait until the
                girl moves directly below you.  Then you push, hard and fast,
                with all your strength.  
                \b
                The great rock groans and topples forward before the girl can move.  
                It strikes her hard, pushing her forward and carrying her below 
                the surface of the water.
                \b
                You watch the choppy ripples slowly subside on the surface of 
                the pool.
                \b
                \"Ever your protector, my Queen.  Ever shall we be
                safe.\"";
                rock.moveInto(nil);
                girl.alive = nil;
                girl.moveInto(nil);
                girl.motionDaemon.removeEvent();
                the_well.up = noSunlightForMe;
            }else {
                "At the moment, there seems little reason to push the <<skald.a(rock, 'stone')>> into 
                either the tunnel entrance behind you or into the <<skald.a(water, 'pool')>> below.";
            }
        }
    }
;

noSunlightForMe : FakeConnector
   travelDesc = "There is no point.  There is nothing up there for you.
                There will be only painful sunlight, cold iron, and Man.\n"
; 

wellHole: Fixture 'ragged well hole' 'ragged hole'
    "In the <<skald.a(light)>> now pouring through it,
    you can see that the top of the well shaft was actually capped by an ancient
    wooden cover of thick planks.  It must have rotted over the years, and then
    the little girl walked over it and broke through.
    <<if plank.location == wellHole>>
    \b
    <<skald.a(plank, 'One of the long planks')>> is hanging down into the well, barely attached at the
    other end.<<end>>"
    
    dobjFor(Climb) remapTo(Climb, shaft)
;

+ plank: Fixture 'long wooden plank/cover' 'plank'
    "It is a long wooden plank, still attached to the old well-cover above, 
    but only barely. The hanging plank is out of reach from here, but you could climb 
    up the shaft to the <<skald.a(wellHole, 'hole')>>."
;

+ light: Fixture 'sun star light/sunlight/starlight/tang/air' '<<the_well.dark ? 'starlight' : 'sunlight'>>'
    "Even more disturbing than the painful light is the sharp tang of the air that comes through the 
    <<skald.a(wellHole, 'hole')>> with it."
;

girl: Person 'human girl/child' 'human child'
    "It is a skinny wet little girl with dark hair.  
    The cold <<skald.a(water)>> of the pool comes up to her waist. 
    Even from here, you can smell the iron on her: 
    the taint of the world of Man, which drives all magic underground."
    
    isHer = true
    initSpecialDesc = "A <<skald.a(girl)>> stands in the water."
    alive = true
    motionDaemon = nil  
    motion() {  //handles the girl's motion (probably should have been done with ActorStates)
        if (me.location == the_well) {
            "\b...\n<<one of>>
            The <<skald.a(girl, 'girl')>> tries to climb the slick flagstones, but she cannot get a grip.<<or>>
            The <<skald.a(girl, 'girl')>> jumps, trying to grab a thick root that is sticking out between
            some of the higher flagstones.  The sound of her splashing failure 
            echoes up the shaft of the well.<<or>>
            The <<skald.a(girl, 'girl')>> stands still for a while, looking around the well.<<or>>
            The <<skald.a(girl, 'girl')>> wades across to the other side of the pool.<<or>>
            The <<skald.a(girl, 'girl')>> looks up at the <<the_well.dark ? "starlight" : "sunlight">>
            pouring through the hole above.<<or>>
            The <<skald.a(girl, 'girl')>> scans the walls of the well for other handholds.  You stand very still as
            her eyes pass over you.  Goblins are not easily detected when they don\'t want 
            to be.<<or>>
            The <<skald.a(girl, 'girl')>> puts her face in her hands for a while.  You can hear her sniffling.<<or>>
            The <<skald.a(girl, 'girl')>> yells something you can't make out up at the hole.  Her voice is
            distrubingly loud and alien to you.<<or>>
            The <<skald.a(girl, 'girl')>> wraps her arms around herself, shivering.
            <<half shuffled>>";
        }else {
            "<<one of>>
            <<or>><<or>><<or>><<or>>
            \b...\nYou hear a splash from the direction of the pool.<<or>>
            \b...\nYou hear a very quiet sobbing from the direction of the pool.<<or>>
            \b...\nYou hear a hear a long yell from the direction of the pool.
            <<shuffled>>";
        }
    }
    begone() {
        self.motionDaemon.removeEvent();
        self.moveInto(nil);
        plankEnd.moveInto(the_well);
        plankEnd.moved = nil;
        plank.moveInto(nil);        
    }
    
    dobjFor(Take) {
        verify() { illogical('She is out of reach, bigger than you, and too heavy to carry around.'); }
    }
    dobjFor(Drop) {
        verify() { illogical('You are not carrying {the dobj/her}.'); }
    }
    dobjFor(Attack) {
        verify() { illogicalNow('She is too far way to reach with your hands.'); }
    }
    dobjFor(AttackWith) {
        verify() { illogicalNow('She is too far way to reach with {the iobj/him}.'); }
    }
;

outside : OutdoorRoom 'Outside'
    desc  {"You stand in an empty overgrown field.  There are no living 
        trees here, but some distance away you see a very wide smooth path.  
        Standing evenly along the side of the path are a row of branchless
        poles.  A tight cable runs from pole to pole.  The path and the cable
        run in a straight line as far as you can see in either direction.
        \b
        You feel naked and cold out here.  The very wind carries iron on it, 
        burning your skin.  You can feel it crushing your heart like ice forming
        around a blossom.  This world belongs to Man now, to the child down
        in the well.  But you are a goblin, one of the last.  
        \b
        This outside world will strip the magic and the glammer from you.";
        me.deluded = nil;
    }
               
    down = the_well
    cannotGoThatWayMsg = 'There is nothing for you that way.  '
    
    leavingRoom(traveler) {
        if (girl.location == the_well) {
            "As you scramble back down through the hole in the well cover, 
            you hear a splintering crack beneath you.  You throw yourself to
            one side and then grab at a root with one hand as you start to slide
            into the well.  Beneath you, a heavy plank tears free
            of the well cover and falls into the water below.
            \b
            Clinging to the side of the well, you peer down.  You can see that 
            the plank landed on its end in the center of the pool and then 
            toppled against the far wall.  This formed
            a steep ramp.  The child is already clambering up the ramp, grabbing
            at roots, and dragging herself up out of the well.
            \b
            You carefully climb down to the tunnel ledge, you heart thumping in
            your chest.  Once there, you survey the damage to your pool.  Glancing
            up, you see that the girl is still here, staring down over the lip
            of the well.  It makes your skin crawl how she seems to be staring
            right at you... as if you had no goblin glammer left.
            \b
            Then the girl turns and disappears out of sight.  \"Good riddance!\"
            you mutter to yourself.  This whole experience has left you shaken
            and scared.";
            girl.begone();
        }
    }
;

+ Decoration 'road/path' 'path'
  "The makings of Man are best avoided."
;    
+ Decoration 'cable/rope' 'iron cable'
  "The makings of Man are best avoided."
;
+ Decoration 'pole*poles' 'pole'
  "The makings of Man are best avoided."    
;

+ plankEnd : Fixture 'end long plank/end' 'plank'
    "<<if me.location == outside>>
    It is the end of the long plank that hangs down into the well.  It is barely
    hanging on, thanks to a couple rusty nails.  It would only take a little push
    to send it down into the well.<<else>>
    One end of the heavy plank is submerged in the water, 
    while the other end leans on the far wall.<<end>>"

    initSpecialDesc = "<<if me.location == outside>>
        You can see the end of a long plank that hangs 
        down into the well.<<else>>
        A heavy plank, partially submerged in the water, leans against the far wall.<<end>>"
    
    cannotTakeMsg = 'The plank is too long and heavy to carry, but you could push it.'
    dobjFor(Push) {
        verify() { return nil; }
        action() {
            if (self.location == the_well) {
                "The plank is too far way to reach.";
            }else {
            "You push the end of the plank.  The iron nails groan a little and the 
            plank starts to sway back and forth.  You can hear the girl move
            in the water below you.  You push a little harder and the nails pop free.
            The plank drops into the water with a splash.
            \b
            Peering down after it, you can see that the plank landed on its end
            in the center of the pool and then toppled against the wall.  This formed
            a steep ramp.  The child is already clambering up the ramp, grabbing
            at roots, and dragging herself up out of the well.
            \b
            She stands, panting and dripping before you.  She is over twice your
            height, and she stares at you with wide eyes.  You stand very still... 
            but you know she can see you here.  Your glammer is fading in this 
            outside world.
            \b
            Suddenly, she turns and runs.  She stops when she gets to the
            wide path and turns back to look at you.  Tentatively, she waves.
            Then she turns and runs on before you can decide how to reply.
            \b
            Oddly, your sorrow feels lighter than it has in a long long time.";
            sorrow.weight -= 2;
            
            girl.begone();
            }
        }
    }
;
