#!/usr/bin/env python3

import os
def init_env():
    """
    Ensure GTK/GDK uses the correct backend and desktop hint
    so that monitor resolution queries work consistently.
    Must run before importing gi.repository or GTK libraries.
    """
    # Force GTK to use X11 backend (avoids Wayland logical scaling issues)
    os.environ["GDK_BACKEND"] = "x11"
    # Normalize desktop hint — Unity works more reliably than ubuntu:GNOME
    os.environ["XDG_CURRENT_DESKTOP"] = "Unity"
    # Optional: ensure DISPLAY is set (some environments drop it)
    if "DISPLAY" not in os.environ:
        os.environ["DISPLAY"] = ":0"
init_env()

import sys
import signal
import WallpaperServiceInfo as w
import PlatformInfo
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

# Handle pressing Ctr+C properly, ignored by default
signal.signal(signal.SIGINT, signal.SIG_DFL)

# check if other instance is alreeady running
PlatformInfo.exit_on_process_exists()

# start service
wpsi = w.WallpaperServiceInfo()
service = wpsi.getWallpaperService()
service.startService()

#print(Gtk.get_major_version(), Gtk.get_minor_version(), Gtk.get_micro_version())
Gtk.main()

# ubuntu 22.04 version gtk (current version 3,24,33)
#if Gtk.check_version(3, 24, 25) is not None:
#    print("GTK version is older than 3.24.25")
#    # Handle the older version or exit
#else:
#    print("GTK version is 3.24.25 or newer")
#    # Proceed with your code


def dump_env(prefixes=("XDG_", "GDK_", "GTK_", "WAYLAND", "DISPLAY", "DBUS")):
    print("=== Relevant Environment Variables ===")
    for k, v in sorted(os.environ.items()):
        if any(k.startswith(p) for p in prefixes):
            print(f"{k}={v}")
    print("======================================")

if __name__ == "__main__":
    dump_env()
    try:
        import gi
        gi.require_version('Gdk', '3.0')
        from gi.repository import Gdk
        display = Gdk.Display.get_default()
        if display is None:
            print("No Gdk.Display available (are you inside GNOME/Wayland/X11?)")
        else:
            print(f"Number of monitors detected: {display.get_n_monitors()}")
            for i in range(display.get_n_monitors()):
                m = display.get_monitor(i)
                g = m.get_geometry()
                print(f"Monitor {i}: {g.width}x{g.height} @ ({g.x}, {g.y})")
    except Exception as e:
        print("Error initializing Gdk:", e, file=sys.stderr)