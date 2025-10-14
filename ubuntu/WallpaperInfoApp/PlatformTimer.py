#!/usr/bin/env python3

from threading import Timer

class RepeatingTimer(Timer):
    def run(self):
        while not self.finished.wait(self.interval):
            self.function(*self.args, **self.kwargs)

class PlatformTimer:
    _switchHandler = None
    _pause = False
    _interval = 5

    def __init__(self, wallpaperService):
        self._wallpaperService = wallpaperService
        
    def scheduleSwitchWallpaper(self, seconds):
        if (self._switchHandler != None):
            self.cancelSwitchWallpaper()
        self._switchHandler = RepeatingTimer(interval=seconds, function=self.executeCallback)
        self._pause = False
        self._switchHandler.start()

    def executeCallback(self):
        if not self._pause:
            self._wallpaperService.wallpaperSwitchCallback()

    def cancelSwitchWallpaper(self):
        if (self._switchHandler != None):
            self._switchHandler.cancel()
            self._switchHandler = None
        self._pause = True

    def resetTimer(self):
        if not self._pause:
            self.resume()
    
    def pause(self):
        self.cancelSwitchWallpaper()

    def resume(self):
        self.scheduleSwitchWallpaper(self._interval)

    def setInterval(self, interval):
        self._interval = interval
        if not self._pause:
            self.resume()
