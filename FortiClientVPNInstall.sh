#!/bin/bash

# Name: FortiClientVPNRemoveInstall.sh
# Version: 1.0.3
# Created: 05-27-2022 by Michael Permann
# Modified: 07-13-2024
# Purpose: Detects whether an existing version of FortiClient VPN is installed. If it is, the 
# settings are backed up, the uninstaller is executed with the prompting of the end user, the 
# new version is installed and the settings are moved back in to place.

CURRENT_USER=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
USER_ID=$(/usr/bin/id -u "$CURRENT_USER")
LOGO="/Library/Management/PCC/Images/PCC1Logo@512px.png"
JAMF_HELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
JAMF_BINARY=$(which jamf)
TITLE="Notification"
DESCRIPTION="Please ignore the two pop-up messages regarding \"FortiTray\" and \"System Extensions Blocked\". 

Click the \"OK\" button to dismiss this dialog."
BUTTON1="OK"
DEFAULT_BUTTON="1"
TITLE1="Restart Needed"
DESCRIPTION1="Your computer needs restarted to complete the installation.

Click the \"OK\" button to restart your computer. Your computer will restart automatically after 1 minute."
VPN_APP="/Applications/FortiClient.app/Contents/MacOS/FortiClient"
VPN_REMOVAL_APP="/Applications/FortiClientUninstaller.app/Contents/Library/LaunchServices/com.fortinet.forticlient.uninstall_helper"
VPN_SETTINGS="/Library/Application Support/Fortinet/FortiClient/conf/vpn.plist"
POLICY_TRIGGER_NAME="$4"
POLICY_TRIGGER_NAME_SETTINGS="$5"

if [ -f "$VPN_REMOVAL_APP" ]
then
    echo "FortiClient software present"
    echo "Backing up vpn.plist"
    /bin/cp -p "$VPN_SETTINGS" "/tmp/vpn.plist"
    echo "Running com.fortinet.forticlient.uninstall_helper removal app to remove software"  # Credit to seb.fisher on MacAdmins Slack #fortinet channel for finding this removal option
    /Applications/FortiClientUninstaller.app/Contents/Library/LaunchServices/com.fortinet.forticlient.uninstall_helper
    echo "Updating inventory"
    "$JAMF_BINARY" recon
    echo "Notify user about pop-up messages"
    /bin/launchctl asuser "$USER_ID" /usr/bin/sudo -u "$CURRENT_USER" "$JAMF_HELPER" -windowType utility -windowPosition lr -title "$TITLE" -description "$DESCRIPTION" -icon "$LOGO" -button1 "$BUTTON1" -defaultButton "$DEFAULT_BUTTON" &
    echo "Installing FortiClient VPN software"
    "$JAMF_BINARY" policy -event "$POLICY_TRIGGER_NAME"
    echo "Updating inventory"
    "$JAMF_BINARY" recon
    echo "Moving settings back"
    /bin/cp -p "/tmp/vpn.plist" "$VPN_SETTINGS"
    /bin/launchctl asuser "$USER_ID" /usr/bin/sudo -u "$CURRENT_USER" "$JAMF_HELPER" -windowType utility -windowPosition lr -title "$TITLE1" -description "$DESCRIPTION1" -icon "$LOGO" -button1 "$BUTTON1" -defaultButton "$DEFAULT_BUTTON"
    /sbin/shutdown -r +1 &
else
    echo "FortiClient software NOT present"
    echo "Notify user about pop-up messages"
    /bin/launchctl asuser "$USER_ID" /usr/bin/sudo -u "$CURRENT_USER" "$JAMF_HELPER" -windowType utility -windowPosition lr -title "$TITLE" -description "$DESCRIPTION" -icon "$LOGO" -button1 "$BUTTON1" -defaultButton "$DEFAULT_BUTTON" &
    echo "Installing FortiClient software"
    "$JAMF_BINARY" policy -event "$POLICY_TRIGGER_NAME"
    echo "Updating inventory"
    "$JAMF_BINARY" recon
    echo "Installing FortiClient settings"
    "$JAMF_BINARY" policy -event "$POLICY_TRIGGER_NAME_SETTINGS"
    echo "Updating inventory"
    "$JAMF_BINARY" recon
    /bin/launchctl asuser "$USER_ID" /usr/bin/sudo -u "$CURRENT_USER" "$JAMF_HELPER" -windowType utility -windowPosition lr -title "$TITLE1" -description "$DESCRIPTION1" -icon "$LOGO" -button1 "$BUTTON1" -defaultButton "$DEFAULT_BUTTON"
    /sbin/shutdown -r +1 &
fi

exit 0