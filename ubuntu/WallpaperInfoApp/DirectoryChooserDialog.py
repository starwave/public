#!/usr/bin/env python3

import gi

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

class DirectoryChooserDialog:

    def __init__(self):
        pass

    def directoryChooserDialog(self, parent, path):
        dlg=Gtk.FileChooserDialog ("Select Directory", parent,
            Gtk.FileChooserAction.SELECT_FOLDER,
            (Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OK, Gtk.ResponseType.OK))
        dlg.set_current_folder(path)
        folder = ""
        response = dlg.run()
        if response == Gtk.ResponseType.OK:
            folder = dlg.get_current_folder()
        elif response == Gtk.ResponseType.CANCEL:
            folder = ""
        dlg.destroy()
        return folder
