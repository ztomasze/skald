#charset "us-ascii"

/*
 *   ZT, May 2013: Code extended with permission from Eric Eve.
 *   Modified to use Skald.
 *   Also tweaked text in places (mostly to do with the CAPS words, and a few
 *   British->Americanisms).
 */

/*
 *   This source file represents an attempt to show what the Inform Beginners' Guide
 *   Captain Fate example might look like in a TADS 3 version. The intention is
 *   to give Inform users curious about TADS 3 (or trying to learn TADS 3) some
 *   sample source code that illustrates how to go about common tasks in TADS 3.
 *
 *   The commenting in this source file is intentionally less full than that in
 *   the companion TADS 3 version of the William Tell game, in order to let
 *   the structure of the actual game code stand out a bit more clearly. You
 *   may therefore want to study the William Tell source first to become acquainted
 *   with some of the basics.
 *
 *   Just for fun, I've also included some (optional) code to extend this game
 *   to include Captain Fate's encounter with the madman in the Granary Park.
 */

 /* To activate the extended version, uncomment the following line */
// ZT: Extended version not supported
//  #define EXTENDED_VERSION

/*
 *   Include the main header for the standard TADS 3 adventure library.
 *   Note that this does NOT include the entire source code for the
 *   library; this merely includes some definitions for our use here.  The
 *   main library must be "linked" into the finished program by including
 *   the file "adv3.tl" in the list of modules specified when compiling.
 *   In TADS Workbench, simply include adv3.tl in the "Source Files"
 *   section of the project.
 *
 *   Also include the US English definitions, since this game is written
 *   in English.
 */
#include <adv3.h>
#include <en_us.h>

//ZT: skald
#include "skald.h"
#include "skaldserver.h"

//ZT: skald
skald: SkaldUI
    verbNames = [
        LookAction -> [1010, 'Look'],
        InventoryAction -> [1010, 'Inventory'],

        ExamineAction -> [2000, 'Examine'],
        TakeAction -> [2000, 'Get'],
        DropAction -> [2000, 'Drop'],

        OpenAction -> [2000, 'Open'],
        CloseAction -> [2000, 'Close'],
        LockWithAction -> [2000, 'Lock', 'with'],
        UnlockWithAction -> [2000, 'Unlock', 'with'],

        ChangeAction -> [2000, 'Change'],
        DrinkAction -> [2000, 'Drink'],
        SwitchAction -> [2000, 'Flip'],

        AskForAction -> [2000, 'Ask', 'for'],
        GiveToAction -> [2000, 'Give', 'to'],
        AttackAction -> [2000, 'Attack'],
        PayAction -> [2000, 'Pay'],

        TravelDirAction -> [4010, 'Go']
    ]
;

