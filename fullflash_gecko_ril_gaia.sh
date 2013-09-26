#!/bin/bash

while getopts :rnh opt; do
  case $opt in
    r)
    echo "Turning on RIL Debugging"
    rildebug=1
    ;;
    n)
    echo "Not installing Commercial Ril, should be using mozril"
    nocomril=1
    ;;
    h) 
    echo "
    -r : to turn on ril debugging
    -n : to not install comril
    -h : for help
    "
    exit
    ;;
    d)
    echo "deleting previous Profile"
    deldata=1
    *)
    rildebug=0
    nocomril=0
    deldata=0
    ;;
  esac
done

echo + gaining root access &&
adb root &&

echo + Waiting for adb to come back up &&
adb wait-for-device &&

echo + remounting the system partition &&
adb remount &&
adb shell mount -o remount,rw /system &&

echo + Waiting for adb to come back up &&
adb wait-for-device &&

echo + Stopping b2g &&
adb shell stop b2g &&

echo + Check how much space is taken &&
adb shell df /system &&

echo + removing old system &&
adb shell rm -r /system/b2g &&

echo + Check how much is removed afterwards &&
adb shell df /system &&

if [ $deldata]
then
echo + Deleting Profile data &&
adb shell rm -r /data/b2g/mozilla
adb shell rm -r data/local/storage/persistent/*
fi

echo + Installing new b2g &&
adb push b2g /system/b2g &&

echo + Done installing Gecko!

if [ ! $nocomril ]
then
echo + Installing new RIL &&
adb push ril /system/b2g/distribution/bundles/
echo + Done installing RIL!
fi

echo + Adjusting user.js &&
if [ $rildebug ]
then
  cat gaia/profile/user.js | sed -e "s/user_pref/pref/" > gaia/user.js 
  cat gaia/user.js | sed -e "s/ril.debugging.enabled\", false/ril.debugging.enabled\", true/" > user.js 
else
  cat gaia/profile/user.js | sed -e "s/user_pref/pref/" > user.js 
fi

echo + Deleting any old gaia and profiles &&
adb shell rm -r /cache/* &&
adb shell rm -r /data/b2g/* &&
adb shell rm -r /data/local/webapps &&
adb shell rm -r /data/local/user.js &&
adb shell rm -r /data/local/permissions.sqlite* &&
adb shell rm -r /data/local/OfflineCache &&
adb shell rm -r /data/local/indexedDB &&
adb shell rm -r /data/local/debug_info_trigger &&

echo + Installing new gaia webapps &&
adb shell mkdir -p /system/b2g/defaults/pref &&
if adb shell cat /data/local/webapps/webapps.json | grep -qs '"basePath": "/system' ; then
	adb push gaia/profile/webapps /system/b2g/webapps
else
	adb push gaia/profile/webapps /data/local/webapps
fi
adb push user.js /system/b2g/defaults/pref &&
adb push gaia/profile/settings.json /system/b2g/defaults &&

echo + Rebooting &&
adb shell sync &&
adb shell reboot &&

echo + Done


