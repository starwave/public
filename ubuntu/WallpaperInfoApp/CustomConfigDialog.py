#!/usr/bin/env python3

import gi
import copy
from operator import itemgetter, attrgetter, methodcaller

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk
gi.require_version('Gdk', '3.0')
from gi.repository import Gdk
from gi.repository import GLib

import ThemeLibraryInterface
import BPUtil
import PlatformInfo
import AppUtil
import ThemeInfo as t

_defaultCustomConfigString = "/;;#sn#|#nd#"
_trashcan =    u"\U0001F5D1"
_redcircle =   u"\U0001F534"
_bluecircle =  u"\U0001F535"
_greencircle = u"\U0001F7E2" # Not Working
_graycircle =  u"\U000026AA"
_openfolder =  u"\U0001F4C1"

def openCustomConfigDialog(optionWindow, currentCustomConfigString, callback):
    builder = Gtk.Builder()
    builder.add_from_file('WallpaperInfoApp.glade')
    customConfigDialog = CustomConfigDialog(optionWindow, builder, currentCustomConfigString)
    response = customConfigDialog._configDialog.run()
    if response == Gtk.ResponseType.OK:
        callback(customConfigDialog._customConfigString)
    elif response == Gtk.ResponseType.CANCEL:
        pass
    customConfigDialog._configDialog.destroy()

