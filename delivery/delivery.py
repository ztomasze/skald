#!/usr/bin/python3

## delivery.py
## 
## Serves up the TADS servers to run UI evaluation.  
## Also generates a user, records game transcripts sent home, 
## and keeps track of that sort of thing.
## 
## Basic process:
## no user - generate a new user (logged as "start")
##             and assign to experimental group
##             and direct to background survey
## (user, no stage) - error
## user, stage 1 - Serve first game for given exp group
## user, stage 2 - Serve second game
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
import time

from config import *

# group 0: game 0, then 1  (port 1,4)
# group 1: game 2, then 3. (port 2,3)
# ports are different: +1 or 2 for fate, +3 or 4 for queen, odd for webui, even for Skald
#
GAMES = ['fate-webui.t3', 'queen-skald.t3', 'fate-skald.t3', 'queen-webui.t3']


def main():
    runStudy()
      

def runStudy():
    """
    Runs in research study mode where each user is assigned an ID and routed
    through surveys.
    """
    form = cgi.FieldStorage()
    
    #get user ID
    user = form.getfirst('c', None) or form.getfirst('user', None)
    if not user:
      user = generateUser()
      logTime(user, "Start")
      group = assignToGroup()
      logTime(user, "Grp=" + str(group))
      welcomePage(user, group)
      return

    elif not re.compile(r"\d{1,5}$").match(user) or int(user) < MIN_USER_PORT or \
            int(user) % 5 != 0:
        #bad user
        returnStatus(400, "Bad username format")
        return

    assert user  # have a valid user given from here one
        
    game = form.getfirst('game', None)  # direct game request
    stage = form.getfirst('s', 0) or form.getfirst('stage', 0)
    if stage:
        if stage in ['1', '2']:
            #a valid stage to be in
            stage = int(stage)
        elif not game:
            returnStatus(400, "Given stage argument (" + str(stage) + ") is not supported.")
            return

    if user.endswith('5') and not game:
        # free play
        serveGames(user)
        return

    if game and not stage:  # direct game request
        logTime(user, "Game=" + game)
        serveGame(game, user)
        return 

    if stage and not game:
        logTime(user, stage)
        game = getGame(user, stage)
        serveGame(game, user, stage)
        return
        
    returnStatus(400, "Illegal parameter state; could not continue.")
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

    
def generateUser():
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

    counter = MIN_USER_PORT + (counter * 10)
    return '%05i' % counter


def getGame(user, stage):
  """
  Returns the game the given user should be playing based on group 
  and current stage.
  
  Returns None if no Grp= assigned yet or if stage is not 1 or 2.
  """
  grp = getGroup(user)
  return GAMES[(2 * grp) + (int(stage) - 1)]


def getGroup(user):
  """
  Opens the times file for the given user and finds the first timestamp for
  "Grp=#:", where # is the number of the grp.  Returns this number, else 
  exception.
  """ 
  userTimes = open(os.path.join(DATA_DIR, user + TIMES_FILE), 'r')
  for line in userTimes:
    grp = re.compile("Grp=(\d):").match(line)
    if grp:
      return int(grp.group(1))
     
  raise KeyError('Could not find group for ' + user)
  
  
