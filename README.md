#  depnotify-commander

A utility to fully configure DEPNotify using a configuration profile. 

It is intended to work well as a Jamf Pro pre-stage package alongside the Jamf Connect packages. It solves the catch-22 
of deploying a DEPNotify script before Jamf is ready to run policies. This allows us to avoid the infamous 
"Reticulating splines…" issue when DEPNotify starts through Jamf Connect, but Jamf Pro isn't ready to start
accepting commands from the login script. It also resolves the deployment issues around the login script. Normally the login
script needs to be wrapped in a code signed installer package and deployed during pre-stage enrollment in order to 
guarantee the script is installed early enough.

Note: This utility is not yet tested for DEPNotify deployments using automated enrollment without Jamf Connect.

## Planned Features

* Optionally support a JSON Schema for DEPNotify steps.
* Create folders for images outside of /var/tmp
* Add caffeinate option
* Add option to launch DEPNotify standalone app. (`CURRENT_USER=$(/usr/bin/stat -f "%Su" /dev/console) ;
  CURRENT_USER_ID=$(id -u $CURRENT_USER) ; launchctl asuser $CURRENT_USER_ID open -a "/Applications/Utilities/DEPNotify.app"`)
* Option to run authchanger command on completion
* Option to pull the SSO user name in to a variable.
* Option to set JAMF user with SSO user name.
