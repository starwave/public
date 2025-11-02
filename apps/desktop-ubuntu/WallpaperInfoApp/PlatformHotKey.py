from pynput import keyboard

import BPUtil
import AppUtil as a
import WallpaperServiceConnection

class PlatformHotKey:

    def __init__(self):
        self._hotkeys = [ \
            keyboard.Key.media_previous, keyboard.Key.media_play_pause, keyboard.Key.media_next, \
            keyboard.Key.media_volume_down, keyboard.Key.media_volume_up, \
            keyboard.Key.f7, keyboard.Key.f8, keyboard.Key.f9, \
            keyboard.Key.f10, keyboard.Key.f11 
            ]
        self._current = set()

    def HotKeyPressed(self, key):
        BPUtil.BPLog(str(key))
        if key == keyboard.Key.media_play_pause or key == keyboard.Key.f8:
            WallpaperServiceConnection.broadcastToService(a.MSG.TOGGLE_PAUSE)
        elif key == keyboard.Key.media_next or key == keyboard.Key.f9:
            WallpaperServiceConnection.broadcastToService(a.MSG.NEXT)
        elif key == keyboard.Key.media_previous or key == keyboard.Key.f7:
            WallpaperServiceConnection.broadcastToService(a.MSG.PREVIOUS)
        elif key == keyboard.Key.media_volume_down or key == keyboard.Key.f10:
            WallpaperServiceConnection.broadcastToService(a.MSG.PREVIOUS_THEME)
        elif key == keyboard.Key.media_volume_up or key == keyboard.Key.f11:
            WallpaperServiceConnection.broadcastToService(a.MSG.NEXT_THEME)
        else:
            pass
    
    def on_press(self, key):
        if any([key in self._hotkeys]):
            self._current.add(key)
            self.HotKeyPressed(key)
    
    def on_release(self, key):
        if any([key in self._hotkeys]):
            self._current.remove(key)
    
    def startListen(self):
        self.listener = keyboard.Listener(
            on_press=self.on_press,
            on_release=self.on_release)
        self.listener.start()
    
    def beginHotKey(self):
        self.startListen()

    def endHotKey(self):
        self.listener.stop()
