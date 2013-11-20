#!python3

"""
Convert Skald logs to TADS-compatible command transcripts.
Will leave existing compatible transcripts alone, but will rename them.

Author: Zach Tomaszewski
Created: 18 Nov 2013
"""

import logging
import re
import sys


logging.basicConfig(level=logging.DEBUG, format='%(levelname)-7s: %(message)s')
logger = logging.getLogger(__name__)


def main():
    args = sys.argv
    if len(sys.argv) == 1:
        printUsage()
    else:
        processFiles(sys.argv[1:])
    

def printUsage():
    """
    Prints a usage message.
    """
    print("""
Converts .log files to .cmds files that can be used as game inputs.
Must give one or more .log files as command line arguments.
    """)
    

def processFiles(filenames):
    """
    Coverts files ending in .log to .cmds files.  Overwrites any
    existing .cmds.  Will warn and skip any files that does not
    end in .log.
    """
    for input in filenames:
        if input.endswith('.log'):
            # compute output name
            output = input[:-4] + '.cmds'
            
            # grab lines
            with open(input, 'r') as f:
                lines = f.readlines()
                                
            # determine type and process accordingly
            if input.endswith('.t3.log') and lines[0].startswith('<eventscript>'):
                logger.info("{} ({}) -> {}".format(input, 'TADS', output))
                # lines are good as is                
            
            elif input.endswith('-skald.t3.log'):
                logger.info("{} ({}) -> {}".format(input, 'SKALD', output))
                cmds = [line for line in lines if line.startswith("CMD: ")]
                lines = [re.sub(r'^CMD: ', '<line>', cmd) for cmd in cmds]
                lines[0:0] = ['<eventscript>\n']  # prepend
                
            else:
                logger.error("{} - Could not determine log type!".format(input))
                return  # ABORT
            
            # save results
            with open(output, 'w') as f:
                f.writelines(lines)
            
        else:
            logger.warning('Skipping ' + name + ' (does not end in .log)')
            

if __name__ == "__main__":
    main()
    
