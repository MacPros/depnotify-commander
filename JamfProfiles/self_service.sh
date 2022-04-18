#!/bin/zsh

CURRENT_USER=$(/usr/bin/stat -f "%Su" /dev/console)
CURRENT_USER_ID=$(id -u $CURRENT_USER)
launchctl asuser $CURRENT_USER_ID open -a "/Applications/Utilities/DEPNotify.app"
/usr/local/bin/depnotify-commander