modify Thing {
    // then override for things that can support these things

    dobjFor(Attack) {
        verify() { illogical('You cannot attack {that dobj/him}.'); }
    }
    dobjFor(Drop) {
        verify() {
            if (self.location == gPlayerChar) {
                logical;  // but should never happen!
            }else {
                // illogical (not illogicalNow) because should never be able to Take
                illogical('You are not carrying {the dobj/him}.');
            }
        }
    }
    
    dobjFor(GiveTo) {
        verify() { 
            // illogical to ask to give unsupported topics
            local giveTopics = skald.getTopics(gIobj, GiveToAction, true);  //asobjs
            if (!giveTopics.indexOf(gDobj)) {
                illogical('It seems unlikely that {the iobj/he} would be interested
                    in having {the dobj/him}.');
            }
        }
    }        
}

modify Room {
    dobjFor(Examine) {
        //should never happen: can't refer to locations by name
        verify() { illogical('An entire location is too big for you to examine closely.'); }
    }
}

modify CustomImmovable {
    dobjFor(Take) {
        verify() { illogical('Even though your sculpted adamantine muscles are
            up to the task, you don\'t favour property damage.'); }
    }
}

modify Person {
    dobjFor(Take) {
        verify() { illogical('{The dobj/he} probably wouldn\'t go for that.'); }
    }
}



 /*
  *  The nearest equivalent to defining the Inform LibraryMessages object
  *  is to modify the TADS 3 playerActionMessage object, e.g.:
  */

modify playerActionMessages
  cannotDigMsg = 'Your keen senses detect nothing underground worth
    your immediate attention '
  cannotBuyMsg = 'Petty commerce interests you only on counted occasions. '
  noMoneyMsg = '{You/he} {have} no money. '
;

 /*
  *  But note that in a real TADS 3 game you might not bother to modify
  *  playerActionMessages, since it might be more straightforward to override
  *  the corresponding message properties on the Thing class (or wherever).
  *  It can, however, be useful to override playerActionMessages if you want
  *  to define a new message you want to use in several different contexts.
  */

/*******************************************************************
 *    CLASSES
 *
 *    The Room class already exists in TADS 3
 *
 *    The Appliance class basically does the work of a TADS CustomImmovable
 *    with a customised message, so we'll simply modify this class:
 */

modify CustomImmovable
  cannotTakeMsg = 'Even though your sculpted adamantine muscles are up to the task,
                   you don\'t favour property damage.'
;

/*
 *   The Inform game uses the name property of the Rooms for the vocabulary
 *   of objects otherwise unimplemented in the game, so that if the player
 *   tries to refer to them, he'll be told “That’s not something you need to
 *   refer to in order to SAVE the day”. You can't do this in TADS 3 -- adding
 *   vocabWords to a room object allows the player to refer to that room object.
 *   Normally, the preferred method in TADS 3 would be to define a series of
 *   Decoration objects that provide a description in response to an EXAMINE
 *   command, or a message like "The widget is not important. " in reponse to
 *   any other command.
 *
 *   In order to make this TADS 3 game more like the Inform original we'll define
 *   an Unimportant class that responds with the desired message in response to
 *   any command, including EXAMINE. Then we can place one of these in each room
 *   to deal with the vocabulary given to the name property of the Rooms in the
 *   Inform source.
 */

class Unimportant: Decoration
  desc = "<<notImportantMsg>>"
  notImportantMsg = '{That dobj/he} {is} <i>not</i> something you need to refer to in order to save the day'

;


/**********************************************************************
 *  GAME OBJECTS
 */

/*
 *   Starting location - we'll use this as the player character's initial
 *   location.  The name of the starting location isn't important to the
 *   library, but note that it has to match up with the initial location
 *   for the player character, defined in the "me" object below.
 *
 *   Our definition defines two strings.  The first string, which must be
 *   in single quotes, is the "name" of the room; the name is displayed on
 *   the status line and each time the player enters the room.  The second
 *   string, which must be in double quotes, is the "description" of the
 *   room, which is a full description of the room.  This is displayed
 *   when the player types "look around," when the player first enters the
 *   room, and any time the player enters the room when playing in VERBOSE
 *   mode.
 */

street: OutdoorRoom 'On the street'
    desc()
    {
        if(gPlayerChar.isIn(booth))
          "From this vantage point, you are rewarded with a broad view
             of the <<skald.a(sidewalk)>> and the entrance to <<skald.a(outsideOfCafe)>>. ";
        else
          "On one side -- which your heightened sense of direction
          indicates is north -- there's an open <<skald.a(outsideOfCafe, 'cafe')>> now serving
          lunch. To the south, you can see a <<skald.a(booth, 'phone booth')>>. ";
    }

   cannotGoThatWay = "No time now for exploring! You'll move much faster in your
           Captain Fate costume. "

    south : FakeConnector { "<<replaceAction(Enter, booth)>>" }
    north : FakeConnector { "<<replaceAction(Enter, outsideOfCafe)>>" }

//ZT: crashes on both "enter" and "go in" without object given
//    in : AskConnector {
//          travelAction = EnterAction
//          travelObjs = [booth, outsideOfCafe]
//           travelObjsPhrase = 'of them'
//           promptMessage = "There are two things you could enter from here. "
//    }
;

/* We use an Unimportant object instead of adding these words to the vocabulary
 * of the street Room object. In a real TADS 3 game we'd probably use a number of
 * Decoration objects.
 */

+ Unimportant 'city/buildings/skycrapers/shops/appartments/cars'
;

Decoration 'passing people/pedestrians' 'pedestrians' @street
   "They're just people going about their daily honest business. "
   notImportantMsg = 'The passing pedestrians are of no concern to you. '
   isPlural = true
;

/*
 * Note, TADS 3 code is case-sensitive. Booth is the name of a class in the TADS 3
 * library, whereas booth is the name we've given to this particulary Booth object.
 */


booth : Booth, CustomImmovable 'old red picturesque telephone phone box/booth/cabin'
   'phone booth' @street
   "It's one of the old picturesque models, a red cabin with room
    for one caller. The tall multipaned windows on three of its sides mean that the
   inside of the booth is clearly visible to anyone on the street. "

    /* In TADS 3 you can often provide customised responses simply by defining
     * the appropriate message properties, as here */

    cannotOpenMsg = 'The booth is already open. '
    cannotCloseMsg = 'The latch is missing.  There is no way to close this booth. '

    /* Although sometimes you need to find the right method to override, as here */

    performEntry(posture)
    {
         inherited(posture);
        // can only examine phone booth from outside of it
        "With implausible celerity, you dive inside the phone booth. 
        Thanks to the booth's large windows, your view of the world remains the same. ";
    }
;

sidewalk: CustomImmovable 'sidewalk/pavement/street' 'sidewalk' @street
  "You make a quick surveillance of the sidewalk and discover much
   to your surprise that it looks just like any other sidewalk in
   the city!"
;

outsideOfCafe: Enterable ->cafe 'benny\'s cafe/entrance' 'Benny\'s Cafe' @street
  "The town's favourite for a quick snack, Benny's cafe has a 50's
   rocketship look. "
   dobjFor(TravelVia)
   {
      action()
      {
        "With an impressive mixture of hurry and nonchalance you
          step into the open cafe.<.p>";
        inherited;
      }
   }
   isProperName = true
;


//------------------------------------------------------------------------------

cafe: Room 'Inside Benny\'s Cafe'
  "Benny's offers the finest selection of pastries and sandwiches.
   Customers clog the counter, where Benny himself manages to
  serve, cook and charge without missing a step. At the north side
  of the cafe you can see a <<skald.a(toiletDoor, 'red door')>> connecting with the toilet. "

  beforeTravel(traveler, connector)
  {
    if(traveler != gPlayerChar || connector != street)
       return;

    local keyBorrowed = toiletKey.moved && benny.keyNotReturned;
    local coffeeUnpaid = coffee.moved && benny.coffeeNotPaid;

    if(coffeeUnpaid || keyBorrowed)
    {
        "Just as you are stepping into the street, the big hand
        of <<skald.a(benny)>> falls on your shoulder.\b";
        if(coffeeUnpaid && keyBorrowed)
           "<q>Hey! You've got my key and haven't paid for the
           coffee. Do I look like a chump?</q> You apologise as only a
           hero knows how to do and return inside. ";
        else if(coffeeUnpaid)
           "<q>Just waidda minute here, Mister,</q> he says.
            <q>Sneaking out without paying, are you?</q> You quickly
            mumble an excuse and go back into the cafe. Benny
            returns to his chores with a mistrusting eye. ";
        else if(keyBorrowed)
           "<q>Just where you think you're going with the toilet
           key?</q> he says. <q>You a thief?</q> As Benny forces you back
           into the cafe, you quickly assure him that it was only
           a stupefying mistake. ";

        exit;
    }
 /*
  *   If we're compiling the extended version of the game, we don't want it
  *   to end at this point, so we provide alternative versions of what happens
  *   depending on whether the game is or is not compiled with EXTENDED_VERSION
  *   defineed.
  */
  if(costume.isWornBy(traveler))
    {
    #ifdef EXTENDED_VERSION
      "You step onto the sidewalk, where the passing pedestrians
       recognise the rainbow extravaganza of Captain Fate's costume
       and cry your name in awe as your superhero leg muscles
       galvanize into action and you race eastwards at amazing speed
       towards Granary Park! ";
       replaceAction(TravelVia, outsidePark);
    #else // note that this is a compiler directive, not a programming statement
       "You step onto the sidewalk, where the passing pedestrians
        recognise the rainbow extravaganza of Captain Fate's costume
        and cry your name in awe as you leap with sensational
        momentum into the blue morning skies! ";

        finishGameMsg('You fly away to save the day!',
           [finishOptionFullScore, finishOptionUndo] );
    #endif
    }

  }

  north = toiletDoor
  south = street
  out asExit(south)
;

counter: Surface, CustomImmovable 'counter/bar' 'counter' @cafe
    "The counter is made of an astonishing alloy of metals:
   stain-proof, spill-resistant, and very easy to clean. Customers
   enjoy their snacks in utter tranquillity, safe in the knowledge
   that the counter can take it all. "
   iobjFor(PutOn) remapTo(GiveTo, DirectObject, benny)
;

food: Unimportant 'food/pastry/pastries/sandwich/sandwiches/snack/snacks/doughnut'
   'food' @cafe
   notImportantMsg = 'There is no time for food right now. '
   isPlural = true
;

menu : CustomImmovable 'informative menu/board/writing/picture' 'menu' @cafe
  "The menu board lists Benny's food and drinks, along with their
   prices. Too bad you've never learnt how to read, but luckily
   there is a picture of a big cup of coffee among the
   incomprehensible writing. "
   cannotTakeMsg = 'The board is mounted on the wall behind Benny. Besides, it\'s
        useless writing. '
;


customers: Person 'customers/customer/people/men/women' 'customers' @cafe

  isPlural = true
  uselessToAttackMsg = 'Mindless massacre of civilians is the qualification for
      villains. You are supposed to protect the likes of these people. '
  cannotKissActorMsg = 'There\'s no telling what sorts of mutant bacteria these
     strangers may be carrying around. '
  acceptCommand(issuingActor)
  {
    if(issuingActor == gPlayerChar)
    {
        "These people don't appear to be of the cooperative sort. ";
        return nil;
    }
    else
        return inherited(issuingActor);
  }
;

+ customersSitting: HermitActorState
  specialDesc = "A group of <<skald.a(customers)>> are sitting 
      around enjoying their excellent <<skald.a(food)>>. "
  stateDesc = "A group of helpless and unsuspecting mortals, the kind
    Captain Fate swore to defend the day his parents choked on a
    devious slice of rasberry pie. "
  isInitState = true

  /* We use the afterTravel method to make the customers change state
   * when the PC emerges wearing his costume.
   */
  afterTravel(traveler, connector)
  {
     if(traveler == gPlayerChar && costume.isWornBy(traveler))
       getActor.setCurState(customersCommenting);
  }

  noResponse = "As John Covarth, you attract less interest than Benny's food. "
;

/* By making the customersCommenting state inherit from StopEventList as
 * well as HermitActorState we can get it to display the list of
 * caustic comments with a minimum of programming effort.
 */

+ customersCommenting: HermitActorState, StopEventList
  [
    'Nearby customers glance at your costume with open curiosity. ',

    '<q>Didn\'t know there was a circus in town,</q> comments one
      customer to another. <q>Seems like the clowns have the
      day off.</q>',

    '<q>These fashion designers don\'t know what to do to show
      off,</q> snorts a fat gentleman, looking your way. Those
      within earshot try to conceal their smiles. ',

    '<q>Must be carnival again,</q> says a man to his wife, who
      giggles, stealing a peek at you. <q>Time sure flies.</q> ',

    '<q>Bad thing about big towns,</q> comments someone to his
      table companion, <q>is you get the damnedest bugs coming
      out from toilets.</q>',

    '<q>I sure wish I could go to work in my pyjamas,</q> says a
      girl in an office suit to some colleagues. <q>It looks so
      comfortable.</q>',

    nil
  ]

  /* The only piece of code we actually need to write on this ActorState
   * object is to override the doScript method so that it is only called
   * when the player character is in the same room as the customers, and
   * then on average only 50% of the time.
   */

  doScript()
  {
     if(gPlayerChar.isIn(getActor.location) && rand(2) == 1)
       inherited;
  }

  stateDesc = "Most seem to be concentrating on their food, but some do
    look at you quite blatantly. Must be the mind-befuddling
    colours of your costume. "

  specialDesc = "Most of the customers are concentrating on their food,
    but some of them are blatantly staring at you. "

  noResponse = "People seem to mistrust the look of your fabulous costume. "
;


benny: Person 'benny' 'Benny' @cafe
  "A deceptively fat man of uncanny agility, <<skald.a(benny)>> entertains his
   customers crushing coconuts against his forehead when the mood
   strikes him. "

   coffeeNotPaid = true
   keyNotReturned = true


   dobjFor(Attack)
   {
      verify()
      {
        if(costume.wornBy != gPlayerChar)
           illogicalNow('That would be an unlikely act for meek John Covarth. ');
      }
      action()
      {
        "Before the horror-stricken eyes of the surrounding
        people, you magnificently jump over the counter and
        attack Benny with remarkable, albeit insufficient,
        speed. Benny receives you with a treacherous upper-cut
        that sends your granite jaw flying through the cafe.\b
        <q>These guys in pyjamas think they can bully innocent
        folk,</q> snorts Benny, as the eerie hands of darkness
        engulf your vision and you lose consciousness. ";

        finishGameMsg('You have been shamefully defeated', [finishOptionScore, finishOptionUndo]);
      }
   }

   cannotKissActorMsg = 'This is no time for mindless infatuation. '

   isHim = true
   isProperName = true

   /* As a bonus, we'll also add handling for PAY BENNY */
   dobjFor(Pay)
   {
      verify()
      {
         if(!coffee.moved)
           illogicalNow('You haven\'t bought anything from him. ');
         else if(!coffeeNotPaid)
           illogicalAlready('You\'ve already paid him. ');
         else if(!coin.isIn(gActor))
           illogicalNow('You don\'t have anything to pay him with. ');
      }
      action() { replaceAction(GiveTo, coin, benny); }

   }
;

 /* This ActorState is not strictly necessary here, but in a real TADS 3 game
  * Benny would probably have at least a couple of ActorStates, so we include
  * one here to show the principle.
  */

+ BennyWorking : ActorState
  specialDesc = "<<skald.a(benny)>> is working behind the <<skald.a(counter)>>. "
  isInitState = true
;

 /* In TADS 3 we handle GIVE X TO ACTOR using GiveTopic objects rather
  * than code on the actor object itself. This allows game authors to
  * use a broadly declarative approach, instead of having to write
  * complex procedural code.
  */


++ GiveTopic @toiletKey
  topicResponse
  {
     getActor.keyNotReturned = nil;
     toiletKey.moveInto(nil);
     "<<skald.a(benny)>> nods as you admirably return his key. ";
  }
;

++ GiveTopic @clothes
  "You need your unpretentious John Covarth clothes. "
;

++ GiveTopic @costume
  "You need your stupendous acid-protective suit. "
;

++ GiveTopic @coin
  topicResponse()
  {
    coin.moveInto(nil);
    getActor.coffeeNotPaid = nil;
    "With marvellous illusionist gestures, you produce the
    coin from the depths of your <<costume.wornBy == gPlayerChar ?
    'bullet-proof costume' :' ordinary street clothes'>>
    as if it had dropped on the counter from Benny's ear!
    People around you clap politely. <<skald.a(benny)>> takes the coin
    and gives it a suspicious bite. <q>Thank you, sir. Come
    back anytime,</q> he says. ";
  }
;

/* Similar we handle ASK ACTOR FOR X using AskForTopics */

++ AskForTopic @toiletKey
   topicResponse()
   {
     toiletKey.moveInto(gPlayerChar);
     getActor.keyNotReturned = true;
     "<<skald.a(benny)>> tosses the <<skald.a(toiletKey, 'key')>> to the restrooms on the
      counter, where you grab it with a dextrous and
     precise movement of your hyper-agile hand. ";
   }
;

/* We use AltTopics to define alternative responses; an AltTopic response
 * is used when its isActive condition is true. Where the isActive condition
 * of more than one AltTopic is true, later topics take precedence over
 * earlier ones.
 */

+++ AltTopic
   "<q>Last place I saw that key, it was in your
    possession,</q> grumbles <<skald.a(benny)>>. <q>Be sure to return it
    before you leave.</q> "
    isActive = !toiletKey.isIn(nil)
;

+++ AltTopic
   "But you do have the key already."
   isActive = toiletKey.isIn(gPlayerChar)
;

+++ AltTopic
  "<q>Toilet is only fer customers,</q> he grumbles, looking
   pointedly at a menu board behind him. "
   isActive = !coffee.moved
;


++ AskForTopic @coffee
  topicResponse()
  {
     coffee.moveInto(counter);
     "With two gracious steps, <<skald.a(benny)>> places a cup of his world-famous
     <<skald.a(coffee, 'dark roast')>> in front of you. ";
  }
;

+++ AltTopic
   "One coffee should be enough. "
   isActive = coffee.moved
;

++ AskForTopic @food
  "Food will take too much time, and you must change now! "
;

++ AskForTopic @menu
  "With only the smallest sigh, <<skald.a(benny)>> nods towards the <<skald.a(menu)>>
  on the wall behind him. "
;

++ DefaultAskForTopic
  "<q>I don't think that's on the menu, sir.</q>, Benny replies. "
;

/*    A DefaultAnyTopic traps any conversational topic (Ask For, Ask About, Tell About,
 *   Give To, Show To, or a command) not explicitly handled in a more specific TopicEntry.
 */

++ DefaultAnyTopic
  "Benny is too busy for idle chit-chat. "
  isConversational = nil
;

/*
 * It will be convenient here to have two objects representing coffee, the
 * first being the picture of the cup of coffee on the menu, the second
 * being the real cup of coffee. We set them up in such a way that the
 * parser will prefer the real coffee to the picture whenever the former
 * is in scope.
 */
//ZT: changing Thing's GiveTo causes problems here

Decoration 'big menu picture/coffee' 'big menu picture' @menu
   "The picture on the menu board of a big cup of coffee sure looks good. "

    notImportantMsg = 'You should ask Benny for one first. '
   dobjFor(Buy)
   {
     verify()
     {
      if(!coin.isIn(gActor))
        illogicalNow(&noMoneyMsg);
     }
   }
;


coffee: Thing 'steaming colombian dark roast/cup/coffee' 'cup of coffee'
  "It smells delicious. "
  dobjFor(Drink)
  {
     /*
      * We need to change the preconditions here from the library default, objHeld,
      * since TAKE COFFEE is remapped to DRINK COFFEE, and objHeld will attempt an
      * implicit TAKE COFFEE, triggering a potentially infinite regress that will
      * result in a stack overflow error.
      */
     preCond = [touchObj]
     verify() { logicalRank(150, 'drinkable'); }
     action()
     {
            self.moveInto(nil);
        "You pick up the cup and swallow a mouthful. Benny's
        worldwide reputation is well deserved.
        Just as you finish, <<skald.a(benny)>> takes away the empty cup.
       <q>That will be one quidbuck sir,</q> he tells you. ";
     }
  }

  dobjFor(Take) asDobjFor(Drink)

  dobjFor(Taste) asDobjFor(Drink)

  dobjFor(Buy)
  {
     /* By making the buy attempt fail in check() rather than verify()
      * we ensure that the parser chooses this coffee object rather than
      * the picture of coffee in response to a BUY COFFEE command. This
      * avoids an annoying "Which cup of coffee do you mean?" type message.
      */

     verify() { }
     check()
     {
        if(!coin.isIn(gActor))
        {
          reportFailure(&noMoneyMsg);
          exit;
        }
     }
     action()
     {
        replaceAction(GiveTo, coin, benny);
     }
  }
  smellDesc = "If your hyperactive pituitary glands are to be trusted,
     it's Colombian. "

  /* Allow the player to refer to this object in a conversation command, e.g.
   * ASK BENNY FOR COFFEE, even before this object has been seen.
   * Note that ASK ACTOR FOR X does not in general require X to be in scope.
   */
  isKnown = true
;

outsideOfToilet : Enterable, CustomImmovable ->toiletDoor
    'bath rest room/toilet/bathroom/restroom/loo' 'restroom' @cafe
  desc()
  {
    if(toiletDoor.isOpen)
    "A brilliant thought flashes through your superlative
         brain: detailed examination of the restroom would be
         extremely facilitated if you entered it.";
    else
        "With a tremendous effort of will, you summon your
         unfathomable astral vision and project it forward towards
         the closed door... until you remember that it's
         Dr Mystere who's the one with mystic powers. ";
  }

  dobjFor(Open) remapTo(Open, toiletDoor)
  dobjFor(Close) remapTo(Close, toiletDoor)
  cannotTakeMsg = 'That would be part of the building. '
;

/*
 * In TADS 3 the standard way to define a door is to use two objects, one
 * for each side of the Door. The library code takes care of keeping the
 * two sides of the door in sync, so that (for example) opening one side
 * will automatically open the other. None of the code in the Inform version
 * of this door is needed here, since the behaviour it implements is standard
 * in the TADS 3 Door class.
 */

toiletDoor : LockableWithKey, Door 'red toilet rest room restroom door' 'restroom door' @cafe
   "A red door with the unequivocal black man-woman silhouettes
   marking the entrance to hygienic facilities. There is a
   scribbled note stuck on its surface. "
  keyList = [toiletKey]
;


toiletKey : Key 'toilet restroom key' 'restroom key'
  "Your super perceptive senses detect nothing of consequence
    about the restroom key. "

  dobjFor(Drop)
  {
    check()
    {
        reportFailure('Benny is trusting you to look after that key. ');
        exit;
    }
  }
  showInventoryItem(options, pov, infoTab)
  {
     if(clothes.isWornBy(gPlayerChar))
       "the crucial key";
     else
       "the used and irrelevant key";
  }

  /* Allow the player to refer to the key in a conversational command
   * (e.g. ASK BENNY FOR KEY) even before the key has been seen.
   */
  isKnown = true
;

CustomImmovable 'scribbled note' 'scribbled note' @cafe
  "The scorched undecipherable note holds no secrets from
   you now! Ha! "

   initDesc =  "You apply your enhanced ultrafrequency vision to the note
         on the restroom door and squint in concentration, giving up only when you see the
         borders of the note begin to blacken under the incredible
         intensity of your burning stare. You reflect once more how
         helpful it would've been if you'd ever learnt to read.\b
         A kind old lady passes by and explains:
         <q>You have to ask <<skald.a(benny)>> for the key, at the counter.</q>\b
         You turn quickly and begin, <q>Oh, I know that, but...</q>\b
         <q>My pleasure, son,</q> says the lady, as she exits the cafe. "


   /* By default a TADS 3 object is in its initState until it is moved;
    * but we want this note to be in its initState only until it has been
    * described. This ensures that players see the initDesc the first time
    * they issue an EXAMINE NOTE command, and the standard desc thereafter.
    */
   isInInitState = (!described)

;

//-------------------------------------------------------------------------

toilet: Room 'Unisex Toilet'
  "A surprisingly clean square room covered with glazed-ceramic
   tiles, featuring little more than a <<skald.a(lavatory)>> and a <<skald.a(lightSwitch)>>.
   The only exit is south, through the door and into the cafe. "

   south = toiletDoorInside
   out asExit(south)

   /* The brightness property controls whether a room is lit or
    * dark. Normally, a brightness of 3 is lit, while 0 is dark.
    * We can define this property declaratively so that it
    * automatically adjusts when the door is open or closed.
    */
   brightness = (toiletDoor.isOpen ? 3 : 0)

   /* The scoring scheme used in the Inform version is not native to
    * TADS 3, so we'll replace it with one that is.
    */

   enteringRoom(traveler)
   {
     if(traveler == gPlayerChar)
       /* Note that if we award all our points this way, the game will
        * calculate the maximum score for us.
        */
       achievement.awardPointsOnce();
   }
   achievement: Achievement { +1 "entering the toilet" }

   /* This is the code we need to make the light switch and door remain
    * in scope even when the toilet is dark.
    */
   getExtraScopeItems(actor) { return [lightSwitch, toiletDoorInside]; }
;

/*
 * Note the syntax for linking the two sides of the same Door together;
 * one of the Door objects (but not both) has to point to the other,
 * which we can do simply with the -> toiletDoor location.
 * This achieves three things:
 *
 *     First it keeps both sides of the door
 *  in sync, so that opening, closing, locking and unlocking one side of
 *  the door is reflected in the state of the other side of the door.
 *
 *     Second, it defines where the door leads to (the library assumes that
 *  a door leads to the location of its other side; so, for example, toiletDoorInside
 *  leads to toiletDoor.location, i.e. the cafe).
 *
 *     Third, it tells the parser that the two sides of the Door are facets
 *  of the same physical object for the purposes of pronoun resolution, so that,
 *  for example, if the player types OPEN DOOR (referring to toiletDoorInside)
 *  then SOUTH (thereby moving into the cafe) then EXAMINE IT, the parser will
 *  take IT to refer to toiletDoot (toiletDoorInside no longer being in scope).
 *
 */


toiletDoorInside: LockableWithKey, Door -> toiletDoor
  'red (toilet) cafe restroom door' 'restroom door'  @toilet
  "A red door with no outstanding features. "
  keyList = [toiletKey]
;

/* Note, we can just use the standard library Flashlight class here
 * to achieve the same effect as the code on the equivalent object
 * in the Inform version.
 */

lightSwitch : Flashlight, Fixture 'light switch' 'light switch' @toilet
  "A notorious achievement of technological science, elegant yet
   easy to use. "
  dobjFor(Push) asDobjFor(Switch)

    dobjFor(Switch) {
        action() {
            inherited;
            if (self.isOn && !coin.moved) {
                "As the fluorescent bulb flickers to life, your keen eyes catch a
                subtle glint from the across the room near the <<skald.a(lavatory)>>. ";
            }
        }
    }
;

lavatory: CustomImmovable 'toilet/lavatory/loo/bog/john/bowl/can/wc' 'toilet' @toilet
  "It's just a bog standard lavatory. "
  initDesc()
  {
     coin.makePresent();
     "The latest user civilly flushed it after use, but failed to
     pick up the valuable <<skald.a(coin, 'coin')>> that fell from his pants. ";
  }
  isInInitState = (!described)
  dobjFor(LookIn) asDobjFor(Examine)

  /* A slight variation from the Inform version: we remap LookUnder to Examine
   * only if the lavatory hasn't been Examined before; otherwise we use the
   * default LookUnder handling to provide a more appropriate response.
   */
  dobjFor(LookUnder) maybeRemapTo(!described, Examine, self)

  notAContainerMsg = 'While any other mortals might unwittingly throw just about
         anything into {the dobj/him} you remember the wise teachings
         of your mentor, Duke Elegant, about elderly plumbing and rising
         waters. '

;

/* We can make the coin object a PresentLater rather than moving it with
 * moveInto when the player char examines the lavatory.
 */

coin: PresentLater, Thing 'valuable silver coin/quidbuck' 'silver coin' @toilet
  "It's a genuine silver quidbuck. "

  dobjFor(Take)
  {
    action()
    {
        inherited;
        "You crouch into the Sleeping Dragon position and deftly, with
        paramount stealth, you pocket the lost <<skald.a(coin, 'coin')>>. ";
        achievement.awardPointsOnce();
    }
  }
  achievement:Achievement { +1 "finding the lost coin" }
;



/*
 *   Our game credits and version information.  This object isn't required
 *   by the system, but our GameInfo initialization above needs this for
 *   some of its information.
 *
 *   IMPORTANT - You should customize some of the text below, as marked:
 *   the name of your game, your byline, and so on.
 */
versionInfo: GameID
    name = 'Captain Fate'
    byline = 'by Roger Firth and Sonja Kesserich (this TADS 3
     version by Eric Eve, modified by Zach Tomaszewski)'
    htmlByline = 'by <a href="mailto:your-email@your-address.com">
                  YOUR NAME</a>'
    version = '1.0'
    authorEmail = 'YOUR NAME <your-email@your-address.com>'
    desc = 'CUSTOMIZE - this should provide a brief description of
            the game, in plain text format.'
    htmlDesc = 'CUSTOMIZE - this should provide a brief description
                of the game, in <b>HTML</b> format.'

    showCredit()
    {
        /* show our credits */
        "Original Inform version of <i>Captain Fate</i> by Roger Firth and Sonja
         Kesserich. This TADS 3 version offered with their kind permission.\b
         Translation to TADS 3 by Eric Eve.\b
        Minor modifications and support for Skald UI added by Zach Tomaszewski.\b";
         #ifdef EXTENDED_VERSION
           "TADS 3 Extensions to original Inform version of the game by Eric Eve.\b";
         #endif
         "TADS 3 Language and Library by Michael J. Roberts. ";

        /*
         *   The game credits are displayed first, but the library will
         *   display additional credits for library modules.  It's a good
         *   idea to show a blank line after the game credits to separate
         *   them visually from the (usually one-liner) library credits
         *   that follow.
         */
        "\b";
    }
    showAbout()
    {
        "<q>Captain Fate</q> was originally written as a programming example for
         the <i>Inform Beginner's Guide</i>. The current game represents an
         attempt to reproduce the same game in TADS 3";
       #ifdef EXTENDED_VERSION
        ", together with a brief extension that finally brings Captain FATE face
         to face with the dreaded madman";
       #endif
        ". ";
    }
