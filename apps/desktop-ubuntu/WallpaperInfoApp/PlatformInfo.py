#!/usr/bin/env python3

import os, sys
import gi
import threading
import inspect
import subprocess
gi.require_version('Gdk', '3.0')
gi.require_version('Gtk', '3.0')
from gi.repository import Gdk, Gtk

import BPUtil

def get_screen_info(monitor=None, min_size=800):
    """
    Returns monitor resolutions with position.
    Uses GDK first, then falls back to XRandR if sizes look invalid.
    """
    # Flush pending events so GDK has fresh monitor info
    while Gtk.events_pending():
        Gtk.main_iteration_do(False)
    display = Gdk.Display.get_default()
    n_monitors = display.get_n_monitors()
    def gdk_monitor_info(m):
        geom = m.get_geometry()
        scale = m.get_scale_factor()
        return (geom.width * scale, geom.height * scale, geom.x, geom.y)
    results = []
    if monitor is None:
        for i in range(n_monitors):
            results.append(gdk_monitor_info(display.get_monitor(i)))
    else:
        if 0 <= monitor < n_monitors:
            results.append(gdk_monitor_info(display.get_monitor(monitor)))
        else:
            return None
    # Check if any monitor looks too small ? try xrandr fallback
    needs_fallback = any(w < min_size or h < min_size for w, h, _, _ in results)
    if needs_fallback:
        try:
            xrandr_out = subprocess.check_output(["xrandr"]).decode()
            # Look for connected monitors with resolution info
            fallback = []
            for line in xrandr_out.splitlines():
                if " connected" in line and "+" in line:
                    # e.g. "1920x1080+0+0"
                    parts = line.split()
                    for p in parts:
                        if "x" in p and "+" in p:
                            res, pos = p.split("+", 1)
                            w, h = map(int, res.split("x"))
                            x, y = map(int, pos.split("+"))
                            fallback.append((w, h, x, y))
                            break
            if fallback:
                results = fallback
        except Exception as e:
            print("XRandR fallback failed:", e)
    return results if monitor is None else results[0]

class BPLock():
    def __init__(self, parent = None):
        self._lock = threading.Lock()
        self._parent = parent

    def acquire(self, tag = ""):
        if self._parent != None and tag == "":
            calframe = inspect.getouterframes(inspect.currentframe(), 2)
            tag = type(self._parent).__name__ + "." + calframe[1][3]
        if tag != "":
            print("[" + tag + "]", "lock acquire")
        self._lock.acquire()

    def release(self, tag = ""):
        if self._parent != None and tag == "":
            calframe = inspect.getouterframes(inspect.currentframe(), 2)
            tag = type(self._parent).__name__ + "." + calframe[1][3]
        if tag != "":
            print("[" + tag + "]", "lock release")
        self._lock.release()

def exit_on_process_exists():
    current_pid = str(os.getpid())
    current_ppid = str(os.getppid())
    current_pname = BPUtil.bashCommand(f"ps -o cmd= {current_pid:s}")
    BPUtil.BPLog(f"pid = {current_pid:s}, ppid = {current_ppid:s}, pname = {current_pname:s}")
    output = BPUtil.bashCommand("ps -ef")
    for line in output.split("\n"):
        fields = line.split()
        pid = fields[1]
        pname = " ".join(fields[7:])
        if "WallpaperInfoApp.py" in pname or "WallpaperInfoApp.bin" in pname:
            # WallpaperInfoApp.bin executes self so that ppid needs to be checked.
            if pid != current_pid and pid != current_ppid:
                print(line)
                BPUtil.BPLog(f"Quitting because other instance process ({pid:s}) is already running.")
                sys.exit()

def printProps(object):
    attrs = vars(object)
    print(type(object).__name__ + ": ", ", ".join("%s: %s" % item for item in attrs.items()))

def setWallpaperWithBash(file_uri):
    BPUtil.bashCommand(f"gsettings set org.gnome.desktop.background picture-uri \"{file_uri}\"")



