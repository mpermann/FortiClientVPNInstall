#!/bin/bash

# Name: FortiClientVPNRemoveInstall.sh
# Date: 05-27-2022
# Author: Michael Permann
# Version: 1.0.1
# Purpose: Detects whether an existing version of FortiClient VPN is installed. If it is, the 
# settings are backed up, the uninstaller is executed with the prompting of the end user, the 
# new version is installed and the settings are moved back in to place.
# Modified: 05-29-2022

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
TITLE1="Restart Needed"
DESCRIPTION1="Your computer needs restarted to complete the installation.

Click the \"OK\" button to restart your computer. Your computer will restart automatically after 1 minute."
VPN_APP="/Applications/FortiClient.app/Contents/MacOS/FortiClient"
VPN_SETTINGS="/Library/Application Support/Fortinet/FortiClient/conf/vpn.plist"
POLICY_TRIGGER_NAME="$4"
POLICY_TRIGGER_NAME_SETTINGS="$5"

if [ -f "$VPN_APP" ]
then
    echo "FortiClient software present"
    echo "Backing up vpn.plist"
    /bin/cp -p "$VPN_SETTINGS" "/tmp/vpn.plist"
    echo "Launching FortiClientUninstaller.app"
    /bin/launchctl asuser "$USER_ID" /usr/bin/sudo -u "$CURRENT_USER" "/usr/bin/open" "/Applications/FortiClientUninstaller.app"
    /bin/launchctl asuser "$USER_ID" /usr/bin/sudo -u "$CURRENT_USER" "$JAMF_HELPER" -windowType utility -windowPosition lr -title "$TITLE" -description "$DESCRIPTION" -icon "$LOGO" -button1 "$BUTTON1" -defaultButton "$DEFAULT_BUTTON"
    echo "Updating inventory"
    "$JAMF_BINARY" recon
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