;

//-----------------------------------------------------------------------
// The player and his possessions

me: Actor
    /* the initial location */
    location = street
    name = 'yourself'
;

+ clothes: Wearable 'ordinary street clothes/clothing' 'your ordinary clothes'
   "Perfectly ordinary-looking street clothes for a nobody like
     John Covarth "
  isPlural = true
  isQualifiedName = true
  wornBy = gPlayerChar

  dobjFor(Wear)
  {
    verify()
    {
        if(isWornBy(gActor))
          illogicalAlready('You are already dressed as John Covarth. ');
        else
          illogicalNow('The town needs the power of Captain Fate, not the anonymity
                 of John Covarth. ');
    }
  }

  dobjFor(Doff)
  {
    verify()
    {
        if(!isWornBy(gActor))
          illogicalNow('Your keen eye detects that you\'re no longer wearing them. ');
    }
    check()
    {
        switch(gActor.getOutermostRoom)
        {
           case street:
             if(gActor.isIn(booth))
              "Lacking Superman's super-speed, you realise that it
              would be awkward to change in plain view of the passing
              pedestrians. ";
             else
              "In the middle of the street? That would be a public
               scandal, to say nothing of revealing your secret
               identity. ";
             exit;
           case cafe:
             "<<skald.a(benny)>> allows no monkey business in his establishment. ";
             exit;
           case toilet:
             if(toiletDoor.isOpen)
             {
                "The door to the cafe stands open to tens of curious eyes.
                You'd be forced to arrest yourself for lewd conduct.";
                exit;
             }
             if(!gActor.canSee(self))
             {
                "Last time you changed in the dark, you wore the suit inside
                 out! ";
                 exit;
             }
             break;
           default:
             "There must be better places to change your clothes! ";
             exit;
        }
    }
    action()
    {
        "You quickly remove your street clothes and bundle them
         up together into an infra minuscule pack ready for easy
         transportation. ";
         if(toiletDoorInside.isLocked)
         {
            inherited;
            costume.wornBy = gActor;
            "Then you unfold your invulnerable-cotton costume and
             turn into Captain Fate, defender of free will, adversary
             of tyranny! ";
         }
         else
         {
             "Just as you are slipping into Captain Fate's costume,
             the door opens and a young woman enters. She looks at
             you and starts screaming, <q>RAPIST! NAKED RAPIST IN THE
             TOILET!!!</q>\b
             Everybody in the cafe quickly comes to the rescue, only
             to find you ridiculously jumping on one leg while trying
             to get dressed. Their laughter brings a quick end to
             your crime-fighting career! ";
             finishGameMsg('Your secret identity has been revealed',
               [finishOptionFullScore, finishOptionUndo]);
         }
    }
  }

  dobjFor(Change) asDobjFor(Doff)

;

+ costume: Wearable 'captain fate\'s captain\'s fate costume/suit' 'your costume'
  "It is state-of-the-art manufacture, from chemically reinforced 100%
   Cotton-lastic(tm). "
   dobjFor(Wear)
   {
     verify()
     {
        if(isWornBy(gActor))
          illogicalAlready('You are already dressed as Captain Fate. ');
        else
          illogicalNow('First you\'d have to take off your commonplace unassuming
            John Covarth incognito street clothes. ');
     }
   }

   dobjFor(Doff)
   {
     verify()
     {
        if(isWornBy(gActor))
          illogical('You need to wear your costume to fight crime! ');
        else
          illogicalAlready('You can\'t change out of your costume because
              you\'re not yet wearing it! ');
     }
   }
   dobjFor(Change) asDobjFor(Doff)

   dobjFor(Drop)
   {
     check()
     {
        "Your unique multi-coloured Captain Fate costume? The most
        coveted clothing item in the whole city? Certainly not! ";
        exit;
     }
   }

   isQualifiedName = true
;


/*
 *   The "gameMain" object lets us set the initial player character and
 *   control the game's startup procedure.  Every game must define this
 *   object.  For convenience, we inherit from the library's GameMainDef
 *   class, which defines suitable defaults for most of this object's
 *   required methods and properties.
 */
gameMain: GameMainDef
    /* the initial player character is 'me' */
    initialPlayerChar = me

    newGame() {
        // optional command line args: port number
        if (libGlobal.commandLineArgs.length() > 1) {
            skaldServer.port = toInteger(libGlobal.commandLineArgs[2]);
        }
        if (libGlobal.commandLineArgs.length() > 2) {
            skaldServer.hostname = libGlobal.commandLineArgs[3];
        }
        //CONT:
        // Document hostname requirements....
        
        
        skald.start();
        //XXX: for now, score links cause problems in SkaldUI, so turn off
        libGlobal.scoreObj.scoreNotify.isOn = nil;
        
        inherited();
        skald.shutdown();
    }


    /*
     *   Show our introductory message.  This is displayed just before the
     *   game starts.  Most games will want to show a prologue here,
     *   setting up the situation for the player, and show the title of the
     *   game.
     */
    showIntro()
    {
        "Impersonating mild mannered John Covarth, assistant help boy at an
         insignificant drugstore, you suddenly stop when your acute hearing
         deciphers a stray radio call from the police. There's some madman
         attacking the population in Granary Park! You must change into your
         Captain Fate <<skald.a(costume, 'costume')>> fast...!\b";
    }

    /*
     *   Show the "goodbye" message.  This is displayed on our way out,
     *   after the user quits the game.  You don't have to display anything
     *   here, but many games display something here to acknowledge that
     *   the player is ending the session.
     */
    showGoodbye()
    {
        "<.p>Thanks for playing!\b";
    }
;

/* Although the TADS 3 library was meant to translate X, GIVE ME Y into ASK X FOR Y,
 * this has never worked, so we include the following StringPreParser to do the job.
 * This basically checks whether any player input is of the form XXXXX, GIVE ME YYYYY, and
 * if it is, replaces it with ASK XXXXX FOR YYYYY before passing it on to the parser.
 */

StringPreParser
  runOrder = 90
  doParsing(str, which)
     {
         local workStr = str.toLower;
         local iComma = workStr.find(',');
         local iGiveMe = workStr.find('give me');
         if(iComma == nil || iGiveMe == nil)
           return str;
         str = 'ask ' + workStr.substr(1, iComma-1)
          + ' for ' + workStr.substr(iGiveMe + 8);

         return str;
     }

;

//============================================================================
// Extended grammar

DefineTAction(Change)
;

VerbRule(Change)
  ('change' | 'exchange' |'swap' | 'swop') singleDobj
  : ChangeAction
  verbPhrase = 'change/changing (what)'
;


DefineTAction(Buy)
;

VerbRule(Buy)
  ('buy' | 'purchase') singleDobj
   :BuyAction
   verbPhrase = 'buy/buying (what)'
;

/* While we're at it, we'll define a PAY verb */

DefineTAction(Pay)
;

VerbRule(Pay)
  'pay' singleDobj
  :PayAction
  verbPhrase = 'pay/paying (whom) '
;

DefineTAction(AskForTopicList);
VerbRule(AskForTopicList)
    'askfor' singleDobj : AskForTopicListAction
;
modify Person {
    dobjFor(AskForTopicList) {
        action() {
            "You can ask me for these things: <<toString(skald.getTopics(self, AskForAction))>>\n";
        }
    }
}

modify Thing
  dobjFor(Change)
  {
     preCond = [touchObj]
     verify()
      {
          illogical('{That dobj/he} {is} not something {you/he} must change to save the day. ');
      }
  }

  dobjFor(Buy)
  {
    verify() { illogical(&cannotBuyMsg); }
  }

  dobjFor(Pay)
  {
    verify() { illogical('You neither can nor need to pay {the dobj/him}. '); }
  }
;

// END OF ORIGINAL VERSION

/****************************************************************************
 * EXTRA CODE FOR EXTENDED VERSION
 *
 *   This extension to the original Captain FATE game follows the eponymous
 *   hero through to his triumphant encounter with the madman in Granary Park.
 *
 *   On leaving Benny's cafe dressed in his Captain Fate costume, our hero is
 *   taken straight to the entrance of the park. The entrance is, however, guarded
 *   by a policewoman who will not allow any member of the public - Captain Fate
 *   included - to enter the park. The solution is for Fate to make the policewoman
 *   run away; this may be achieved by showing her the rat which may be discovered
 *   in the sewer just to the east. To enter the sewer Fate first has to move the
 *   plastic cone that's on top of the manhole cover, descend into the sewer, and
 *   then look in the water.
 *
 *   Once the policewoman has run away from the rat, Fate is free to enter the park,
 *   where the madman is still on the rampage. Fate only has a few turns before the
 *   madman will turn his attention to him and kill him. If, however, Fate is either
 *   brave enough or rash enough to attempt to attack first, the madman dies laughing,
 *   and Fate will have saved the day.
 */

#ifdef EXTENDED_VERSION

outsidePark: OutdoorRoom 'Outside Granary Park'
  "This part of the city is entirely deserted, apart from the police cars lining the street
   and the anxious policemen patrolling the outside of Granary Park, which lies just to
   the north. The deserted street continues to east and west. "

  north = granaryPark
  west: FakeConnector { "You're not going back that way until you've rid the city of the terrible
     MADMAN. " }
  east = eastStreet

;

+ Enterable ->granaryPark 'granary park/entrance' 'Granary Park'
  "Granary Park is the city's main recreation space, in ordinary times a place
   of peace and tranquillity. Its entrance lies just to the north. "
;

+ Decoration 'blue white police cars' 'police cars'
  "Blue and white police cars line the south side of the street. "
  isPlural = true
;

+ police: Decoration 'anxious policemen' 'anxious policemen'
  "Most of them look like they're more intent on keeping the public and themselves
   out of harm's way than on tackling the MADMAN in the park. "
;

/* We set this policewoman up to be more like a typical TADS 3 implentation of an NPC */


policewoman: Person 'female police policewoman/woman/officer' 'policewoman' @outsidePark
  "A courageous upholder of the LAW, dedicated to the PEACE and SECURITY of the city. "
  isHer = true

  uselessToAttackMsg = 'Captain FATE does not attack officers of the LAW! '
  cannotKissActorMsg = 'She may be pretty enough, but you have your SUPERHERO reputation
    to consider! '
;

/*
 *  The following code illustrates the typical TADS 3 way of handling NPC conversation.
 *  We give the policewoman two ActorStates (in a more complex game she might have many
 *  more). She starts in the ConversationReadyState, which supplies a description of
 *  what she's doing when she's not talking with the player character. When the PC addresses
 *  her, the associated HelloTopic response is displayed to register the start of the
 *  conversation, and she switches into her associated InConversationState. At the end of
 *  the conversation, she switches back to her ConversationReadyState and her ByeTopic
 *  response is displayed. A conversation is ended if (a) the player explicitly issues
 *  a BYE command or (b) the Player Character leaves the area or (c) the PC fails to
 *  engage in conversation for several turns in a row.
 */


+ policeTalking: InConversationState
  /* The description shown in room descriptions */
  specialDesc = "The police officer is standing just in front of the park entrance,
   eyeing you suspiciously. "

  /* This description is added to that in the policewoman's desc property for display
   * in response to an EXAMINE POLICEWOMAN command.
   */
  stateDesc = "She's eyeing you suspiciously. "

  /*
   * The following code makes the policewoman intercept the PC's attempt
   * to enter the park.
   */
  beforeTravel(traveler, connector)
  {
     if(traveler == gPlayerChar && connector == granaryPark)
     {
       /* This triggers the 'no-entry' ConvNode (Conversation Node) -- see below */
       getActor.initiateConversation(nil, 'no-entry');
       exit;
     }
     inherited(traveler, connector);
  }
;

/*  As a convenience, TADS 3 allows us to associate a ConversationReadyState
 *  with a particular InConversationState by locating the former in the latter.
 */

++ policeGuarding: ConversationReadyState
  specialDesc = "A female police officer stands guard just by the entrance to
   the park. "
   stateDesc = "She's standing guard by the park entrance. "

  /* Mark this as the state this actor starts out in */
  isInitState = true

  /*
   * We have to make this test here as well. It seems tedious to have to repeat
   * effectively the same code on both ActorStates, and it would be possible
   * to avoid this with a slightly different coding pattern -- but for the
   * sake of clarity we'll simply repeat it here.
   */
  beforeTravel(traveler, connector)
  {
     if(traveler == gPlayerChar && connector == granaryPark)
     {
       getActor.initiateConversation(policeTalking, 'no-entry');
       exit;
     }
     inherited(traveler, connector);
  }
;

/*
 *  The HelloTopic is triggered in response to TALK TO POLICEWOMAN, or
 *  POLICEWOMAN, HELLO (explicit triggering) or in response to any conversational
 *  command (e.g. ASK POLICEWOMAN ABOUT MADMAN) addressed to this actor (implicit
 *  triggering). For a more complex NPC we could distinguish between explicit and
 *  implicit triggering by supplying an ImpHelloTopic for the latter.
 *
 *  Note also the use of StopEventList to vary the response. A StopEventList
 *  works through every item in its list until it reaches the last one, which
 *  it will then keep repeating.
 */

+++ HelloTopic, StopEventList
  [
    '<q>Good morning, officer,</q> you greet her.\b
     <q>Good morning, sir,</q> she replies dubiously, <q>Been to a fancy
      dress party?</q>',

    '<q>Hello again!</q> you declare cheerily.\b
     <q>Hello,</q> she replies warily. '
  ]
;

+++ ByeTopic
  "<q>Cheerio, then!</q> you say.\b
   <q>Have a nice day!</q> she replies. "

;

 /*
  *  While HelloTopic and ByeTopic need to be located in the ConversationReadyState,
  *  the main TopicEntries should be located in the InConversationState, or directly
  *  in the Actor object (if you want them to be common to all ActorStates). Here
  *  we could do either, but for sake of illustration we'll put them in the InConversationState.
  */

++ AskTellTopic, StopEventList @madman
 [
  '<q>So there\'s a raging MADMAN in the park!</q> you tell her.\b
   <q>That\'s right, sir,</q> she tells you, <q>But don\'t worry, we\'ll
   soon have everything back under control! Mind you,</q> she adds confidentially,
   <q>I gather he\'s <i>so</i> mad that he\'s even eating <i>rats</i> in there!
   Ugh! The very thought of it -- I can\'t stand rats!</q><.reveal rat-phobia>',

   '<q>So what are you doing about this madman?</q> you enquire.\b
    <q>Don\'t worry, sir -- we\'ll soon have everything back under control,</q>
     she assures you. '
 ]
;

/*
 *   The following topic allows the player to follow up the clue about the
 *   policewoman's dislike of rats with a further question; but we won't
 *   allow it to be an active (reachable) topic of conversation until
 *   the policewoman first mentions her dislike of rats. We achieve this
 *   through the <.reveal rat-phobia> tag in her initial reply about the
 *   madman, coupled with the test for gRevealed('rat-phobia') below.
 */

++ AskTellTopic @rat
  "<q>What's so terrible about rats?</q> you ask her.\b
   <q>How can you ask?</q> she shudders, <q>They\'re such <i>horrid</i>
   creatures -- I can't <i>bear</i> to be near one!</q>"
  isActive = gRevealed('rat-phobia')
;

/* Note that the following topic will be triggered by
 * ASK POLICEWOMAN ABOUT HERSELF as well as the more obvious phrasings.
 */

++ AskTellTopic, StopEventList [policewoman, police]
  [
    '<q>Have you been guarding this spot long?</q> you enquire.\b
     <q>Ever since the report of the madman\'s attack came through,</q>
      she tells you. ',

    '<q>Do you have the situation under control?</q> you ask.\b
     <q>We soon will have,</q> she assures you. ',

    '<q>Are you sure you can cope here -- are you all right?</q>
     you enquire.\b
     <q>Perfectly all right, don\'t you worry, sir,</q> she assures you
     in a tone of voice specially reserved for daft-looking men in
     silly costumes. '
  ]
;

++ GiveShowTopic @rat
  topicResponse()
  {
    "The policewoman takes one look at the rat and lets out a loud shriek.
    <q>AIEE! It's a horrid smelly RAT!</q> she cries, <q>I can't stand rats!</q>\b
    Still screaming in terror and disgust, she runs off down the street. ";
    getActor.moveInto(nil);
    achievement.awardPointsOnce();
  }
  achievement: Achievement { +1 "persuading the policewoman to desert her post " }
;

++ GiveShowTopic @cone
  "<q>I found this cone left in the middle of the road,</q> you tell her.\b
   <q>Then I suggest you put it back where you found it sir,</q> she replies. "
;

  /* The response to be displayed in response to an attempt to GIVE or SHOW
   * the policewoman anything for which we have not provided a more specific
   * response.
   */

++ DefaultGiveShowTopic
  "<q>We're not allowed to accept gifts from members of the public, sir.</q>
   she tells you, as you try to offer her {the dobj/him}. "
;

 /*  The following Topic provides a response to any movement command
  *  the player attempts to address to the policewoman, e.g.
  *  OFFICER, GO EAST
  */
++ CommandTopic @TravelAction
  "<q>My orders are to stay right here,</q> she tells you. "
;

 /*
  * The DefaultCommandTopic handles any other commands directed at the
  * policewoman.
  */

++ DefaultCommandTopic
  "<q>I only accept orders from my superiors,</q> she tells you. "
;

 /*
  *  Finally, we apply a catch-all topic to handle anything we haven't
  *   already provided more specific handling for. In this case, the
  *   DefaultAnyTopic will handle all ASK ABOUT, ASK FOR and TELL ABOUT
  *   commands for which no specific TopicEntries have been defined.
  *   Otherwise Give, Show and orders commands will be handled by
  *   the more specific DefaultGiveShowTopic and DefaultCommandTopic
  */

++ DefaultAnyTopic
  "<q>That's not something I\'m in a position to discuss with you right now sir,</q> she
    tells you. "
;

 /*
  *  A ConvNode object provide a means by which an NPC can ask a question or
  *  make a statement to which the player character can offer explicit responses.
  *
  *  Note that a ConvNode must be located directly within its associated actor.
  */

+ ConvNode 'no-entry'
 /* The message to display when this ConvNode is activated */

  npcGreetingMsg = "<q>I'm afraid you can't go in the park just now, sir,
   there's a madman still loose!</q> she tells you. "
;

/*
 *  The topics that are valid only when this ConvNode is active are located
 *  directly in the ConvNode. The way this ConvNode is set up, it will be
 *  active only for the single turn directly following the display of its
 *  npcGreetingMsg.
 *
 *  Here we employ a pair of SpecialTopics to allow the player to respond
 *  in a way outside the normal ASK/TELL grammar. The first single-quoted
 *  string after the SpecialTopic class name is the prompt that will be
 *  displayed to the player to indicate that this is one possible response.
 *  The list of words that follows defines the vocabulary that may be used
 *  to trigger this SpecialTopic. The SpecialTopic is triggered if and only
 *  if all the words the player types in response are included in this list.
 *  E.g. the first SpecialTopic will be triggered by AGREE IT'S TOO DANGEROUS
 *  or AGREE or IT IS DANGEROUS or DANGEROUS but not by SAY IT'S DANGEROUS.
 *  The trick is to try to anticipate as many as possible of the phrasings
 *  a player might use to select this response, given the phrasing you
 *  offer in the first string ('agree it\'s too dangerous').
 *
 *  Note that SpecialTopics can only be used in ConvNodes, but that all
 *  the other kinds of TopicEntry (AskTopic etc.) may also be used in
 *  ConvNodes.
 */

++ SpecialTopic 'agree it\'s too dangerous' ['agree', 'it', 'is', 'it\'s', 'its', 'too', 'dangerous']
  "<q>Quite right, officer,</q> you concur, <q>it must be far too dangerous for
    a member of the public to go in there with a MADMAN on the rampage.</q>\b
   <q>Precisely, sir,</q> she nods. "
;

++ SpecialTopic 'tell her you\'re Captain FATE'
   ['tell', 'her', 'you', 'are', 'you\'re', 'i', 'am', 'i\'m', 'captain', 'fate']
   "<q>But I'm Captain FATE, renowned SUPERHERO and defender of the weak!</q> you
    protest, <q>Dealing with rampaging madmen is all in a day's work for me -- it's
    what I came here for!</q>\b
   <q>Of course you are, sir,</q> she replies soothingly, <q>But I have my orders and
    I'm afraid no one's allowed in there -- not even folks in fancy dress!</q> "
;


granaryPark: OutdoorRoom 'Granary Park'
  "This once was a peaceful park, in which courting couples could safely canoodle
   behind discrete bushes, mothers take their toddlers for a safe walk, and rheumy-eyed
   old men sit watching the world go by on thoughtfully-provided wooden benches. But
   now the bushes have been uprooted, the benches smashed, and the whole park made
   to look like a sorry WASTELAND. "
   south = outsidePark

   /* Make OUT behave like SOUTH without listing it as a separate exit */
   out asExit(south)
;

+ Decoration 'uprooted bush/bushes/flora' 'bushes'
  "Parts of the destroyed bushes lie strewn across the park. "
  isPlural = true
;

+ Decoration 'smashed bench/benches/fragments' 'benches'
  "None of the benches here will ever be sat on again. They have all been
   SMASHED to FRAGMENTS. "
;

madman: Person 'tall mean mean-looing giant madman' 'madman' @granaryPark
   "This madman is a GIANT; he's nearly EIGHT feet tall, and mean-looking
    with it. "
    isHim = true
    isKnown = true // so he can be referred to in conversation before he's been seen
    dobjFor(Attack)
    {
       action()
       {
          "With more COURAGE than SENSE you charge towards the murderous MADMAN.
           He turns to you with a TERRIFYING cry, raising his arms in readiness
           to REND you limb from limb. But, just then, he catched sight of your
           RIDICULOUS Captain FATE costume, and bursts into fits of HELPLESS
           laughter. This causes him to CHOKE on the park-keeper leg he was
           chewing, and the choking proves FATAL. Turning first bright red and
           then sickly green, the terrible MADMAN collapses onto the ground and
           DIES!\b
           The police and citizenry of the city RUSH into the park to see what
           has happened, and hail you as the greatest COMIC HERO of the decade!\b ";
           achievement.awardPointsOnce();
          finishGameMsg(ftVictory, [finishOptionUndo, finishOptionFullScore] );
       }
    }
    achievement: Achievement {+2 "bringing about the madman's demise " }
;

 /*
  *  We can simply use an EventList here, since if the final item is reached
  *  the game will end. The HermitActorState is a useful ActorState to use
  *  for an Actor who is currently unresponsive to conversation.
  */

+ HermitActorState, EventList
  [
    'The MADMAN picks up another severed limb and starts chewing on it. ',
    'The MADMAN glowers at you furiously, but then turns his attention back to
     destroying more immediate targets. ',
    'The MADMAN starts lumbering towards you! ',

    /*
     *  Single-quoted strings in an EventList are simply displayed. The odd-looking
     *  syntax below allows an EventList item to do something more complex. Between
     *  the braces following the new function keywords we could write any code
     *  we liked, and it'll be executed when this item in the list is reached.
     */
    new function {
       "The MADMAN reaches you, hits you across the head with his POWERFUL RIGHT
         HAND, and breaks your neck! ";
        finishGameMsg(ftDeath, [finishOptionUndo, finishOptionFullScore]);
    }
  ]
  isInitState = true
  specialDesc =  "A terrible GIANT madman is rampaging around the park, tearing up the
    flora and eating whatever's left of the fauna. "
  stateDesc = "He's rampaging round the park causing TERRIBLE destruction. "

  /* This is the response the madman will make to any conversational command addressed
   * to him.
   */
  noResponse = "In response the MADMAN merely lets out a terrible BLOOD-CURDLING
   growl. "

  /* We only want the madman to work through his eventList when the PC is present */
  doScript()
  {
     if(gPlayerChar.isIn(getActor.getOutermostRoom))
       inherited;
  }

  /* Reset the eventList back to the first item in the list each time the PC arrives on the scene */
  afterTravel(traveler, connector)
  {
      curScriptState = 1;
      inherited(traveler, connector);
  }
;

eastStreet: OutdoorRoom 'Deserted Street'
  "This section of street looks even more deserted; obviously news of
   MADMAN has terrified the local populace into fleeing. All the shops
   are shut up, and there's not a soul on the sidewalk<< cone.moved ? ''
   : ' -- just a lonely red plastic cone stationed in the middle of the road
   to keep traffic from passing by the park during the present emergency' >>. "

  east : FakeConnector { "That would take you even further from the park, and
    Captain Fate NEVER runs away from DANGER! " }
  west = outsidePark
  down = manhole
;

+ Decoration 'shop/shops' 'shops'
  "All the shops round here look shut for the day. "
  isPlural = true
;

+ Unimportant 'city/road/street/sidewalk/pavement'
;

+ cone: Thing 'large lonely annoying red plastic cone*cones' 'large red plastic cone'
  "It's just one of those annoying objects that seem to BREED in large
    numbers for the express purpose of obstructing motorists. "

  /*
   *  If the cone is picked up or simply moved aside, the manhhole cover
   *  beneath will be revealed. We need handling on this for both TAKE CONE
   *  and MOVE CONE.
   */

  dobjFor(Take)
  {
    action()
    {
        if(!manhole.discovered)
        {
            "Picking up the cone reveals a manhole cover beneath. ";
            manhole.discover();
        }
        inherited;
    }
  }
  dobjFor(Move)
  {
    action()
    {
      if(manhole.discovered)
        inherited;
      else
      {
       "Moving the cone to one side reveals a manhole cover in the road. ";
        manhole.discover();
      }
    }
  }
  /*
   *  If the manhole hasn't been discoverered yet, make PUSH or PULL this
   *  cone behave like MOVE CONE.
   */
  dobjFor(Push) maybeRemapTo(!manhole.discovered, Move, self)
  dobjFor(Pull) maybeRemapTo(!manhole.discovered, Move, self)

  /*
   *  Since the cone is mentioned in the room description until it's moved, we
   *  don't want it listed separately until it has been moved.
   */
  isListed = (moved)
;

/*
 *  By making the manhole a Hidden, we keep it out of sight until we call its
 *  discovered method. By making it a SecretDoor we keep the exit lister from
 *  showing that travel is possible this way (in this case down) until the
 *  manhole cover is open. We need to add Openable to the class list to allow
 *  the manhole to respond to OPEN and CLOSE commands (which SecretDoor, unlike
 *  door, will not do by default).
 */

+ manhole: Hidden, Openable, SecretDoor 'manhole circular cover/piece/metal'
   'manhole cover'
  "It's a circular piece of metal in the middle of the road, probably
   covering the entrance to a sewer beneath. <<isOpen ? 'It\'s open. ' : ''>> "
  destination = sewer
  dobjFor(Pull) asDobjFor(Open)
  dobjFor(Push) asDobjFor(Close)
;


sewer: Room 'Sewer'
   "This VILE and malodorous sewer runs along a stone tunnel under the street;
     trickling along the bottom of the sewer is a shallow stream of liquid
     that your super-sensitive sense of smell detects to be a mixture
     of water and effluent. "
  up = eastStreet
  east: FakeConnector { "You have NO desire to follow this malodorous sewer on
     its FILTHY course -- you might soil your Captain FATE costume! " }
  west: FakeConnector { "Your DARKNESS-PENETRATING sight detects that in that
     direction the sewer does not lead to any place FIT for SUPERHEROES. " }
;

+ Fixture 'vile rank shallow water/effluent/stream/liquid/mixture' 'water'
  "It's really rather RANK. "
  cannotDrinkMsg = 'This muck is not fit for SCUM, let alone superheroes! '
  dobjFor(LookIn)
  {
    action()
    {
        if(rat.discovered)
          inherited;
        else
        {
            rat.discover();
            "Your PENETRATING sight detects a large brown rat lurking in the filthy water. ";
        }
    }
  }
;

+ rat: Hidden 'large brown fierce rat/rodent*rats*rodents' 'large brown rat'
   "It's a large, fierce rodent -- but NO match for your superhero GRIP. "
   initSpecialDesc = "A large brown rat is lurking in the vile water. "
   isKnown = true // to make rats a possible topic of conversation before this one found.
;

/*
 *  Note how we use a separate object to deal with the smell of the rat.
 */

++ Odor
  /* The description to add to the description of the rat when it's EXAMINEd */
  sourceDesc = "It smells strongly of effluent-stained RODENT. "

  /* The smell message to display when we can't see the rat */
  hereWithoutSource = "You smell a RAT. "

  /* The smell message to display when we can see the rat */
  hereWithSource = "The rat stinks of RODENT! "
;


#endif //EXTENDED_VERSION
