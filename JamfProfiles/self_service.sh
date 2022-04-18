#!/bin/zsh

DEP_NOTIFY_LOG="/var/tmp/depnotify.log"
CURRENT_USER=$(/usr/bin/stat -f "%Su" /dev/console)
CURRENT_USER_ID=$(id -u $CURRENT_USER)
launchctl asuser $CURRENT_USER_ID open -a "/Applications/Utilities/DEPNotify.app" --args -path "$DEP_NOTIFY_LOG"
/usr/local/bin/depnotify_commander
