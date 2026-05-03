#!/bin/sh

echo "[*] Starting device-side operations..."

rm -rf /var/mobile/Media/1
mv -f /var/mobile/Media/Downloads/1 /var/mobile/Media

chown -R mobile:mobile /var/mobile/Media/1

chmod -R 755 /var/mobile/Media/1
chmod 644 /var/mobile/Media/1/Activation/*.plist

killall backboardd
sleep 12

mv -f /var/mobile/Media/1/Activation/FairPlay /var/mobile/Library/FairPlay
chmod 755 /var/mobile/Library/FairPlay

ACT1=$(find /var/containers/Data/System -name internal)
ACT2=${ACT1%?????????????????}

ACT3=$ACT2/Library/internal/data_ark.plist

chflags nouchg $ACT3 2>/dev/null
mv -f /var/mobile/Media/1/Activation/data_ark.plist $ACT3
chmod 755 $ACT3
chflags uchg $ACT3 2>/dev/null

ACT4=$ACT2/Library/activation_records
mkdir -p $ACT4

mv -f /var/mobile/Media/1/Activation/activation_record.plist \
$ACT4/activation_record.plist

chmod 755 $ACT4/activation_record.plist
chflags uchg $ACT4/activation_record.plist 2>/dev/null

chflags nouchg /var/wireless/Library/Preferences/com.apple.commcenter.device_specific_nobackup.plist 2>/dev/null

mv -f /var/mobile/Media/1/Activation/com.apple.commcenter.device_specific_nobackup.plist \
/var/wireless/Library/Preferences/com.apple.commcenter.device_specific_nobackup.plist

chown root:mobile /var/wireless/Library/Preferences/com.apple.commcenter.device_specific_nobackup.plist
chmod 755 /var/wireless/Library/Preferences/com.apple.commcenter.device_specific_nobackup.plist
chflags uchg /var/wireless/Library/Preferences/com.apple.commcenter.device_specific_nobackup.plist 2>/dev/null

launchctl unload /System/Library/LaunchDaemons/com.apple.mobileactivationd.plist 2>/dev/null
launchctl load /System/Library/LaunchDaemons/com.apple.mobileactivationd.plist 2>/dev/null

ldrestart

echo "[✓] Done. Device will reboot..."
reboot
