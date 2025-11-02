#!/usr/bin/env python3

from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from collections import OrderedDict
from threading import Thread

import os

import BPUtil
import WPath as w

ADD = 0x00000180 # MOVED_TO | CREATE
REMOVE = 0x00000240 # MOVED_FROM | DELETE

class PlatformFileObserver():

    def __init__(self, path, callback):
        self._observer = Observer()
        self._sourcePaths = OrderedDict()
        self._exifPaths = OrderedDict()
        self._sourceRootPath = path
        self._interrupt = True
        self._callback = callback
        
    def startWatching(self):
        if self._callback == None:
            BPUtil.BPLog("startWatching Error: Callback is None") 
            return
        self._interrupt = False
        thread = Thread(target = self.startWatchingInternal, args = ())
        thread.start()

    def startWatchingInternal(self):
        for r, d, f in os.walk(self._sourceRootPath):
            for file in f:
                if file.lower().endswith(".jpg"):
                    fullpath = os.path.join(r, file)
                    if "/BP Photo/" in fullpath:
                        self._exifPaths[fullpath] = ""
                    else:
                        self._sourcePaths[fullpath] = ""
        self._event_handler = FileEventHandler(self)
        self._observer.schedule(self._event_handler, self._sourceRootPath, recursive=True)
        self._observer.start()
        if len(self._sourcePaths) > 0:
            w.WPath.setPlatformRootPath(list(self._sourcePaths)[0])
        self._callback.fileWatchingStarted(self._sourcePaths)
        self.exifReadStart()

    def stopWatching(self):
        self._interrupt = True
        self._observer.stop()
        self._observer.join()

    def addPathInternal(self, path):
        if not path.lower().endswith(".jpg"):
            return
        exif = ""
        if "/BP Photo/" in path:
            exif = self.getExifFromPath(path)
        self._callback.onEvent(ADD, w.WPath(path, exif))

    def deletePathInternal(self, path):
        self._callback.onEvent(REMOVE, w.WPath(path, ""))
    
    def exifReadStart(self):
        for path in self._exifPaths:
            if self._interrupt:
                BPUtil.BPLog("exifReadStart is interrupted.") 
                return  # must return without calling callback since it's not complete scan
            exif = self.getExifFromPath(path)
            self._exifPaths[path] = exif
        if len(self._sourcePaths) == 0 and len(self._exifPaths) > 0:
            w.WPath.setPlatformRootPath(list(self._exifPaths)[0])
        self._callback.exifReadFinished(self._exifPaths)
    
    def getExifFromPath(self, path):
        return BPUtil.getExifDescription(path)

class FileEventHandler(FileSystemEventHandler):

    def __init__(self, fileObserver):
        self._fileObserver = fileObserver
        self._addPathDict = OrderedDict()
    
    # if move in from outside of path, it's created
    # if move out to outside of path, it's deleted
    # only if move with path, it's moved
    def on_any_event(self, event):
        if event.is_directory:
            return
        elif event.src_path == None or not event.src_path.lower().endswith(".jpg"):
            return
        elif event.event_type == 'created':
            BPUtil.BPLog("File Change : CREATE % s" % event.src_path)
            self._addPathDict[event.src_path] = "CREATE"
        elif event.event_type == 'deleted':
            BPUtil.BPLog("File Change : DELETE % s" % event.src_path)
            self._fileObserver.deletePathInternal(event.src_path)
        elif event.event_type == 'moved':
            BPUtil.BPLog("File Change : MOVED_FROM % s" % event.src_path)
            BPUtil.BPLog("File Change : MOVED_TO % s" % event.dest_path)
            self._fileObserver.deletePathInternal(event.src_path)
            self._fileObserver.addPathInternal(event.dest_path)
        elif event.event_type == 'closed':
            # closed after created will be vaild timing for file add event
            BPUtil.BPLog("File Change : CLOSED % s" % event.src_path)
            if event.src_path in self._addPathDict:                
                BPUtil.BPLog("File Added : % s" % event.src_path)
                del self._addPathDict[event.src_path]
                self._fileObserver.addPathInternal(event.src_path)
            else:
                BPUtil.BPLog("File Access Ended % s" % event.src_path)
        else: # modified
            #BPUtil.BPLog("File Change : TYPE % s " % event.event_type)
            return

"""
import sys
import time
class MyCallback:
    def onEvent(self, event, wpath):
        print("onEvent", event, wpath.path, wpath.exif)
    def fileWatchingStarted(self, sourcePaths):
        print("fileWatchingStarted")
        for path in sourcePaths:
            print(path)
    def exifReadFinished(self, exifPath):
        print("exifReadFinished")
        for path in exifPath:
            print(path)
try:
    myCallback = MyCallback()
    myobserver = PlatformFileObserver("/home/starwave/Downloads/Work", myCallback)
    myobserver.startWatching()
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    myobserver.stopWatching()
"""