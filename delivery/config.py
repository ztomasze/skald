# Local configuration for delivery.py

import os.path
import subprocess

# System directory from where all the game files are being served from.
# Absolute or relative from cgi-bin.
FILES_DIR = '/zacht/httpd/htdocs/'

# Fully-qualified domain name of server from which game files are being served
# No slash at end (so can append port if needed)
FILES_URL_SERVER = 'localhost'

# Directory path part of URL pointing to files location.
FILES_URL_DIR = '/'


# The directory to store saved files and logs into.  Path given should
# be either relative to this script or absolute from drive root. 
DATA_DIR = '/zacht/httpd/skaldData'

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
TADS = '/usr/local/bin/frob --interface plain -N00 --no-pause --webhost ' + FILES_URL_SERVER

# Where to read/write to the void
DEVNULL = subprocess.DEVNULL

# Lowest port usable by users.  Should be divisible by 10 and must be >= 10000.
MIN_USER_PORT = 30000
