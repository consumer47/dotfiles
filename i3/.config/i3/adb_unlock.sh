#!/usr/bin/bash

adb shell input keyevent 26  # Power button (wakes the screen)
adb shell input text 1596  
adb shell input keyevent 66  # Press ENTER to confirm
