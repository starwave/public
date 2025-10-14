#!/usr/bin/env python3

import cairo
import threading
import PlatformInfo
import BPUtil
import html

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk
gi.require_version('Gdk', '3.0')
from gi.repository import Gdk
from gi.repository import GLib

class Singleton(type):
    _instances = {}
    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super(Singleton, cls).__call__(*args, **kwargs)
        return cls._instances[cls]

class Widgets(metaclass=Singleton):
    def __init__(self):
        self._lableWidgetsDict = {}
        self._themeWidgetsDict = {}
        self._pauseWidgetsDict = {}
        self._previousMonitorCount = 0

_themeChangeCount = 0
_old_value = 0

def refreshWidgets():
    w = Widgets()
    clearWidgets(w._lableWidgetsDict)
    clearWidgets(w._themeWidgetsDict)
    clearWidgets(w._pauseWidgetsDict)
    resolutions = PlatformInfo.get_screen_info(None)
    w._previousMonitorCount = len(resolutions)
    i = 0
    for r in resolutions:
        #print(r[0], r[1], r[3], r[3])
        widget = WallpaperWidget()
        widget.move(r[2]+60, r[3]+r[1]-40)
        widget.set_size_request(300, 30)
        w._lableWidgetsDict[i] = widget
        widget = WallpaperWidget()
        widget.move(r[2]+r[0] - 90, r[3]+50)
        w._themeWidgetsDict[i] = widget
        widget = WallpaperWidget()
        widget.move(r[2]+r[0] - 70, r[3]+r[1]-40)
        w._pauseWidgetsDict[i] = widget
        i += 1

def updateLabelWidget(text):
    w = Widgets()
    resolutions = PlatformInfo.get_screen_info(None)
    if len(resolutions) !=  w._previousMonitorCount:
        screenChanged()
    for widget in w._lableWidgetsDict.values():
        widget.setCaption(text)

def updateThemeWidget(themeLabel, forceShow):
    w = Widgets()
    global _themeChangeCount, _old_value
    for widget in w._themeWidgetsDict.values():
        if (widget._caption != themeLabel or forceShow):
            widget.setCaption(themeLabel)
            widget.setHide(False)
            _themeChangeCount += 1
        if widget._isVisible and not forceShow:
            _old_value = _themeChangeCount
            timer = threading.Timer(7.0, delayedHide, [widget])
            timer.start()

def delayedHide(widget):
    global _themeChangeCount, _old_value
    if _old_value == _themeChangeCount:
        widget.setHide(True)

def updatePauseWidget(pause):
    w = Widgets()
    for widget in w._pauseWidgetsDict.values():
        widget.setCaption("\u23F8" if pause else "")

def clearWidgets(dict):
    for widget in dict.values():
        widget.destroy()
    dict.clear()

def clearAllWidgets():
    w = Widgets()
    clearWidgets(w._lableWidgetsDict)
    clearWidgets(w._themeWidgetsDict)
    clearWidgets(w._pauseWidgetsDict)

def screenChanged():
    BPUtil.BPLog("Screen has been changed")
    refreshWidgets()

class WallpaperWidget(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self)
        self.set_size_request(60, 30)
        self.set_skip_taskbar_hint(True) # remove icon from taskbar
        self.set_keep_below(True)
        #self.connect('destroy', Gtk.main_quit) # disable since there is no close button
        self.connect('draw', self.draw)

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and screen.is_composited():
            self.set_visual(visual)

        grid = Gtk.Grid()
        self.add(grid)
        self.label = Gtk.Label()
        self.label.set_alignment(0,0)
        self.label.set_size_request(50, 20)
        self.modify_fg(Gtk.StateFlags.NORMAL, Gdk.color_parse("white"))
        self.label.set_name("shadow_label")
        self.label.set_text("")
        grid.attach(self.label, 0,0,1,1)

        css = b"""
                #shadow_label { text-shadow: -0px -0px white, -1px -1px gray, 1px 1px black; }
            """
        css_provider = Gtk.CssProvider()
        css_provider.load_from_data(css)
        context = Gtk.StyleContext()
        screen = Gdk.Screen.get_default()
        context.add_provider_for_screen(screen, css_provider,
                                        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        self.set_app_paintable(True)
        self.set_decorated(False)
        self._isVisible = False
        self._caption = ""
        self.show_all()

    def draw(self, widget, context):
        context.set_source_rgba(0, 0, 0, 0)
        context.set_operator(cairo.OPERATOR_SOURCE)
        context.paint()
        context.set_operator(cairo.OPERATOR_OVER)

    def setCaption(self, caption):
        self._caption = caption
        Gdk.threads_add_idle(GLib.PRIORITY_DEFAULT_IDLE, self.setCaptionInternal, caption)

    def setCaptionInternal(self, caption):
        #self.label.set_text(caption) -> plain text without css markup
        caption_esc = html.escape(caption) # Must html escape
        self.label.set_use_markup(True)
        self.label.set_markup(caption_esc) # for Bold = '<b>'+caption_esc+'</b>'

    def setHide(self, hide):
        if hide:
            self._isVisible = False
            Gdk.threads_add_idle(GLib.PRIORITY_DEFAULT_IDLE, self.label.hide)
        else:
            self._isVisible = True
            Gdk.threads_add_idle(GLib.PRIORITY_DEFAULT_IDLE, self.label.show)


"""
refreshWidgets()
updateLabelWidget("Animation/Up (1)")
updateThemeWidget("Default+", True)
updatePauseWidget(True)
timer = threading.Timer(12.0, clearAllWidgets)
timer.start()
Gtk.main()
"""