def logTime(user, stage=0):
  """
  Dumps the current time into the given user's TIMES_FILE.
  """
  userTimes = open(os.path.join(DATA_DIR, user + TIMES_FILE), 'a')
  userTimes.write(str(stage))
  userTimes.write(": ")
  userTimes.write(time.ctime())  #human-readable
  userTimes.write(" = ")
  userTimes.write(str(int(time.time()))) #seconds since epoch
  userTimes.write('\n')
  userTimes.close()
   

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
<style type="text/css">
body {
  font-family: sans-serif;
}
a {
  text-decoration: none;
}
a:hover {
  text-decoration: underline;
}
.launcher {
  width: 50%;
  background-color: #f0f0f0;
  font-weight; bold;
  border: 1px solid black;
  text-align: center;
  padding: 2em;
}
</style>
</head>""" + body + """</html>""")


#TODO: refactor to use printHtmlPage
def returnStatus(status, detail):
  """
  Returns the given status code, with short webpage, to the sender.
  """
  print("Content-Type: text/html")
  print("Status: " + str(status))
  print()
  #print HTML
  body = "<body>"
  if status == 200:
    body += "<h3>200: OK</h3>"
  elif status == 400:
    body += "<h3>400: Bad Request</h3>"
    body += "<p>The request you sent did not contain the required format/content: "
  elif status == 500:
    body += "<h3>500: Oops!</h3>"
    body += "<p>There was a script error on my end: "

  body += detail
  body += "</p></body>"
  printHtmlPage(str(status), body, status)


def serveGame(game, user, stage=0):
    """
    Starts the given game file on a port derived from the given int(user).
    That is, user should be a string that converts to an int.  Will then
    add 1 to 4 to that base port number depending on the game requested:
    fate-webui: +1, fate-skald: +2, queen-webui: +3, queen-skald: +4
    
    If a non-zero stage, will provide a landing page with the corresponding
    linke to click when done.
    
    """
    if not game in GAMES:
        returnStatus(400, "Unsupported game requested.")
        return
        
    if stage:
        serveGamePage(game, user, stage)
        return

    port = int(user) + 1
    if game.startswith('queen'):
        port += 2
    webui = game.endswith('-webui.t3')
    if webui:
        tads_opts = ''   # --webhost ' + FILES_URL_SERVER
    else:
        port += 1
        tads_opts = ''
        url = "http://{}:{}{}".format(FILES_URL_SERVER, port, FILES_URL_DIR)
            
    # XXX: game must be in the current directory for a log file to be generated
    # by frobs/tads.  So must use only game name and set cwd to work.
    cmd = ' '.join([TADS, tads_opts, game, str(port)])

    # save output to file
    outputfile = "{}-{}.output".format(port, game)
    outputfile = os.path.join(DATA_DIR, outputfile)

    # spawn separate process, but only if hasn't been started yet
    if not os.path.exists(outputfile):
        subprocess.Popen(cmd, shell=True, close_fds=True,
                        cwd=DATA_DIR,
                        stdin=DEVNULL,
                        stdout=open(outputfile, 'w'),
                        stderr=open(outputfile + '.err', 'w'))
    #print(cmd)
    time.sleep(1)  # give it a second to start

    if webui:
        try:
            with open(outputfile, 'r') as f:
                for i in range(1): f.readline()  # skip over
                url = f.readline()
                #print(url)
                url = url[len('connectWebUI:'):] # remove prefix
                if not url.startswith('http:'):
                    returnStatus(500, 'Could not start game')
                    return
        except IOError:
            returnStatus(500, 'Could not start game--no link file generated')
            return
    
    print("Content-Type: text/html")
    print("Status: 307")
    print("Location: " + url)
    print()


def serveGamePage(game, user, stage):
    """
    Creates a landing page with a link to start a game in a new window
    and another link to continue with survey steps.
    """
    g = "Captain Fate" if game.startswith('fate') else "The Queen's Heart"
    i = "Skald UI" if game.endswith('-skald.t3') else "Text UI"
    s = "Game " + str(stage) + " of 2"
    title = "{}: {} ({})".format(s, g, i)
    h1 = "{}: {} <small>({})</small>".format(s, g, i)
    gurl = "/cgi-bin/delivery.py?user={user}&game={game}".format(user=user, game=game)
    surl = RESPONSE_SURVEY_URL + "?user={}&stage={}".format(user, stage)
    body = """
<body>
<h1>""" + h1 + """</h1>
<p>
Click the link in the box below to launch the game in a new window:
<p class="launcher">
<a href="{gurl}" target="_blank">{g}</a>
</p>
<p>
Please play only once.  
Your game session will end if 10 minutes pass without any input from you.
<p>
Once you have played the game, 
<a href="{surl}">click here to continue with the study</a>.
</body>
""".format(gurl=gurl, g=g, surl=surl)
    printHtmlPage(title, body)
    return


def serveGames(user=MIN_USER_PORT):
    """
    Only serves up the four games with no user tracking.
    If no user given, uses MIN_USER_PORT, which is cause conflict for more than
    one concurrent user.  
    """
    user = int(user)
        
    body = """
<body>
<h3>Available games:</h3>
<ul>
<li>Captain Fate: 
  <a href="?user={0}&game=fate-webui.t3">text UI</a> / 
  <a href="?user={0}&game=fate-skald.t3">Skald UI</a>
<li>Queen's Heart: 
  <a href="?user={0}&game=queen-webui.t3">text UI</a> / 
  <a href="?user={0}&game=queen-skald.t3">Skald UI</a>
</body>""".format(user)  #, GAMES
    printHtmlPage("Available Games", body) 


def welcomePage(user, group):
    """
    Alpha testing splash page
    """
    body = """
<body>
<h3>Welcome</h3>
<p>
Thank you for participating!
<p>
Please <a href='""" + BACKGROUND_SURVEY_URL + '?user=' + str(user) + '&group=' + str(group) + \
"""'><b>click here to begin</b></a>.
</p>
</body>
    """
    printHtmlPage('Welcome!', body)
  
  
if __name__ == "__main__":
  main()
