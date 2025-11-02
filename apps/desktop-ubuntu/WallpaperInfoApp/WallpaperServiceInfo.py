#!/usr/bin/env python3

import ThemeInfo as t
import PlatformPreference as pref
import WallpaperService

class Singleton(type):
    _instances = {}
    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super(Singleton, cls).__call__(*args, **kwargs)
        return cls._instances[cls]

class WallpaperServiceInfo(metaclass=Singleton):

    def __init__(self):
        pref.getPreference(self)
        # must update custom info before it updates themeinfo
        t.setCustomConfigDetail(self._customThemeInfo._root, self._customThemeInfo._allow,  self._customThemeInfo._filter)
        self._themeInfo  = t.getThemeInfo(self._theme)
        self._wallpaperService = WallpaperService.WallpaperService()
        self._currentWPath = None
        self._thumbnail = None

    # persistent property setter/getter 
    def getSourceRootPath(self):
        return self._sourceRootPath
    def setSourceRootPath(self, path):
        self._sourceRootPath = path
        pref.setPreference("root_path", path)

    def getTheme(self):
        return self._themeInfo._theme
    def getThemeInfo(self):
        return self._themeInfo
    def setThemeInfo(self, themeInfo):
        self._themeInfo = themeInfo
        pref.setPreference("theme", str(int(self._themeInfo._theme)))
    def setCustomThemeInfo(self, customThemeInfo):
        self._customThemeInfo = customThemeInfo
        pref.setPreference("custom_root", customThemeInfo._root)
        pref.setPreference("custom_allow", customThemeInfo._allow)
        pref.setPreference("custom_filter", customThemeInfo._filter)
    def getCustomConfigString(self):
        return self._customThemeInfo._root + ";" + self._customThemeInfo._allow + ";" + self._customThemeInfo._filter
        
    def getPause(self):
        return self._pause
    def setPause(self, pause):
        self._pause = pause
        pref.setPreference("pause", str(pause))

    def getInterval(self):
        return self._interval
    def setInterval(self, interval):
        self._interval = interval
        pref.setPreference("interval", str(interval))
    
    # runtime property setter/getter
    def getcurrentWPath(self):
        return self._currentWPath
    def setcurrentWPath(self, wpath):
        self._currentWPath = wpath

    def getThumbnail(self):
        return self._thumbnail
    def setThumbnail(self, thumbnail):
        if thumbnail != self._thumbnail and self._thumbnail != None:
            del self._thumbnail
        self._thumbnail = thumbnail

    def getLastUsedPaths(self):
        return self._lastUsedPaths
    def setLastUsedPaths(self, lastUsedPaths):
        self._lastUsedPaths = lastUsedPaths

    def getWallpaperService(self):
        return self._wallpaperService

    # public value from resource
    _defaultInterval = 7
    _minInterval = 5 
    _maxInterval = 30

#wpsi = WallpaperServiceInfo()
#print(wpsi.getTheme().label())
#wpsi3 = WallpaperServiceInfo()
#print(wpsi3.getTheme().label())
#wpsi.setThemeInfo(t.getThemeInfo(t.Theme.special1))
#print(wpsi.getTheme().label())
#wpsi2 = WallpaperServiceInfo()
#print(wpsi2.getTheme().label())
#print(wpsi3.getTheme().label())
#wpsi.setInterval(13)
