#!/usr/bin/env python3

import DirectoryChooserDialog
import ThemeInfo as t
import WallpaperServiceInfo as w
import AppUtil as a
import WallpaperServiceConnection
import BPUtil
import PlatformInfo
import CustomConfigDialog

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk
gi.require_version('Gdk', '3.0')
from gi.repository import Gdk
from gi.repository import GLib

class WallpaperInfoUI:
    def __init__(self, builder, icon):
        global _singleUI
        _singleUI = self
        self.initWithBuilder(builder)
        self._icon = icon
        self._optionWindow.set_icon_from_file(self._icon)
        self._optionWindow.set_size_request(240,400)
        r = PlatformInfo.get_screen_info(0)
        self._optionWindow.move(r[2]+r[0]-240, r[3]+20)
        self._optionWindow.show_all()
        self._optionWindow.hide()
        self._isHidden = True
        self._serviceConnection = None
        self._serviceRunning = False
        list_store = Gtk.ListStore(str)
        for label in t.getLabels():
            list_store.append([label])
        self._themeComboBox.set_model(list_store)
        renderer_text = Gtk.CellRendererText()
        self._themeComboBox.pack_start(renderer_text, True)
        self._themeComboBox.add_attribute(renderer_text, "text", 0)
        # set up controls after init to avoid too many resursive call
        Gdk.threads_add_idle(GLib.PRIORITY_DEFAULT_IDLE, self.onLoad, [])

    def initWithBuilder(self, builder):
        self._optionWindow = builder.get_object('WallpaperInfoUI')
        self._rootPathText = builder.get_object('rootPathText')
        self._themeComboBox = builder.get_object('themeComboBox')
        self._intervalScale = builder.get_object('intervalScale')
        self._thumbnailImage = builder.get_object('thumbnailImage')
        self._startStopButton = builder.get_object('startStopButton')
        self._previousButton = builder.get_object('previousButton')
        self._playPauseButton = builder.get_object('playPauseButton')
        self._nextButton = builder.get_object('nextButton')
        self._customConfigStringText = builder.get_object('customConfigStringText')

    def __del__(self):
        if self._serviceConnection != None:
            self._serviceConnection.unbindService()
            self._serviceConnection = None

    def onLoad(self, parm):
        if a.isMyServiceRunning():
            self._serviceRunning = True
            self._serviceConnection = WallpaperServiceConnection.bindService(self)
        else:
            self._serviceRunning = False
        self.updateLayoutWithServiceInfo()

    # Option Window Signal
    def onDirButtonClicked(self, button):
        BPUtil.BPLog("onDirButtonClicked")
        wpsi = w.WallpaperServiceInfo()
        path = wpsi.getSourceRootPath()
        ds = DirectoryChooserDialog.DirectoryChooserDialog()
        new_path = ds.directoryChooserDialog(self._optionWindow, path)
        if new_path != None and new_path != "" and new_path != path:
            self._serviceConnection.sendMessageToService(a.MSG.SET_ROOT, 0, new_path)
            self.updateLayoutWithServiceInfo()

    def onThemeComboBoxChanged(self, widget):
        if self._doneLoading:
            BPUtil.BPLog("onThemeComboBoxChanged")
            theme_index = widget.get_active()
            if self._serviceConnection !=  None:
                self._serviceConnection.sendMessageToService(a.MSG.SET_THEME, theme_index)

    def onIntervalScaleValueChanged(self, adj):
        if self._doneLoading:
            value = int(adj.get_value())
            BPUtil.BPLog("onIntervalScaleChangeValue", str(value))
            self._serviceConnection.sendMessageToService(a.MSG.SET_INTERVAL, value)

    def onStartStopButtonClicked(self, button):
        BPUtil.BPLog("onStartStopButtonClicked")

        if a.isMyServiceRunning():
            self._serviceRunning = True
        else:
            self._serviceRunning = False
        if self._serviceRunning:
            WallpaperServiceConnection.stopService()
            self._serviceConnection.unbindService()
            self._serviceConnection = None
        else:
            self._serviceConnection = WallpaperServiceConnection.bindService(self)
            WallpaperServiceConnection.startService()
        self._serviceRunning = not self._serviceRunning
        self.updateLayoutWithServiceInfo()

    def onPreviousButtonClicked(self, button):
        BPUtil.BPLog("onPreviousButtonClicked")
        self._serviceConnection.sendMessageToService(a.MSG.PREVIOUS)

    def onPauseButtonClicked(self, button):
        BPUtil.BPLog("onPauseButtonClicked")
        wpsi = w.WallpaperServiceInfo()
        self._serviceConnection.sendMessageToService(a.MSG.PAUSE, 0 if wpsi.getPause() else 1)
        self.updateLayoutWithServiceInfo()

    def onNextButtonClicked(self, button):
        BPUtil.BPLog("onNextButtonClicked")
        self._serviceConnection.sendMessageToService(a.MSG.NEXT)

    def updateCustomConfigString(self, customConfigString):
        wpsi = w.WallpaperServiceInfo()
        # request to update service only when it's different from previous set
        if wpsi.getCustomConfigString() != customConfigString:
            self._serviceConnection.sendMessageToService(a.MSG.CUSTOM_CONFIG, 0, customConfigString)

    def customConfigStringSetButtonClicked(self, button):
        BPUtil.BPLog("customConfigStringSetButtonClicked")
        customConfigString = w.WallpaperServiceInfo().getCustomConfigString()
        CustomConfigDialog.openCustomConfigDialog(self._optionWindow, customConfigString, self.customConfigStringSetCallback)

    def customConfigStringSetCallback(self, newCustomConfigString):
        if newCustomConfigString != None and newCustomConfigString != "":
            self.updateCustomConfigString(newCustomConfigString)
            self._customConfigStringText.set_text(newCustomConfigString)

    # option window update layout
    def updateLayoutWithServiceInfo(self):
        controls = [
            self._rootPathText,
            self._themeComboBox,
            self._intervalScale,
            self._thumbnailImage,
            # self._startStopButton,
            self._previousButton,
            self._playPauseButton,
            self._nextButton,
            self._customConfigStringText]
        if a.isMyServiceRunning():
            self._serviceRunning = True
            for control in controls:
                control.set_sensitive(True)
        else:
            self._serviceRunning = False
            for control in controls:
                control.set_sensitive(False)
        self._doneLoading = False
        # initialize controls on UI
        wpsi = w.WallpaperServiceInfo()
        # source root path
        prettyRootPath = wpsi.getSourceRootPath().replace(BPUtil.getHomeDirectory(), "~")
        self._rootPathText.set_text(prettyRootPath)
        # theme combo box
        self._themeComboBox.set_active(wpsi.getTheme())
        # interval scale
        # gtk.Adjustment(value = 7, lower = 5, upper = 30, step_incr = 1, page_incr = 0, page_size = 0)
        # adj = Gtk.Adjustment(wpsi.getInterval(), 5, 30, 1)
        self._intervalScale.set_value(wpsi.getInterval())
        # customConfigString
        self._customConfigStringText.set_text(wpsi.getCustomConfigString())
        # media buttons
        image = Gtk.Image.new_from_icon_name("gtk-media-play", Gtk.IconSize.BUTTON) if wpsi.getPause() else \
                Gtk.Image.new_from_icon_name("gtk-media-pause", Gtk.IconSize.BUTTON)
        self._playPauseButton.set_image(image)
        image = Gtk.Image.new_from_icon_name("gtk-media-stop", Gtk.IconSize.BUTTON) if self._serviceRunning else \
                Gtk.Image.new_from_icon_name("gtk-media-record", Gtk.IconSize.BUTTON)
        self._startStopButton.set_image(image)
        # thumbnail
        self.refreshThumbnail()
        # Notify UI loading is done
        self._doneLoading = True

    def wallpaperInfoUpdated(self, isFullUpdate):
        if isFullUpdate:
            pass
            # wpsi = WallpaperServiceInfo()
            # makeListViewItem(wpsi.getLastUsedPaths())
        Gdk.threads_add_idle(GLib.PRIORITY_DEFAULT_IDLE, self.updateLayoutWithServiceInfo)

    def refreshThumbnail(self):
        if self._serviceRunning:
            wpsi = w.WallpaperServiceInfo()
            if wpsi.getThumbnail() != None:
                self._thumbnailImage.set_from_pixbuf(wpsi.getThumbnail())
                return
        self._thumbnailImage.set_from_file(self._icon)

    def refreshlastUsedPathsListView(self):
        pass

    def broadcastReceiver(self, thumbnail, currentWPath, pause):
        global _singleUI
        if _singleUI != None:
            self.wallpaperInfoUpdated(False)

    def thumbnailImageClicked(self, widget, event):
        BPUtil.BPLog("thumbnailImageClicked")
        wpsi = w.WallpaperServiceInfo()
        wpath = wpsi.getcurrentWPath()
        if wpath != None and wpath.path != None:
            if BPUtil.shiftKeyPressed(event):
                BPUtil.showImageFile(wpath.path)
            else:
                BPUtil.showImagePreview(wpath.path)

def showOptionWindow(isToggle = False):
    global _singleUI
    if _singleUI != None:
        if isToggle:
            if _singleUI._isHidden:
                _singleUI._optionWindow.show()
                _singleUI._optionWindow.present() # bring to front
            else:
                _singleUI._optionWindow.hide()
            _singleUI._isHidden = not _singleUI._isHidden
        else:
            _singleUI._optionWindow.show()
            _singleUI._isHidden = False

