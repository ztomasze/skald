#!/usr/bin/python3

## delivery.py
## 
## Serves up the TADS servers to run UI evaluation.  
## Also generates a userID, records game transcripts sent home, 
## and keeps track of that sort of thing.
## 
## Basic process:
## no userID - generate a new userID (logged as "start")
##             and assign to experimental group
##             and direct to background survey
## (userID, no stage) - error
## userID, stage 1 - Serve first game for given exp group
## userID, stage 2 - Serve second game
## 
## Author: Zach Tomaszewski
## Created: 06 Dec 2010 (as demeter.py)
## Version: 17 Jun 2013
##

import os.path
import re
import cgi
import os
import subprocess
import time
import random

# Where all the game files are being served from
FILES_DIR = '../htdocs/skald'

# Fully-qualified domain name of server from which game files are being served
# No slash at end (so can append port if needed)
FILES_URL_SERVER = 'http://demo.zach.tomaszewski.name'

# Directory path part of URL pointing to files location.
FILES_URL_DIR = '/'


# The directory to store saved files and logs into.  Path given should
# be either relative to this script or absolute from drive root. 
DATA_DIR = os.path.normpath('../skaldData')

# Name of the counter file that is source of userIDs
COUNTER_FILE = os.path.join(DATA_DIR, 'counter.txt')
# Name of the counter file that is source of which experimental group 
# the next user gets assigned to.
EXP_GROUP = os.path.join(DATA_DIR, 'expgroup.txt')

# Name of the file to store timestamps in within each user's directory.
# UserID will be prepended to this
TIMES_FILE = 'times.txt'

# Should begin with http://...
BACKGROUND_SURVEY_URL = 'http://www.surveygizmo.com/s3/439469/Demeter-Evaluation-Consent-Background'
RESPONSE_SURVEY_URL = 'http://www.surveygizmo.com/s3/439486/Demeter-Evaluation-Player-Response'

# Location of TADS interpreter capable of acting as a server
# May include any TADS options, after which the game file will be appended.
TADS = '/usr/local/bin/frob -i plain -N 0'

FATE = 'fate.t3'
QUEEN = 'queen.t3'

# Games: [experimental group][stage]
GAMES = [[FATE + ' web',   QUEEN + ' skald'],
         [FATE + ' skald', QUEEN + ' web']]


def main():
#    runStudy()
#    serveGames()
    serveGame(FATE, 'skald', generateUserID())
  

def serveGames():
    """
    Only serves up the two games with no user tracking.
    """
    body = """
<body>
<h3>Available games:</h3>
<ul>
<li>Captain Fate: 
  text UI / Skald UI
<li>Queen's Heart: 
  text UI / Skald UI  
</body>"""
    printHtmlPage("Available Games", body)


def serveGame(game, mode, port):
    """
    Starts the given game file in the given mode ('web' or 'skald')
    on the given port.
    """
    cmd = ' '.join([TADS, os.path.join(DATA_DIR, game), mode, port])
    
    print("Content-Type: text/html")
    print("Status: 307")
    print("Location: {}:{}{}".format(FILES_URL_SERVER, port, FILES_URL_DIR))
    print()

    # save output to file
    outputfile = "{}-{}.{}.output".format(port, game, mode)
    outputfile = os.path.join(DATA_DIR, outputfile)

    # spawn separate process
    subprocess.Popen(cmd, shell=True, close_fds=True,
                    stdin=open('/dev/null'),
                    stdout=open(outputfile, 'w'),
                    stderr=subprocess.STDOUT)
    # print(cmd)
 
    

def runStudy():
  """
  Runs in research study mode where each user is assigned an ID and routed
  through surveys.
  """
  form = cgi.FieldStorage()
  
  #get user ID
  userID = form.getfirst('c', None) or form.getfirst('userID', None)
  if not userID:
    userID = generateUserID()
    logTime(userID, "Start")
    group = assignToGroup()
    logTime(userID, "Grp=" + str(group))
    welcomePage(userID, group)    
    return
  elif not re.compile(r"\d\d\d$").match(userID):
    #bad userID
    returnStatus(400, "Bad username format")
    return

  #get any passed stage of survey so far (if not uploading)
  if not filename:
    stage = form.getfirst('s', 0) or form.getfirst('stage', 0)
    if stage and stage == '1' or stage == '2':
      #a valid stage to be in
      stage = int(stage)
    else:
      returnStatus(400, "Given stage argument (" + str(stage) + ") is not supported.")
      return

  #now, do what we came to do...
  #first, log what we're doing
  logTime(userID, stage)
  
  #serve the correct game for this user
  game = getGame(userID, stage)
  if game:
    generateJNLP(userID, game)
    serveApplet(userID, game, stage)
  else:
    returnStatus(400, "Something wrong: No such game to play.<br>\
      Check that you are really a valid user and that you submitted which stage you are on.")
    return


