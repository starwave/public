#!/usr/bin/env python3

import gi
import os
from gi.repository import Gio
gi.require_version('GdkPixbuf', '2.0')
from gi.repository import GdkPixbuf
import pathlib
import subprocess
import shutil
import time

import WallpaperServiceInfo as w
import BPUtil
import PlatformInfo

class PlatformWallpaper:

    _schema = 'org.gnome.desktop.background'
    _key = 'picture-uri'
    _key_dark = 'picture-uri-dark'
    _thumbnail_height = 100
    _setup = False
    _stable_path = ''

    def __init__(self):
        self.gsettings = Gio.Settings.new(self._schema)
        self.gsettings.set_string("picture-options", "scaled")
        self.gsettings.set_string("primary-color", "#000000")
        self.gsettings.set_string("secondary-color", "#000000")
        self.gsettings.set_string("color-shading-type", "solid")
        wallpaper_dir = pathlib.Path.home() / ".bpwallpaper"
        wallpaper_dir.mkdir(parents=True, exist_ok=True)
        self._stable_path = wallpaper_dir / "current.jpg"
        output = subprocess.check_output(['gsettings', 'get', 'org.gnome.desktop.interface', 'gtk-theme'])
        theme_name = output.decode().strip().strip("'")
        self._key = 'picture-uri-dark' if ('dark' in theme_name.lower()) else 'picture-uri'
        BPUtil.BPLog("gnome theme name = " + theme_name + ", key name = " + self._key)

    def setWallpaper(self, path):
        if not BPUtil.fileExists(path):
            BPUtil.BPLog("Wallpaper " + path + " doesn't exist.")
            return False
        return self.applyWallpaperFromFile(path)

    def applyWallpaperFromFile(self, path):
        shutil.copy2(path, self._stable_path)
        if not self._setup:
            self.setUpWallpaperFromFile(path)
        # in case time needs to be updated
        # now = time.time()
        # os.utime(path, (now, now))
        wpsi = w.WallpaperServiceInfo()
        thumbnail = self.makeThumbnail(path)
        wpsi.setThumbnail(thumbnail)
        return True

    def setUpWallpaperFromFile(self, path):
        self._setup = True
        env = os.environ.copy()
        # Ensure DBus/XDG env vars are passed to subprocess
        if "DBUS_SESSION_BUS_ADDRESS" not in env:
            env["DBUS_SESSION_BUS_ADDRESS"] = "unix:path=/run/user/{}/bus".format(os.getuid())
        if "XDG_RUNTIME_DIR" not in env:
            env["XDG_RUNTIME_DIR"] = "/run/user/{}".format(os.getuid())
        # Dark mode variant (may not exist on older GNOME versions)
        # Tell GNOME to use the symlink (only once, not every 5 seconds)
        file_uri = self._stable_path.as_uri()
        subprocess.run([
            "gsettings", "set",
            "org.gnome.desktop.background",
            self._key, file_uri
        ], env=env)
        # for lock screen:
        subprocess.run([
            "gsettings", "set",
            "org.gnome.desktop.screensaver",
            "picture-uri", file_uri
        ])
        return True

    def makeThumbnail(self, path):
        thumbnail = None
        try:
            pixbuf = GdkPixbuf.Pixbuf.new_from_file(path)
            source_width = pixbuf.get_width()
            source_height = pixbuf.get_height()
            thumbnail_width = int(source_width * self._thumbnail_height / source_height)
            thumbnail = pixbuf.scale_simple(thumbnail_width, self._thumbnail_height, GdkPixbuf.InterpType.NEAREST)
            # if width, height is known
            # thumbnail = GdkPixbuf.Pixbuf.new_from_file_at_size(path, thumbnail_width, self._thumbnail_height)
        except Exception as error:
            BPUtil.BPLog("Error in makeThumbnail: ", str(error))
            return None
        if thumbnail == None:
            BPUtil.BPLog("Error in makeThumbnail", path)
            return None
        return thumbnail

"""
path = '/home/starwave/CloudStation/BP Wallpaper/#nd#/Angelina Jolie (11).jpg'
p = PlatformWallpaper()
thumnail = p.makeThumbnail(path)
thumnail.savev('/home/starwave/Downloads/test.jpg', 'jpeg', [], [])
"""