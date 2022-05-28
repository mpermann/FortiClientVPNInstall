#!/bin/bash

# Name: FortiClientVPNRemoveInstall.sh
# Date: 05-27-2022
# Author: Michael Permann
# Version: 1.0
# Purpose: Detects whether an existing version of FortiClient VPN is installed. If it is, the 
# settings are backed up, the uninstaller is executed with the prompting of the end user, the 
# new version is installed and the settings are moved back in to place.

CURRENT_USER=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
USER_ID=$(/usr/bin/id -u "$CURRENT_USER")
LOGO="/Library/Application Support/HeartlandAEA11/Images/HeartlandLogo@512px.png"
JAMF_HELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
JAMF_BINARY=$(which jamf)
TITLE="Uninstall Application"
DESCRIPTION="Another version of FortiClient VPN was detected and must be removed before proceeding. 

1. Click the \"Uninstall\" button on the FortiClient Uninstaller dialog. 
2. Enter your computer password and click the \"Install Helper\" button.
3. Click the \"Done\" button to close FortiClient Uninstaller.

Then click the \"OK\" button to dismiss this dialog."
BUTTON1="OK"
DEFAULT_BUTTON="1"
VPN_APP="/Applications/FortiClient.app/Contents/MacOS/FortiClient"
VPN_SETTINGS="/Library/Application Support/Fortinet/FortiClient/conf/vpn.plist"
POLICY_TRIGGER_NAME="FortiClient_VPN"
POLICY_TRIGGER_NAME_SETTINGS="FortiClient_Settings_443"

if [ -f "$VPN_APP" ]
then
    echo "FortiClient software present"
    echo "Backing up vpn.plist"
    /bin/cp -p "$VPN_SETTINGS" "/tmp/vpn.plist"
    echo "Launching FortiClientUninstaller.app"
    /bin/launchctl asuser "$USER_ID" /usr/bin/sudo -u "$CURRENT_USER" "/usr/bin/open" "/Applications/FortiClientUninstaller.app"
    /bin/launchctl asuser "$USER_ID" /usr/bin/sudo -u "$CURRENT_USER" "$JAMF_HELPER" -windowType utility -windowPosition lr -title "$TITLE" -description "$DESCRIPTION" -icon "$LOGO" -button1 "$BUTTON1" -defaultButton "$DEFAULT_BUTTON"
    "$JAMF_BINARY" policy -event "$POLICY_TRIGGER_NAME"
    /bin/cp -p "/tmp/vpn.plist" "$VPN_SETTINGS"
else
    echo "FortiClient software NOT present"
    echo "Installing FortiClient software"
    "$JAMF_BINARY" policy -event "$POLICY_TRIGGER_NAME"
    echo "Installing FortiClient settings"
    "$JAMF_BINARY" policy -event "$POLICY_TRIGGER_NAME_SETTINGS"
fi

exit 0