def assignToGroup():
    """
    Opens EXP_GROUP, gets the number there, then flips the number (b/w 0 and 1)
    and stores it for the next value.  EXP_GROUP should contain an integer 
    and nothing else.  Throws an IOError if could not open the file, or
    there is currently a lock on it.

    Returns the group just assigned.
    """
    #see if file is already locked; if so, see if it is unlocked soon
    waiting = 1.0  #second
    while waiting > 0 and os.path.exists(EXP_GROUP + '.lock'):
        time.sleep(0.2)
        waiting -= 0.2

    if os.path.exists(EXP_GROUP + '.lock'):
        raise IOError("Lock file still in place.")

    lockFile = open(EXP_GROUP + '.lock', 'w')  

    #read in current value
    counterFile = open(EXP_GROUP, "r")
    counter = int(counterFile.readline())
    counterFile.close()

    #flip
    if counter == 0:
        nextCounter = 1
    else:
        nextCounter = 0  

    #save new
    counterFile = open(EXP_GROUP, "w")
    counterFile.write(str(nextCounter))
    counterFile.close()  

    lockFile.close()
    os.remove(lockFile.name)

    return counter


def generateJNLP(userID, game):
  """
  Copies the original demeter.jnlp, appending the userID and -stage to 
  filename (before extension) and updating the userID contained within the 
  file itself.
  """
  #get original contents
  jnlp = open(os.path.join(DEMETER_DIR, 'demeter.jnlp'), 'r')
  contents = jnlp.read()
  jnlp.close()

  #replace userID 
  found = re.compile(USER_ID_PRE + '(\d\d\d)').search(contents)
  contents = contents.replace(found.group(0), USER_ID_PRE + userID)
  #point to game version
  found = re.compile(GAME_ID_PRE).search(contents)
  contents = contents.replace(found.group(0), GAME_ID_PRE + str(game))
  
  # prints out a separate jnlp file in case we get another request from a 
  # different user before the first (on a slow connection, perhaps) actually
  # reads the jnlp file
  userJnlp = open(os.path.join(DEMETER_DIR, 'demeter' + userID + '-' + str(game) + '.jnlp'), 'w')
  userJnlp.write(contents)
  jnlp.close()


    
def generateUserID():
    """
    Opens COUNTER_FILE, increments the number there, and returns the new
    value as a 3-digit string.  COUNTER_FILE should contain an integer 
    and nothing else.  Throws an IOError if could not open the file, or
    there is currently a lock on it.
    """
    #see if file is already locked; if so, see if it is unlocked soo
    waiting = 1.0  #second
    while waiting > 0 and os.path.exists(COUNTER_FILE + '.lock'):
          time.sleep(0.2)
          waiting -= 0.2

    if os.path.exists(COUNTER_FILE + '.lock'):
          raise IOError("Lock file still in place.")

    lockFile = open(COUNTER_FILE + '.lock', 'w')  

    #read in current value
    counterFile = open(COUNTER_FILE, "r")
    counter = int(counterFile.readline())
    counterFile.close()

    #inc
    counter += 1

    #save new
    counterFile = open(COUNTER_FILE, "w")
    counterFile.write(str(counter))
    counterFile.close()  

    lockFile.close()
    os.remove(lockFile.name)

    return '49%03i' % counter  #49... 3 digit integer


def getGame(userID, stage):
  """
  Opens the times file for the given userID and finds the first timestamp for
  "Grp=#:", where # is the number of the grp.  Then uses this number, stage,
  and VERSION_BASE to return the number of the game this user should currently
  be playing.
  
  Returns 0 if no Grp= assigned yet or if stage is not 1 or 2.
  """
  userTimes = open(os.path.join(DATA_DIR, userID + TIMES_FILE), 'r')
  for line in userTimes:
    grp = re.compile("Grp=(\d):").match(line)
    if grp:
      grp = int(grp.group(1))
      if stage == 1:
        return VERSION_BASE + grp
      elif stage == 2:
        return VERSION_BASE + 2 + grp
  return 0
  
  
def logTime(userID, stage=0):
  """
  Dumps the current time into the given user's TIMES_FILE.
  """
  userTimes = open(os.path.join(DATA_DIR, userID + TIMES_FILE), 'a')
  userTimes.write(str(stage))
  userTimes.write(": ")
  userTimes.write(time.ctime())  #human-readable
  userTimes.write(" = ")
  userTimes.write(str(int(time.time()))) #seconds since epoch
  userTimes.write('\n')
  userTimes.close()

  
  
  
  
