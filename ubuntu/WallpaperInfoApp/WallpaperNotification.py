#!/usr/bin/env python3

from collections import OrderedDict
import threading

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk
gi.require_version('Gdk', '3.0')
from gi.repository import Gdk
from gi.repository import GLib
gi.require_version('Notify', '0.7')
from gi.repository import Notify
gi.require_version('AppIndicator3', '0.1')

import WallpaperInfoUI
import WallpaperServiceInfo as w
import WallpaperServiceConnection
import PlatformHotKey
import BPUtil
import WPath
import ThemeInfo as t
import AppUtil as a

_maxImageList = 15

class WallpaperNotification:

    def __init__(self, app_id, icon):
        self._lock = myLock()
        builder = Gtk.Builder()
        builder.add_from_file('WallpaperInfoApp.glade')
        self.initWithBuilder(builder)
        # init properties
        self._app_id = app_id
        self._icon = icon
        self._menuThumbnail = None
        self._isOpen = True
        self._pathsInMenu = MyOrderedDict()
        self._previousPath = WPath.WPath("", "")
        self._previousThumbnail = None
        self._previousTheme = t.Theme.all
        self.setThumbnail(None, None)
        # set up optionUI / customconfig window

        self._wallpaperInfoUI = WallpaperInfoUI.WallpaperInfoUI(builder, icon)
        self.connectSignals(builder)
        # initialize menu items
        self.preparePathsInMenu()
        themeLabels = t.getLabels()
        self._themesMenuItem.set_submenu(Gtk.Menu())
        index = 0
        for themelabel in themeLabels:
            menuItem = Gtk.CheckMenuItem(label=themelabel)
            menuItem.connect('activate', self.themeMenuItemSelected)
            menuItem.set_active(False)
            menuItem.name = str(index)
            self._themesMenuItem.get_submenu().append(menuItem)
            index += 1
        self._themesMenuItem.show_all()

        # initialize app indicator
        self.initializeAppIndicator()
        # set up hot key
        self._hotKeys = PlatformHotKey.PlatformHotKey()
        self._hotKeys.beginHotKey()

    def initWithBuilder(self, builder):
        self._mainMenu = builder.get_object('MainMenu')
        self._wallpaperMenuItem = builder.get_object('wallpaperMenuItem')
        self._themesMenuItem = builder.get_object('themesMenuItem')
        self._pauseMenuItem = builder.get_object('pauseMenuItem')
        self._thumbnailMenuItem = builder.get_object('thumbnailMenuItem')
        self._thumbnailMenuItemImage = builder.get_object('thumbnailMenuItemImage')
        self._optionsMenuItem = builder.get_object('optionsMenuItem')

    def connectSignals(self, builder):
        builder.connect_signals({
            "menuItemPreviousImage": self.menuItemPreviousImage,
            "menuItemNextImage": self.menuItemNextImage,
            "menuItemPauseResume": self.menuItemPauseResume,
            "imageMenuItemClicked": self.imageMenuItemClicked,
            "onShowOrHide": self.onShowOrHide,
            "onAbout": self.onAbout,
            "onQuit": self.onQuit,

            "onDirButtonClicked": self._wallpaperInfoUI.onDirButtonClicked,
            "onIntervalScaleValueChanged": self._wallpaperInfoUI.onIntervalScaleValueChanged,
            "onThemeComboBoxChanged": self._wallpaperInfoUI.onThemeComboBoxChanged,
            "thumbnailImageClicked": self._wallpaperInfoUI.thumbnailImageClicked,
            "onStartStopButtonClicked": self._wallpaperInfoUI.onStartStopButtonClicked,
            "onPreviousButtonClicked": self._wallpaperInfoUI.onPreviousButtonClicked,
            "onPauseButtonClicked": self._wallpaperInfoUI.onPauseButtonClicked,
            "onNextButtonClicked": self._wallpaperInfoUI.onNextButtonClicked,
            "customConfigStringSetButtonClicked": self._wallpaperInfoUI.customConfigStringSetButtonClicked,
        })

    def __del__(self):
        self._hotKeys.endHotKey()

    def buildNotification(self, wpath, thumbnail, theme):
        # BPUtil.BPLog("WallpaperNotification.buildNotification()")
        if not self._isOpen:
            return
        self._previousThumbnail = thumbnail
        Gdk.threads_add_idle(GLib.PRIORITY_DEFAULT_IDLE, self.updatePathsInMenu, wpath)
        Gdk.threads_add_idle(GLib.PRIORITY_DEFAULT_IDLE, self.setResumeOrPauseOnMenuItem)
        Gdk.threads_add_idle(GLib.PRIORITY_DEFAULT_IDLE, self.setThumbnail, wpath, thumbnail)
        Gdk.threads_add_idle(GLib.PRIORITY_DEFAULT_IDLE, self.updateThemeSelectionInMenu, theme)

    def setThumbnail(self, wpath, thumbnail):
        if thumbnail != None:
            if self._menuThumbnail != None:
                del self._menuThumbnail
            self._menuThumbnail = thumbnail
            self._thumbnailMenuItemImage.set_from_pixbuf(thumbnail)
            self._thumbnailMenuItem.set_label(wpath.label())
        else:
            # to use set_from_pixbuf: pixbuf = Gtk.Image.new_from_file(self._icon)
            self._thumbnailMenuItem.set_label("Waiting for Image")
            self._thumbnailMenuItemImage.set_from_file(self._icon)
        if (wpath != None):
            self._thumbnailMenuItem.name = wpath.path
            self._thumbnailMenuItem.set_sensitive(True)
        else:
            self._thumbnailMenuItem.name = None
            self._thumbnailMenuItem.set_sensitive(False)

    def setResumeOrPauseOnMenuItem(self):
        wpsi = w.WallpaperServiceInfo()
        if (wpsi.getPause()):
            self._pauseMenuItem.set_label("Resume")
        else:
            self._pauseMenuItem.set_label("Pause")

    def preparePathsInMenu(self):
        self._wallpaperMenuItem.set_submenu(Gtk.Menu())
        for index in range(0,_maxImageList):
            menuItem = Gtk.CheckMenuItem()
            menuItem.set_active(False)
            if index < len(self._pathsInMenu):
                wpath = self._pathsInMenu.items()[index]
                menuItem.set_label(wpath.label())
                menuItem.name = wpath.path
                menuItem.set_sensitive(True)
                menuItem.connect('activate', self.imageMenuItemClicked)
                if wpath.path == self._previousPath.path:
                    menuItem.set_active(True)
            else:
                menuItem.set_label("(Empty)")
                menuItem.name = None
                menuItem.set_sensitive(False)
            self._wallpaperMenuItem.get_submenu().append(menuItem)
        self._wallpaperMenuItem.show_all()

    def updatePathsInMenu(self, wpath):
        if wpath == None:
            #BPUtil.BPLog("WallpaperNotification.updatePathsInMenu - Error with None")
            return
        previous_index = self._pathsInMenu.firstIndexOf(self._previousPath.path)
        if previous_index >= 0:
            # there is no other easy way but iterating whole set
            for menuItem in self._wallpaperMenuItem.get_submenu().get_children():
                if previous_index == 0:
                    menuItem.set_active(False)
                    break
                previous_index -= 1
        self._previousPath = wpath
        wpathLabel = wpath.label()
        index = self._pathsInMenu.firstIndexOf(wpath.path)
        if index >= 0:
            # there is no other easy way but iterating whole set
            for menuItem in self._wallpaperMenuItem.get_submenu().get_children():
                if index == 0:
                    menuItem.set_active(True)
                    break
                index -= 1
        else:
            # value is not used.
            self._pathsInMenu.prepend(wpath.path, wpath.exif)
            if len(self._pathsInMenu) > _maxImageList:
                self._pathsInMenu.popItem()
            menuItem = Gtk.CheckMenuItem(label=wpathLabel)
            menuItem.set_active(True)
            menuItem.set_label(wpathLabel)
            menuItem.set_sensitive(False)
            # TODO activate impl by distinguish between actual click and call
            # menuItem.connect('activate', self.imageMenuItemClicked)
            self._wallpaperMenuItem.get_submenu().insert(menuItem, 0)
            menuitems_len = len(self._wallpaperMenuItem.get_submenu().get_children())
            if menuitems_len > _maxImageList:
                menuitem_to_delete = self._wallpaperMenuItem.get_submenu().get_children()[menuitems_len - 1]
                self._wallpaperMenuItem.get_submenu().remove(menuitem_to_delete)
        self._wallpaperMenuItem.show_all()

    def updateThemeSelectionInMenu(self, theme):
        theme_int = int(theme)
        if theme_int != self._previousTheme:
            self._previousTheme = theme_int
            index = 0
            menuItems = self._themesMenuItem.get_submenu().get_children()
            for menuItem in menuItems:
                # only in GTK, set_active call triggers themeMenuItemSelected
                if theme_int != index:
                    if menuItem.get_active():
                        menuItem.set_active(False)
                        menuItem.set_sensitive(True)
                else:
                    menuItem.set_active(True)
                    menuItem.set_sensitive(False)
                index += 1

    def themeMenuItemSelected(self, *args):
        menuItem = args[0]
        theme_int = int(menuItem.name)
        if theme_int != self._previousTheme and menuItem.get_active():
            WallpaperServiceConnection.broadcastToService(a.MSG.SET_THEME, theme_int)

    def menuItemPreviousImage(self, *args):
        WallpaperServiceConnection.broadcastToService(a.MSG.PREVIOUS)

    def menuItemNextImage(self, *args):
        WallpaperServiceConnection.broadcastToService(a.MSG.NEXT)

    def menuItemPauseResume(self, *args):
        WallpaperServiceConnection.broadcastToService(a.MSG.TOGGLE_PAUSE)

    def imageMenuItemClicked(self, *args):
        menuitem = args[0]
        path = menuitem.name
        if path != None and BPUtil.fileExists(path):
            BPUtil.showImageFile(path)
            #BPUtil.showImagePreview(path)

    def onShowOrHide(self, *args):
        WallpaperInfoUI.showOptionWindow(True)

    def onAbout(self, *args):
        Notify.Notification.new("About WallpaperInfoApp",
            "WallpaperInfoApp 1.0 by Brad Park",
            self._icon).show()

    def onQuit(self, *args):
        wpsi = w.WallpaperServiceInfo()
        wpsi.getWallpaperService().stopService()
        Notify.uninit()
        Gtk.main_quit()

    def initializeAppIndicator(self):
        appIndicatorSupport = True
        try:
            from gi.repository import AppIndicator3
        except:
            appIndicatorSupport = False
        if appIndicatorSupport:
            self.ind = AppIndicator3.Indicator.new(
                self._app_id, self._icon,
                AppIndicator3.IndicatorCategory.APPLICATION_STATUS)
            self.ind.set_status(AppIndicator3.IndicatorStatus.ACTIVE)
            self.ind.set_menu(self._mainMenu)
            self.ind.set_secondary_activate_target(self._optionsMenuItem)
        else:
            self.ind = Gtk.StatusIcon()
            self.ind.set_from_file(self._icon)
            self.ind.connect('popup-menu', self.onPopupMenu)
        Notify.init(self._app_id)

    # not used
    def onPopupMenu(self, icon, button, time):
        self.menu.popup(None, None, Gtk.StatusIcon.position_menu, icon,
                        button, time)

class myLock():
    def __init__(self):
        self._lock = threading.Lock()
    def acquire(self, tag = ""):
        #print(tag, "lock acquire")
        self._lock.acquire()
    def release(self, tag = ""):
        #print(tag, "lock release")
        self._lock.release()

class MyOrderedDict(OrderedDict):
    def prepend(self, key, value):
        self[key] = value
        self.move_to_end(key, last=False)

    def firstIndexOf(self, key):
        try:
            index = list(self.keys()).index(key)
        except:
            return -1
        return index

    def popItem(self):
        last_key = list(self.keys())[len(self) - 1]
        del self[last_key]