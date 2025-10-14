#!/usr/bin/env python3

import WallpaperServiceInfo as w
import WPath
import BPUtil
import subprocess

class MSG:
    REQUEST_INFO = 1
    PAUSE = 2
    PREVIOUS = 3
    NEXT = 4
    SET_ROOT = 5
    ACTIVITY_REPORT = 6
    SET_WALLPAPER = 7
    SET_INTERVAL = 8
    SERVICE_INFO = 9
    SET_THEME = 10
    CUSTOM_CONFIG = 11
    PREVIOUS_THEME = 12
    NEXT_THEME = 13
    TOGGLE_PAUSE = 14
    SET_MODE = 15
    SET_SAVER = 16
    SET_SAVERTIME = 17
    OPEN_SETTING_UI = 18

def getWordsArray(wordString):
    if wordString == None or wordString == "":
        return []
    else:
        return wordString.split('|')

# ger random path from bpwallpaper bash script
# wpath = AppUtil.getWallpaperFromBash(wpsi.getTheme().stringValue(), "1920x1080")
def getWallpaperFromBash(themeString, resolution):
    result = subprocess.run(['bpwallpaper', '-u', '-n', '-D', resolution, '-t', themeString], stdout=subprocess.PIPE)
    path = result.stdout.decode('utf-8').strip()
    wpath = WPath.WPath(path)
    wpath.exif = BPUtil.getExifDescription(path)
    return wpath

def isMyServiceRunning():
    wpsi = w.WallpaperServiceInfo()
    return wpsi.getWallpaperService().isStarted()