def serveApplet(userID, game, stage):
  """
  Generates an HTML page that launches the demeter.jnlp
  """
  jnlpFile = DEMETER_HREF + 'demeter' + userID + '-' + str(game) + ".jnlp"
  
  print("Content-Type: text/html")
  print()
  #print HTML
  print("""
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" >
<title>Demeter (Zag Edition)</title>
</head>

<body style="font-family: sans-serif;  margin: 1em;
  """)
  if stage == 1:
    print('background-color: #fffbda;"')
  elif stage == 2:
    print('background-color: #dae0e0;"')
  
  print(""">
    <table>
    <tr><td width="450" style="border: 1px solid black;">
    <applet code='org.p2c2e.zag.AppletMain'
      archive='""" + DEMETER_HREF + """demeter.jar'
      jnlp_href='""" + jnlpFile + """'
      width="450" height="300">
      Your browswer either does not have Java installed or does not support the APPLET tag.
      You can visit <a href="http://www.java.com/">java.com</a> to get the current Java plugin.
      <param name="gameFile" value='../demeter/Demeter""" + str(game) + """.ulx' />
      <param name="saveToFilePath" value="../cgi-bin/demeter.py" />
      <param name="userID" value='""" + str(userID) + """' />  
    </applet>
    
    <td style="padding: 1em;">
    <h2>Game session """ + str(stage) + """ of 2</h2>    
    """)
  if stage == 1:
    print("""
    <p>
    The <i>Demeter</i> game should open in another window, beginning with 
    a request from Java to allow it to run.
    <p>
    Your game input is being anonymously recorded.  Since this is your
    first time playing, the game will start with a short
    tutorial to get your oriented.
    <p>
    Play one time through the tutorial and the game that follows.
    """)
  elif stage == 2:
    print("""
    <p>
    Welcome back!  This version of <i>Demeter</i> has slightly different
    settings than the first version you played.  As before, the game
    will open in a new window. Your game input is still being
    anonymously recorded.  Since this is your second time, we'll skip
    the tutorial.
    """)
  print('<p><br><b>Once you finish the game, <a href="' + RESPONSE_SURVEY_URL + \
    "?userID=" + str(userID) + "&s=" + str(stage) + '">click here to continue with the study.</a></b>')
  print("""    
    <p><br>
    If you encounter a technical problem with the game and need to 
    restart this session, you can:</b>
    <ul>
    <li>Hit refresh in your browser to reload this page.
    <li>If that doesn't work, try to <a href='""" + jnlpFile + """'>open the game
    with Java Web Start</a>.
    <li>See the FAQs below for more specific help.
    </ul>
    </tr></table>
    <br>
    
    <div style="float: right; border: 1px dotted black; padding: 1em; margin-right: 2em;">
    You are here:<br>    
    <strike><i>1. Background Survey</i></strike><br>
  """)
  if stage == 1:
    print("""
    <b>2. Game Session 1 of 2</b><br>
    <i>3. Response Survey</i><br>    
    <i>4. Game Session 2 of 2</i><br>
    <i>5. Response Survey</i><br>
    """)
  elif stage == 2:
    print("""
    <strike><i>2. Game Session 1 of 2</i></strike><br>
    <strike><i>3. Response Survey</i></strike><br>    
    <b>4. Game Session 2 of 2</b><br>
    <i>5. Response Survey</i><br>
    """)
  print("""  
    </div>
    
    <h4>FAQs</h4>
    <ul>
    <li><a href="http://www2.hawaii.edu/~ztomasze/argax/games/demeter/faqs.html#warning" 
    target="_blank">Why do I get a warning from Java when the applet first loads?</a>
    <li><a href="http://www2.hawaii.edu/~ztomasze/argax/games/demeter/faqs.html#signature" 
    target="_blank">Why does this application need a signature in the first place?</a>
    <li><a href="http://www2.hawaii.edu/~ztomasze/argax/games/demeter/faqs.html#no_start" 
    target="_blank">I do not get any pop-up window at all.</a>
    <li><a href="http://www2.hawaii.edu/~ztomasze/argax/games/demeter/faqs.html#cancel"
    target="_blank">I hit Cancel in the initial pop-up window from Java and now the game won't start.</a>
    </ul>
</body>
</html>
""")  

  
def returnStatus(status, detail):
  """
  Returns the given status code, with short webpage, to the sender.
  """
  print("Content-Type: text/html")
  print("Status: " + str(status))
  print()
  #print HTML
  print("""
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" >
<title>""" + str(status) + """</title>
</head>

<body>
  """)
  if status == 200:
    print("<h3>200: OK</h3>")
  elif status == 400:
    print("<h3>400: Bad Request</h3>")
    print("<p>The request you sent did not contain the required format/content: ")
  elif status == 500:
    print("<h3>500: Oops!</h3>")
    print("<p>There was a script error on my end: ")

  print(detail)
  print("</p>")
  print("""
</body>
</html> 
  """)  
  

def welcomePage(userID, group):
  """
  Alpha testing splash page
  """
  body = """
<body>
<h3>Welcome</h3>
<p>
Thanks for being an beta tester!  You are currently anonymous user """ + str(userID) + """.
<p>
Please <a href='""" + BACKGROUND_SURVEY_URL + '?userID=' + str(userID) + '&group=' + str(group) + \
"""'><b>click here to begin</b></a>.
</p>
</body>
  """
  printHtmlPage('Welcome!', body)

def printHtmlPage(title, body, status=None):
  """
  Prints the content-type header (with optional Status line), then the HTML 
  document.  Uses a standard head containing the given title.  Then includes
  the given body text, which must start and end with <body></body>.
  """
  print("Content-Type: text/html")
  if status:
    print("Status: " + str(status))
    
  print()
  #print HTML
  print("""<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" >
<title>""" + title + """</title>
</head>""" + body + """</html>""")
  

  
  
if __name__ == "__main__":
  main()
