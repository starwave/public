#!/usr/bin/env python3

import PlatformTimer
import PlatformWallpaper
import WallpaperWidgetProvider
import WallpaperNotification
import WallpaperServiceHandler
import ImageFileManager
import WPath
import WallpaperServiceInfo as w
import ThemeInfo as t
import AppUtil as a
import BPUtil

import os
import sys

class WallpaperService:

    def __init__(self):
        self._started = False
        # only for python3 code
        # check if it's binary or .py
        if getattr(sys, 'frozen', False):
            curr_path = os.path.dirname(sys.executable)
        elif __file__:
            curr_path = os.path.dirname(os.path.abspath(__file__))
        self._icon = os.path.join(curr_path, 'thirdwave.xpm')
        self._app_id = "WallpaperInfoApp"
        self._wallpaperNotification = WallpaperNotification.WallpaperNotification(self._app_id, self._icon)
        self._wallpaperServiceHandler = WallpaperServiceHandler.WallpaperServiceHandler(self)
       
    def __del__(self):
        if self._started:
            self.onDestroy()

    def startService(self):
        self.onStartCommand()
    
    def stopService(self):
        self._imageFileManager.stopWatching() # to interrupt exif read
        self.onDestroy()

    def onDestroy(self):
        # stop timer when service is destroyed to prevent service is rerunning
        self._platformTimer.pause()
        # update widget for default view
        wpsi = w.WallpaperServiceInfo()
        wpsi.setcurrentWPath(None)
        wpsi.setThumbnail(None)
        if self._started:
            self._started = False
        self.broadcastServiceUpdate()

    def broadcastReceiver(self, action, extras = 0):
        if not self._started:
            return
        if action == a.MSG.SET_THEME:
            BPUtil.BPLog("WallpaperServicebroadcastReceiver - MSG.SET_THEME")
            self.updateServiceTheme(extras)
            self.broadcastServiceUpdate()
        elif action == a.MSG.PREVIOUS:
            BPUtil.BPLog("WallpaperServicebroadcastReceiver - MSG.PREVIOUS")
            self.restartTimer()
            self.naviageWallpaper(-1)
        elif action == a.MSG.NEXT:
            BPUtil.BPLog("WallpaperServicebroadcastReceiver - MSG.NEXT")
            self.restartTimer()
            self.naviageWallpaper(1)
        elif action == a.MSG.PREVIOUS_THEME:
            BPUtil.BPLog("WallpaperServicebroadcastReceiver - MSG.PREVIOUS_THEME")
            self.updateServiceThemeWithPrevious()
            self.broadcastServiceUpdate()
        elif action == a.MSG.NEXT_THEME:
            BPUtil.BPLog("WallpaperServicebroadcastReceiver - MSG.NEXT_THEME")
            self.updateServiceThemeWithNext()
            self.broadcastServiceUpdate()
        elif action == a.MSG.TOGGLE_PAUSE:
            BPUtil.BPLog("WallpaperServicebroadcastReceiver - MSG.TOGGLE_PAUSE")
            self.togglePause()
        else:
            BPUtil.BPLog("WallpaperServicebroadcastReceiver -Invalid Action")

    def onStartCommand(self):
        if not self._started:
            BPUtil.BPLog("Wallpaper Info Service Started.")
            self._platformWallpaper = PlatformWallpaper.PlatformWallpaper()
            self._imageFileManager = ImageFileManager.ImageFileManager()
            wpsi = w.WallpaperServiceInfo()
            self.setNewRootPath(wpsi.getSourceRootPath())
            WallpaperWidgetProvider.refreshWidgets()
            self._started = True
            self._platformTimer = PlatformTimer.PlatformTimer(self)
            self._platformTimer.setInterval(wpsi.getInterval())
            self.pause_resume_service()
        else:
            WallpaperWidgetProvider.refreshWidgets()
        self.resetSaverTimer()

    def resetSaverTimer(self):
        pass
    
    def screenChangeCallback(source, event):
        BPUtil.BPLog("WallpaperService.screenChangeCallback")
        WallpaperWidgetProvider.refreshWidgets()
        
    def wallpaperSwitchCallback(self):
        wpsi = w.WallpaperServiceInfo()
        if not wpsi.getPause():
            self.naviageWallpaper(1)

    def setInterval(self, interval):
        self._platformTimer.setInterval(interval)

    def togglePause(self):
        wpsi = w.WallpaperServiceInfo()
        wpsi.setPause(not wpsi.getPause())
        self.pause_resume_service()

    def pause_resume_service(self):
        wpsi = w.WallpaperServiceInfo()
        if wpsi.getPause():
            self._platformTimer.pause()
        else:
            self._platformTimer.resume()
            self.naviageWallpaper(1)
        self.broadcastServiceUpdate()

    def setNewRootPath(self, newRootPath):
        wpsi = w.WallpaperServiceInfo()
        wpsi.setcurrentWPath(None)
        wpsi.setThumbnail(None)
        wpsi.setSourceRootPath(newRootPath)
        self._imageFileManager.setSourceRootPath(newRootPath)

    def naviageWallpaper(self, offset):
        if not self._imageFileManager.isThemeReady() and offset == 1:
            BPUtil.BPLog("skip new image during theme preparation")
            return
        wpsi = w.WallpaperServiceInfo()
        currentWPath = wpsi.getcurrentWPath()
        if currentWPath != None:
            imagePath = self._imageFileManager.retrievePathFromSource(currentWPath, offset)
            if imagePath == None: # there is no image in source
                # self._platformWallpaper.makeThumbnailFromScreenWallpaper()
                self.broadcastServiceUpdate()
                BPUtil.BPLog("naviageWallpaper skipped by no image.")
                return
            # Check when previous image is filtered one while option is on
            while offset == -1 and not wpsi.getThemeInfo().isThemeImage(imagePath.coden()):
                PreviousImagePath = self._imageFileManager.retrievePathFromSource(imagePath, -1)
                # must avoid infinite loop by checking previous image stays same
                if PreviousImagePath.path == imagePath.path:
                    BPUtil.BPLog("naviageWallpaper skipped by no previous theme image.")
                    return
                imagePath = PreviousImagePath
            # change Wallpaper only if there is new image
            if imagePath.path != wpsi.getcurrentWPath().path:
                self.changeWallpaper(imagePath)
            else:
                BPUtil.BPLog("naviageWallpaper skipped by no previous image.")
        else:
            # Change with the first Wallpaper
            if offset == 1:
                self.changeWallpaper(None)
            else:
                BPUtil.BPLog("naviageWallpaper skipped by no previous image.")

    def setWallpaperFromLastUsedPaths(self, imagePath):
        self.restartTimer()
        self.changeWallpaper(imagePath)

    def restartTimer(self):
        self._platformTimer.resetTimer()

    def changeWallpaper(self, currentWPath):
        # Only true for the first image
        if currentWPath == None or not BPUtil.fileExists(currentWPath.path):
            currentWPath = self._imageFileManager.retrievePathFromSource(None, 1)
            if currentWPath == None: # there is no image in source
                # self._platformWallpaper.makeThumbnailFromScreenWallpaper()
                self.broadcastServiceUpdate()
                BPUtil.BPLog("changeWallpaper skipped by no image.")
                return
        wpsi = w.WallpaperServiceInfo()
        count = 0
        total = self._imageFileManager.getTotalImageCount()
        while currentWPath == None or not wpsi.getThemeInfo().isThemeImage(currentWPath.coden()):
            currentWPath = self._imageFileManager.retrievePathFromSource(currentWPath, 1)
            # must avoid infinite loop in elif action == all files are filtered
            # reach end of source due to all filtered files
            count += 1
            if (count >= total):
                BPUtil.BPLog("%s", "changeWallpaper skipped by no theme image.")
                # pause service otherwise service is hanging
                wpsi.setPause(True)
                self.pause_resume_service()
                wpsi.getLastUsedPaths().clear()
                self.broadcastServiceUpdate()
                return
        pretty_path = currentWPath.label()
        if self._platformWallpaper.setWallpaper(currentWPath.path):
            wpsi.setcurrentWPath(currentWPath)
            BPUtil.BPLog("{WP} " + pretty_path + " [" + self._imageFileManager.getImageStat(currentWPath.path) + "]")
            self.broadcastServiceUpdate()
        else:
            # it seems it falls on here, when there is no monitor connected. Even then, set current path and move on.
            wpsi.setcurrentWPath(None)
            BPUtil.BPLog("{WP} " + pretty_path + " is failed. [" + self._imageFileManager.getImageStat(currentWPath.path) + "]")

    def updateServiceTheme(self, theme):
        wpsi = w.WallpaperServiceInfo()
        wpsi.setThemeInfo(t.getThemeInfo(theme))
        self._imageFileManager.prepareSourceForTheme()
        self.broadcastServiceUpdate()

    def updateServiceThemeWithNext(self):
        self.updateServiceTheme(w.WallpaperServiceInfo().getThemeInfo().getNextThemeInfo()._theme)

    def updateServiceThemeWithPrevious(self):
        self.updateServiceTheme(w.WallpaperServiceInfo().getThemeInfo().getPrevousThemeInfo()._theme)

    def updateServiceCustomConfig(self, customConfigString):
        wpsi = w.WallpaperServiceInfo()
        wpsi.setCustomThemeInfo(t.setCustomConfig(customConfigString))
        # reassign custom theme to invoke prepareTheme() with updated custom config string
        # then prepare source again with it
        if (wpsi.getTheme() == t.Theme.custom):
            wpsi.setThemeInfo(t.getThemeInfo(t.Theme.custom))
            self._imageFileManager.prepareSourceForTheme()
        
    def broadcastServiceUpdate(self):
        #BPUtil.BPLog("WallpaperService.broadcastServiceUpdate")
        wpsi = w.WallpaperServiceInfo()
        # To Notification
        self._wallpaperNotification.buildNotification(wpsi.getcurrentWPath(), wpsi.getThumbnail(), wpsi.getTheme())
        # To Widget
        WallpaperWidgetProvider.updatePauseWidget(wpsi.getPause())
        WallpaperWidgetProvider.updateThemeWidget(wpsi.getTheme().label(), wpsi.getPause())
        wpath = wpsi.getcurrentWPath()
        if wpath != None:
            imageWithDescription = wpath.label()
            WallpaperWidgetProvider.updateLabelWidget(imageWithDescription)
        else:
            WallpaperWidgetProvider.updateLabelWidget("")
        # To UI
        self._wallpaperServiceHandler.replyToClient(wpsi.getThumbnail(), wpsi.getcurrentWPath(), wpsi.getPause())
        
    def isStarted(self):
        return self._started

_default_wpath = WPath.WPath(None, "")
_maxLastUsedPaths = 50