class CustomConfigDialog:
    def __init__(self, optionWindow, builder, currentCustomConfigString):
        self._handleThemeChange = False
        self._lock = PlatformInfo.BPLock()
        self._optionWindow = optionWindow
        self._currentCustomConfigString = currentCustomConfigString
        self._customConfigString = currentCustomConfigString
        self._themeLibraryInterface = ThemeLibraryInterface.ThemeLibraryInterface()
        self.initWithBuilder(builder)
        self._themeLibsList = []
        self._customWordsList = []
        self._reservedWordList = []

        # set up dialog
        self._configDialog.set_transient_for(optionWindow)
        self._configDialog.set_size_request(240,400)
        width, height = self._configDialog.get_size()
        o_width, o_height = optionWindow.get_size()
        o_x, o_y = optionWindow.get_position()
        self._configDialog.move(o_x + (o_width - width) / 2, o_y + (o_height - height) / 2)

        # get theme & reserved data - try local file first and from server
        self.getReservedWords()
        self.getThemeLibrary()

        # connect signals
        self._saveToLibraryButton.connect("clicked", self.saveToLibraryButtonClicked)
        self._addButton.connect("clicked", self.addButtonClicked)
        self._clearButton.connect("clicked", self.clearButtonClicked)
        self._okButton.connect("clicked", self.okButtonClicked)
        self._cancelButton.connect("clicked", self.cancelButtonClicked)
        self._themeLibsListView.connect("button-press-event", self.themeLibsListView_buttonpressed)
        self._customWordsListView.connect("button-press-event", self.customWordsListView_buttonpressed)

        # trigger onLoad
        Gdk.threads_add_idle(GLib.PRIORITY_DEFAULT_IDLE, self.onLoad, [])

    def initWithBuilder(self, builder):
        self._configDialog = builder.get_object("CustomConfigDialog")
        self._customConfigStringText = builder.get_object("newCustomConfigStringText")
        hbox = builder.get_object("box_config_list")
        self._saveToLibraryButton = builder.get_object("saveToLibraryButton")
        self._addButton = builder.get_object("addButton")
        self._clearButton = builder.get_object("clearButton")
        self._okButton = builder.get_object("okButton")
        self._cancelButton = builder.get_object("cancelButton")
        box_config_list = builder.get_object("box_config_list")

        self._popupMenu = builder.get_object("PopupMenu")
        for i, menuItemName in enumerate(["rootMenuItem", "allowMenuItem", "filterMenuItem", "reservedMenuItem"]):
            menuItem = builder.get_object(menuItemName)
            menuItem.name = str(i)
            menuItem.connect("activate", self.customWordsListView_wordTypeMenuItemClicked)

        self._themeLibsListView = Gtk.TreeView()
        tree_selection = self._themeLibsListView.get_selection()
        tree_selection.set_mode(Gtk.SelectionMode.SINGLE)
        tree_selection.connect("changed", self.themeLibsListView_SelectionChanged)
        self._themeLibsListStore = Gtk.ListStore(str, str, str)
        self._themeLibsListView.set_model(self._themeLibsListStore)
        for i, column_title in enumerate(["Theme", _trashcan]):
            renderer = Gtk.CellRendererText()
            column = Gtk.TreeViewColumn(column_title, renderer, text=i)
            column.set_sort_column_id(i)
            self._themeLibsListView.append_column(column)
        self._themeLibsListWindow = Gtk.ScrolledWindow()
        self._themeLibsListWindow.set_vexpand(True)
        self._themeLibsListWindow.add(self._themeLibsListView)

        self._customWordsListView = Gtk.TreeView()
        tree_selection = self._customWordsListView.get_selection()
        tree_selection.set_mode(Gtk.SelectionMode.SINGLE)
        self._customWordsListStore = Gtk.ListStore(str, str, str)
        self._customWordsListView.set_model(self._customWordsListStore)
        for i, column_title in enumerate([_graycircle, "Word", _trashcan]):
            renderer = Gtk.CellRendererText()
            column = Gtk.TreeViewColumn(column_title, renderer, text=i)
            column.set_sort_column_id(i)
            column.set_cell_data_func(renderer, self.customWordCellDataFunction, func_data=i)
            self._customWordsListView.append_column(column)
        self._customWordsListWindow = Gtk.ScrolledWindow()
        self._customWordsListWindow.set_vexpand(True)
        self._customWordsListWindow.add(self._customWordsListView)
        box_config_list.pack_start(self._themeLibsListWindow, True, True, 1)
        box_config_list.pack_end(self._customWordsListWindow, True, True, 1)
        box_config_list.show_all()

    def __del__(self):
        pass

    def onLoad(self, parm):
        self._customConfigStringText.set_text(self._currentCustomConfigString)

    def saveToLibraryButtonClicked(self, button):
        BPUtil.BPLog("CustomConfigDialog - saveToLibraryBtnClicked")
        currentRow = self.themeLibsListView_GetSelectedRow()
        if currentRow == 0 or currentRow == -1: # adding new theme library
            response = self.alertDialogWithNewText("New Theme Label")
            if response != None and response != "" :
                if self.requestUpdateThemeLibrary(response, self._customConfigString):
                    self._lock.acquire()
                    themeLibItem = ThemeLibraryInterface.ThemeLib(response, self._customConfigString)
                    self._themeLibsList.append(themeLibItem)
                    self.updateThemeLibLocalFileFromList()
                    self._lock.release()
                else:
                    self.errorAlert("Error", "Can't add new theme to the library.")
        else: # modifying existing theme libarary
            themeLibItem = self._themeLibsList[currentRow]
            if self.requestUpdateThemeLibrary(themeLibItem.Label, self._customConfigString):
                self._lock.acquire()
                themeLibItem.Config = self._customConfigString
                self.updateThemeLibLocalFileFromList()
                self._lock.release()
            else:
                self.errorAlert("Error", "Can't update selected theme to the library.")

    def addButtonClicked(self, button):
        BPUtil.BPLog("CustomConfigDialog - addButtonClicked")
        response = self.alertDialogWithNewText("New Word")
        if response != None and self.addCustomWord(response, 1):
            self.sortCustomWordList()
            self.updateCustomConfigStringFromList()
            self.customWordsListView_NotifyItemChanged()

    def clearButtonClicked(self, button):
        global _defaultCustomConfigString
        BPUtil.BPLog("CustomConfigDialog - clearButtonClicked")
        self._customConfigString = _defaultCustomConfigString
        self.themeLibsListView_SetSelectedRow(-1)
        self.themeLibsListView_HandleSelectionChanged(-1)

    def okButtonClicked(self, button):
        BPUtil.BPLog("CustomConfigDialog - okButtonClicked")
        self._configDialog.response(Gtk.ResponseType.OK)

    def cancelButtonClicked(self, button):
        BPUtil.BPLog("CustomConfigDialog - cancelButtonClicked")
        self._configDialog.response(Gtk.ResponseType.CANCEL)

    def themeLibsListView_HandleSelectionChanged(self, row):
        if row != None and row >= 0:
            config = self._themeLibsList[row].Config
            self.updateListFromCustomConfigString(config)
        else: # no selection update for clear button
            self.updateListFromCustomConfigString(self._customConfigString)
        self.updateCustomConfigStringFromList()

    def themeLibsListView_NotifyItemChanged(self):
        self._themeLibsListStore.clear()
        for themeLib in self._themeLibsList:
            self._themeLibsListStore.append([themeLib.Label, _trashcan, themeLib.Config])

    def customWordsListView_NotifyItemChanged(self):
        icon = [ _openfolder, _bluecircle, _redcircle, _graycircle]
        self._customWordsListStore.clear()
        for customWord in self._customWordsList:
            self._customWordsListStore.append(
                [icon[customWord.WordType],
                customWord.Word,
                _trashcan if customWord.WordType != 3 else " "
                ])

    # ListView Event Handler
    def themeLibsListView_SelectionChanged(self, tree_selection):
        if self._handleThemeChange:
            row = self.themeLibsListView_GetSelectedRow(tree_selection)
            if row >= 0:
                BPUtil.BPLog("ThemeLibsListView_SelectionChanged = " + str(row))
                self.themeLibsListView_HandleSelectionChanged(row)

    def themeLibsListView_GetSelectedRow(self, tree_selection = None):
        if tree_selection == None:
            tree_selection = self._themeLibsListView.get_selection()
        if tree_selection != None:
            model, iter = tree_selection.get_selected()
            if iter != None:
                path = tree_selection.get_selected_rows()
                if path != None and len(path) > 0 and path[1] != None and path[1][0] != None and path[1][0][0] != None:
                    return path[1][0][0]
        return -1

    def themeLibsListView_SetSelectedRow(self, row):
        if row >=0:
            self._themeLibsListView.set_cursor(row)
        else:
            self._themeLibsListView.get_selection().unselect_all()

    def themeLibsListView_buttonpressed(self, widget, event):
        path_info = widget.get_path_at_pos(event.x, event.y)
        if path_info != None:
            path, column, cellx, celly = path_info
            if path != None and column != None:
                row = int(path[0])
                col = column.get_sort_column_id()
                if (col == 1):
                    self.themeLibsListView_trashClicked(row)

    def themeLibsListView_trashClicked(self, row):
        if (row >= 0):
            self._handleThemeChange = False
            theme_label = self._themeLibsList[row].Label
            if self.requestUpdateThemeLibrary(theme_label, ""):
                # make sure lock stays until themeLibsListView_NotifyItemChanged
                self._lock.acquire()
                previousThemeLabel = ""
                selectedRow = self.themeLibsListView_GetSelectedRow()
                # unselect row if it's deleted
                if selectedRow == row:
                    self.themeLibsListView_SetSelectedRow(-1)
                else:
                    if selectedRow >= 0:
                        previousThemeLabel = self._themeLibsList[selectedRow].Label
                rowToDelete = next((i for i, item in enumerate(self._themeLibsList) if item.Label == theme_label), -1)
                if rowToDelete >= 0:
                    del self._themeLibsList[rowToDelete]
                    # move selected row in case it's affected by deletion
                    newSelectedRow = next((i for i, item in enumerate(self._themeLibsList) if item.Label == previousThemeLabel), -1)
                    self.themeLibsListView_NotifyItemChanged()
                    self._lock.release()
                    self._handleThemeChange = True
                    self.themeLibsListView_SetSelectedRow(newSelectedRow)
                    self.updateThemeLibLocalFileFromList()
                else: # should not be here
                    self._handleThemeChange = True
                    self._lock.release()

    def customWordsListView_buttonpressed(self, widget, event):
        path_info = widget.get_path_at_pos(event.x, event.y)
        if path_info != None:
            path, column, cellx, celly = path_info
            if path != None and column != None:
                row = int(path[0])
                col = column.get_sort_column_id()
                if col == 2:
                    self.customWordsListView_trashClicked(row)
                elif col == 0:
                    self.customWordsListView_wordTypeClicked(row, event)

    def customWordsListView_wordTypeClicked(self, row, event):
        BPUtil.BPLog("customWordsListView_wordTypeClicked")
        self._selectedWord = row
        self._popupMenu.popup(None, None, None, None, event.button, event.time)

    def customWordsListView_wordTypeMenuItemClicked(self, *args):
        menuitem = args[0]
        row = self._selectedWord
        word = self._customWordsList[row].Word
        wordType = int(menuitem.name)
        BPUtil.BPLog("customWordsListView_wordTypeMenuItemClicked:" + word + "," + str(wordType))
        if wordType == 0:
            reservedIndex = next((i for i, item in enumerate(self._reservedWordList) if item.Word == word), -1)
            if reservedIndex >= 0:
                if self._reservedWordList[reservedIndex].WordPath != "":
                    newCustomWordItem = CustomWord(self._reservedWordList[reservedIndex].WordPath, 0)
                    self._customWordsList.append(newCustomWordItem)
            elif next((i for i, item in enumerate(self._reservedWordList) if item.WordPath == word), -1) >= 0:
                self._customWordsList[row].WordType = 0
            else:
                self.errorAlert("Error", "Selected word is not path.")
        elif wordType in [1, 2, 3]:
            self._customWordsList[row].WordType = wordType
        self.sortCustomWordList()
        self.customWordsListView_NotifyItemChanged()
        self.updateCustomConfigStringFromList()

    def customWordsListView_trashClicked(self, row):
        if row >= 0:
            word = self._customWordsList[row].Word
            BPUtil.BPLog("customWordsListView_trashClicked = " + word)
            if next((i for i, item in enumerate(self._reservedWordList) if item.Word == word), -1) >= 0:
                self._customWordsList[row].WordType = 3
                self.sortCustomWordList()
            else:
                del self._customWordsList[row]
            self.customWordsListView_NotifyItemChanged()
            self.updateCustomConfigStringFromList()

    # themeLib json <-> List
    def updateListFromThemeLibJsonString(self, themeLibString):
        self._lock.acquire()
        self._handleThemeChange = False
        previousThemeLabel = "Current"
        newSelectedRow = -1
        selectedRow = self.themeLibsListView_GetSelectedRow(self._themeLibsListView.get_selection())
        if selectedRow >= 0:
            previousThemeLabel = self._themeLibsList[selectedRow].Label
        if themeLibString != "":
            self._themeLibsList = self._themeLibraryInterface.parseThemeLib(themeLibString)
        currentThemeLib = ThemeLibraryInterface.ThemeLib("Current", self._currentCustomConfigString)
        self._themeLibsList.insert(0, currentThemeLib)
        i = 0
        for themeLib in self._themeLibsList:
            label = themeLib.Label
            if previousThemeLabel == label:
                newSelectedRow = i
            i += 1
        self.themeLibsListView_NotifyItemChanged()
        self._lock.release()
        self._handleThemeChange = True
        if (newSelectedRow >= 0): # it must
            self._themeLibsListView.set_cursor(newSelectedRow)

    def updateThemeLibLocalFileFromList(self):
        self._themeLibraryInterface.updateThemeLibLocalFileFromList(self._themeLibsList)

    # ThemeLibraryInterface Wrappers
    def requestUpdateThemeLibrary(self, label, config):
        self._lock.acquire()
        # this lock is important to prevent hang in some computer
        result = self._themeLibraryInterface.requestUpdateThemeLibrary(label, config, self.requestUpdateThemeLibraryCallback)
        self._lock.release()
        return result

    def requestUpdateThemeLibraryCallback(self, response):
        self.updateListFromThemeLibJsonString(response)

    def getThemeLibrary(self):
        themeLibData = self._themeLibraryInterface.getThemeLibrary(self.getThemeLibraryCallback)
        if (themeLibData != ""):
            self.updateListFromThemeLibJsonString(themeLibData)

    def getThemeLibraryCallback(self, msg):
        # must call on ui thread
        Gdk.threads_add_idle(GLib.PRIORITY_DEFAULT_IDLE, self.updateListFromThemeLibJsonString, msg)

    # CustomConfigString <-> List
    def updateListFromCustomConfigString(self, customConfigString):
        self._lock.acquire()
        self._customWordsList.clear()
        self._customConfigString = customConfigString
        reservedWords = copy.deepcopy(self._reservedWordList)
        wpti = t.parseCustomConfig(customConfigString)
        rootsArray = AppUtil.getWordsArray(wpti._root)
        allowWords = AppUtil.getWordsArray(wpti._allow)
        filterWords = AppUtil.getWordsArray(wpti._filter)
        for root in rootsArray:
            self.addCustomWord(root, 0)
            index = next((i for i, item in enumerate(reservedWords) if item.Word == root), -1)
            if (index >= 0):
                del reservedWords[index]
        for allow in allowWords:
            self.addCustomWord(allow, 1)
            index = next((i for i, item in enumerate(reservedWords) if item.Word == allow), -1)
            if (index >= 0):
                del reservedWords[index]
        for filter in filterWords:
            self.addCustomWord(filter, 2)
            index = next((i for i, item in enumerate(reservedWords) if item.Word == filter), -1)
            if (index >= 0):
                del reservedWords[index]
        for reservedWord in reservedWords:
            self.addCustomWord(reservedWord.Word, 3)
        self.sortCustomWordList()
        self.customWordsListView_NotifyItemChanged()
        self._lock.release()

    def updateCustomConfigStringFromList(self):
        self._lock.acquire()
        root = ""
        allow = ""
        filter = ""
        for customWordItem in self._customWordsList:
            if customWordItem.WordType == 0:
                root += customWordItem.Word + "|"
            elif customWordItem.WordType == 1:
                allow += customWordItem.Word + "|"
            elif customWordItem.WordType == 2:
                filter += customWordItem.Word + "|"
        # Remove the last bar if exists
        if len(root) > 0:
            root = root[:-1]
        if len(allow) > 0:
            allow = allow[:-1]
        if len(filter) > 0:
            filter = filter[:-1]
        self._customConfigString = root + ";" + allow + ";" + filter
        self._customConfigStringText.set_text(self._customConfigString)
        self._lock.release()

    # custom word utility methods
    def getReservedWords(self):
        reservedWordsData = self._themeLibraryInterface.getReservedWords(self.getReservedWordsCallback)
        if (reservedWordsData != ""):
            self.updateReservedWords(reservedWordsData)

    def getReservedWordsCallback(self, msg):
        # must call on ui thread
        Gdk.threads_add_idle(GLib.PRIORITY_DEFAULT_IDLE, self.updateReservedWords, msg)

    def updateReservedWords(self, reservedWordsData):
        self._reservedWordList = self._themeLibraryInterface.parseReservedWord(reservedWordsData)

    def sortCustomWordList(self):
        self._customWordsList.sort(key=attrgetter('WordType', 'Word'))

    def addCustomWord(self, newCustomWord, customType):
        if newCustomWord != None and newCustomWord != "":
            if "|" in newCustomWord or ";" in newCustomWord:
                self.errorAlert("Error", "Word can't include the bar (|) or semi-colon (;) character.")
                return False
            customWordItem = CustomWord(newCustomWord, customType)
            self._customWordsList.append(customWordItem)
            return True
        self.errorAlert("Error", "Invalid custom word.")
        return False

    def alertDialogWithNewText(self, message):
        dialog = EntryDialog(title = message,
            message_format = "Press OK or Enter after typed.",
            transient_for = self._optionWindow)
        response = dialog.run()
        dialog.destroy()
        return response

    def errorAlert(self, title, message):
        dialog = Gtk.MessageDialog(
            title = title,
            message_format = message,
            transient_for = self._configDialog)
        dialog.add_buttons(
            Gtk.STOCK_OK, Gtk.ResponseType.OK
        )
        dialog.show()
        response = dialog.run()
        dialog.destroy()
        return None

    # property: alignment, editable, cell-background, foreground, foreground_rgba
    # color : 'white', 'lightskyblue', red', 'lightgray', 'darkgray', 'black'
    def customWordCellDataFunction(self, col, cell, mdl, itr, i):
        # col = Columnn, cell = Cell, mdl = model, itr = iter, i = column number
        # column is provided by the function, but not used
        if i == 1:
            path = mdl.get_path(itr)
            if path != None and len(path) > 0:
                row = path[0]
                if row != None:
                    if self._customWordsList[row].WordType == 3:
                        cell.set_property('foreground', 'darkgray')
                    else:
                        cell.set_property('foreground', 'black')

