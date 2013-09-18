#include <adv3.h>
#include <en_us.h>

/* 
 * The maze of tunnels that forms the bulk of the warren. 
 * Includes easter, western, and the mole that lives here.
 */
the_western_tunnels: Room 'The Western Tunnels'
    "Twisting tunnels stretch off in all directions through the raw earth.  
    Here and there, <<skald.a(arches)>> and <<skald.a(beams, 'wooden support beams')>> 
    shore up the weight of the soil above.  The soil is a little drier here than to the 
    east."
    
    east = the_eastern_tunnels
    west = the_queens_chambers
    
    cannotGoThatWayMsg = 'You wander through the tunnels for a while, but most of
    the minor tunnels eventually bring you back here again. '
    
    leavingRoom(traveler) {
        if (mole.alive && mole.inHole) {
            mole.moveInto(nil);
            mole.inHole = nil;
            "The mole scurries far back into his hole and disappears.\n";
        }
    }
;
+ hole : Decoration 'small hole' 'small hole'
  "The hole is barely big enough for the mole, and certainly too small for you.";
+ arches : Decoration 'stone arch*arches' 'stone arches'
  "Fine goblin craftsmanship from ages past."
    isPlural = true;
+ beams : Decoration 'wooden support beam*beams' 'support beams'
  "These are later additions to hold the tunnels up when the <<skald.a(arches, 'stone arches')>>
  started to crack. On one of these wooden posts, you started tracking years, adding one scratch 
  every winter.  After a dozen scratches, you moved onto another post.  After
  a dozen posts, you stopped scratching."
    isPlural = true;

+ mole : Food 'mole' '<<!self.alive ? 'dead ' : ''>>mole'
    "<<self.alive ? "It is a young mole with soft brown fur and muddy paws.
        It is wrinkling its nose at you as it sniffs the air in that puzzled
        near-sighted way that moles do." :
        "The mole is crumpled, wrinkled, and smeared with blood.  Its little
        nose isn't wrinkling or moving now.">>"
    alive = true
    inHole = true
    taken = nil
    initSpecialDesc = "A mole is poking the tip of his nose out of a small hole."
    initDesc = "All you can see of the mole at the moment is the pink tip of his
        twitching nose."
    
    dobjFor(Take) {
        verify() {
            if (self.inHole) {
                inaccessible('Not while he is still in that hole.');
            }else if (self.alive) {
                illogicalNow('Moles are faster than they look.  If you just try to 
                    pick him up, he\'ll be back into his hole before you can grab him.');
            }
        }
        action() {
            inherited;
            if (!mole.taken) {
                mole.taken = true;
                "When the sticky limp body of the mole sags in your hand, your 
                sorrow feels a little heavier.";
                sorrow.weight++;
            }
        }
    }
    dobjFor(AttackWith) {
        check() { 
            if (self.inHole) {
                failCheck('The mole is still safe in his hole.');
            }
//            if (IndirectObject == sword) {
//                return true; 
//            }
            inherited;
            return;
        }
        action() {
            mole.alive = nil;
            "You draw your sword slowly, then bring it down quickly on the mole.
            You hear the little snap--like that of a spring twig--as its neck
            breaks.  There is a little blood, but not much.  Still, you can smell
            the iron in it.  This mole has been near Man recently.";
        }
    }
    dobjFor(Attack) {
        check() {
            if (self.inHole) failCheck('The mole is still safe in his hole.');
        }
        action() {
            mole.alive = nil;
            "You fall suddenly onto the mole, wrapping your long fingers around it.
            It squirms free with a squeak, but you snatch at it again, squeezing it
            tight.  You can feel tiny bones snapping.  You bury your sharp teeth
            into the mole's throat.  The iron in its blood tingles and burns in 
            your mouth.  You drop the mole in surpise, but the tingling quickly
            subsides.
            \b
            \"Filthy little mole, tainted by the cold iron of Man, aren't you?
            Nevermind. Good for the Ward, you'll be.\"
            \b
            The mole does not answer.";            
        }
    }
;


the_eastern_tunnels: Room 'The Eastern Tunnels'
    "Twisting tunnels stretch off in all directions through the raw earth.  
    Here and there, stone arches and wooden support beams shore up the weight
    of the soil above.  The soil is a little moister here than to the west."

    east = the_well
    west = the_western_tunnels
    
    cannotGoThatWayMsg = 'You wander through the tunnels for a while, but most of
        the minor tunnels eventually bring you back here again. '
;
+ Decoration 'stone arch*arches' 'stone arches';
+ Decoration 'wooden support beam*beams' 'support beams';

