#!/usr/bin/env python3

import AppUtil as a
import WallpaperServiceInfo as w
import ThemeInfo as t
import BPUtil

class WallpaperServiceHandler:

    def __init__(self, wallpaperService):
        self._service = wallpaperService
        self._incomingMessenger = None

    def replyToClient(self, thumbnail, currentWPath, pause):
        if self._incomingMessenger != None:
            self._incomingMessenger._wallpaperInfoUI.broadcastReceiver(thumbnail, currentWPath, pause)

    def handleMessage(self, msg, intOption = 0, objectOption = None):
        wpsi = w.WallpaperServiceInfo();
        if msg == a.MSG.CUSTOM_CONFIG:
            BPUtil.BPLog("WallpaperServiceHandler - MSG.CUSTOM_CONFIG")
            customConfigString = objectOption;
            self._service.updateServiceCustomConfig(customConfigString)
            self._service.restartTimer()
        elif msg == a.MSG.REQUEST_INFO:
            BPUtil.BPLog("WallpaperServiceHandler - MSG.REQUEST_INFO")
        elif msg == a.MSG.PAUSE:
            BPUtil.BPLog("WallpaperServiceHandler - MSG.PAUSE")
            wpsi.setPause(intOption == 1)
            self._service.pause_resume_service()
        elif msg == a.MSG.PREVIOUS:
            BPUtil.BPLog("WallpaperServiceHandler - MSG.PREVIOUS")
            self._service.restartTimer()
            self._service.naviageWallpaper(-1)
        elif msg == a.MSG.NEXT:
            BPUtil.BPLog("WallpaperServiceHandler - MSG.NEXT")
            self._service.restartTimer()
            self._service.naviageWallpaper(1)
        elif msg == a.MSG.SET_INTERVAL:
            BPUtil.BPLog("WallpaperServiceHandler - MSG.SET_INTERVAL")
            if intOption > 0:
                wpsi.setInterval(intOption)
                self._service.setInterval(intOption)
                self._service.restartTimer()
        elif msg == a.MSG.SET_THEME:
            BPUtil.BPLog("WallpaperServiceHandler - MSG.SET_THEME")
            self._service.updateServiceTheme(intOption)
            self._service.restartTimer()
        elif msg == a.MSG.PREVIOUS_THEME:
            BPUtil.BPLog("WallpaperServiceHandler - MSG.PREVIOUS_THEME")
            self._service.updateServiceThemeWithPrevious();
        elif msg == a.MSG.NEXT_THEME:
            BPUtil.BPLog("WallpaperServiceHandler - MSG.NEXT_THEME")
            self._service.updateServiceThemeWithNext();
        elif msg == a.MSG.SET_MODE:
            BPUtil.BPLog("WallpaperServiceHandler - MSG.SET_MODE")
        elif msg == a.MSG.SET_SAVER:
            BPUtil.BPLog("WallpaperServiceHandler - MSG.SET_SAVER")
        elif msg == a.MSG.TOGGLE_PAUSE:
            BPUtil.BPLog("WallpaperServiceHandler - MSG.TOGGLE_PAUSE")
        elif msg == a.MSG.SET_ROOT:
            BPUtil.BPLog("WallpaperServiceHandler - MSG.SET_ROOT")
            self._service.setNewRootPath(objectOption)
        elif msg == a.MSG.SET_WALLPAPER:
            BPUtil.BPLog("WallpaperServiceHandler - MSG.SET_WALLPAPER")
        else:
            BPUtil.BPLog("WallpaperServiceHandler - Invalid MSG Error")

    def unbind(self):
        self._incomingMessenger = None


def incomingHandler(incomingMessenger):
    wpsi = w.WallpaperServiceInfo();
    wpsi.getWallpaperService()._wallpaperServiceHandler._incomingMessenger = incomingMessenger;
    return wpsi.getWallpaperService()._wallpaperServiceHandler

def startService():
    w.WallpaperServiceInfo().getWallpaperService().startService()

def stopService():
    w.WallpaperServiceInfo().getWallpaperService().stopService()

#w_handler = WallpaperServiceHandler(w.WallpaperServiceInfo().getWallpaperService())
#w_handler.handleMessage(a.MSG.REQUEST_INFO, 2)