# Const
_selectedRowColor = Gdk.RGBA(float(0xFF)/255.0, float(0xFC)/255.0, float(0x99)/255.0, 1.0)

class CustomWord:
    def __init__(self, word, wordType):
        self.Word = word
        self.WordType = wordType

class EntryDialog(Gtk.MessageDialog):
    def __init__(self, *args, **kwargs):
        # "default_value" to specify the initial contents of the entry.
        if 'default_value' in kwargs:
            default_value = kwargs['default_value']
            del kwargs['default_value']
        else:
            default_value = ''
        super(EntryDialog, self).__init__(*args, **kwargs)
        entry = Gtk.Entry()
        entry.set_text(str(default_value))
        entry.connect("activate",
                      lambda ent, dlg, resp: dlg.response(resp),
                      self, Gtk.ResponseType.OK)
        self.vbox.pack_end(entry, True, True, 0)
        self.vbox.show_all()
        self.entry = entry
        self.add_button("_Ok", Gtk.ResponseType.OK)
        self.add_button("_Cacnel", Gtk.ResponseType.CANCEL)

    def set_value(self, text):
        self.entry.set_text(text)

    def run(self):
        result = super(EntryDialog, self).run()
        if result == Gtk.ResponseType.OK:
            text = self.entry.get_text()
        else:
            text = None
        return text
