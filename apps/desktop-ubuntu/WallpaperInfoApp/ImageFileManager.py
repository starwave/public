#!/usr/bin/env python3

from collections import OrderedDict
import random
#import os.path
import os
from threading import Thread
from threading import Timer

import WallpaperServiceInfo as w
import WallpaperService
import WPath
import BPUtil
import PlatformFileObserver
import PlatformInfo
import WallpaperWidgetProvider

class ImageFileManager:

    def __init__(self):
        self._lock = PlatformInfo.BPLock()
        self._fileObserver = None
        self._usingListCache = False
        self._writeInterrupt = False
        self._writeFileThread = None
        self.resetFiles()

    def resetFiles(self):
        self._lock.acquire()
        self._themeReady = False
        self._unclassifiedPaths = OrderedDict() # will be overriden
        self._wallpaperPaths = OrderedDict() # will be overriden
        self._themePaths = OrderedDict()
        self._unthemePaths = OrderedDict()
        self._usedPaths = OrderedDict()
        self._lastUsedPaths = OrderedDict()
        wpsi = w.WallpaperServiceInfo()
        wpsi.setLastUsedPaths(self._lastUsedPaths)
        self._lock.release()
        self.stopWatching()

    def stopWatching(self):
        self._writeInterrupt = True
        self.waitForListFileWriting()
        self._lock.acquire()
        if (self._fileObserver != None):
            self._fileObserver.stopWatching()
            self._fileObserver = None
        self._lock.release()

    def setSourceRootPath(self, sourceRootPath):
        self.resetFiles()
        self._writeInterrupt = False
        self._sourceRootPath = sourceRootPath
        if not BPUtil.fileExists(sourceRootPath):
            BPUtil.BPLog(sourceRootPath + "directory doesn't exist.")
            return
        if (self.readListCache()):
            self._lock.acquire()
            BPUtil.BPLog("ImageFileManager.readListCache.")
            WPath.WPath.setPlatformRootPath(list(self._unclassifiedPaths.keys())[0])
            self.classifySourceByTheme()
            self._lock.release()
            self._themeReady = True
        self._fileObserver = PlatformFileObserver.PlatformFileObserver(self._sourceRootPath, self)
        BPUtil.BPLog("ImageFileManager.setSourceRootPath at " + sourceRootPath)
        self._fileObserver.startWatching()

    def onEvent(self, event, wpath):
        if event == PlatformFileObserver.ADD:
            self.addWPath(wpath)
        elif event == PlatformFileObserver.REMOVE:
            self.removePath(wpath.path)
        else:
            return

    def fileWatchingStarted(self, sourcePaths):
        BPUtil.BPLog("ImageFileManager.fileWatchingStarted.")
        self._wallpaperPaths = sourcePaths
        self.writeListCache(self._wallpaperPaths, _wallpaperListCacheFile)
        self._lock.acquire()
        # compare count to determine to use it over cache list.
        if (len(self._wallpaperPaths) > self.getTotalImageCount()):
            self.replaceCacheWithRealPaths(self._wallpaperPaths)
        self._lock.release()
        
    def exifReadFinished(self, exifPaths):
        BPUtil.BPLog("ImageFileManager.exifReadFinished.")
        self._unclassifiedPaths = exifPaths
        self.writeListCache(self._unclassifiedPaths, _photoListCacheFile)
        self._lock.acquire()
        if (self._usingListCache):
            self.replaceCacheWithRealPaths(self._unclassifiedPaths, self._wallpaperPaths)
        else:
            self.classifySourceByTheme()
        self._lock.release()
		
    def getRandomPathFromSource(self):
        if self._themePaths == None or self._usedPaths == None:
            BPUtil.BPLog("_sourcePaths shouldn't be None.")
            return None
        self._lock.acquire()
        if len(self._themePaths) <= 0:
            # Rewind from the beginning
            self.rewindSource()
            if len(self._themePaths) <= 0:
                # when there is no images
                BPUtil.BPLog("There is no theme image in entire source.")
                self._lock.release()
                return None
        # pick new image path from source
        path = random.choice(list(self._themePaths.keys()))
        exif = self._themePaths[path]
        # remove from source path
        if path in self._themePaths:
            del self._themePaths[path]
        # (in case source is small) Check if new path is still in last used path, then remove it to avoid the loop.
        if path in self._lastUsedPaths:
            del self._lastUsedPaths[path]
        # add to last used path
        self._lastUsedPaths[path]= exif
        # mainatain size for self._lastUsedPaths
        if len(self._lastUsedPaths) > WallpaperService._maxLastUsedPaths:
            self._lastUsedPaths.popitem(last=False)
        # add to used path
        self._usedPaths[path] = exif
        self._lock.release()
        return WPath.WPath(path, exif)
            
    def retrievePathFromSource(self, pivotWPath, offset):
        if pivotWPath == None:
            return self.getRandomPathFromSource()
        if (self._lastUsedPaths == None):
            BPUtil.BPLog("self._lastUsedPaths shouldn't be None.")
            return None
        self._lock.acquire()
        index = list(self._lastUsedPaths.keys()).index(pivotWPath.path)
        if index < 0:                                      # No matching image
            if offset == -1:
                BPUtil.BPLog("shouldn't happen when no index but offset is -1")
                wpath = self.getRandomPathFromSource()
        elif index + offset < 0:                           # get previous at the first
            path = list(self._lastUsedPaths.keys())[0]
            wpath = WPath.WPath(path, self._lastUsedPaths[path])
        elif index + offset < len(self._lastUsedPaths):    # get within the range
            path = list(self._lastUsedPaths.keys())[index + offset]
            wpath = WPath.WPath(path, self._lastUsedPaths[path])
        else:
            self._lock.release()
            return self.getRandomPathFromSource() # get next at the last
        self._lock.release()
        return wpath                 

    def addWPath(self, wpath):
        if (self._themePaths == None):
            BPUtil.BPLog("_sourcePaths shouldn't be None.")
            return
        self._lock.acquire()
        wpsi = w.WallpaperServiceInfo()
        themeInfo = wpsi.getThemeInfo()
        if themeInfo.isThemeImage(wpath.coden()):
            self._themePaths[wpath.path] = wpath.exif
        else:
            self._unthemePaths[wpath.path] = wpath.exif
        self._lock.release()
				            		
    def removePath(self, path):
        if self._themePaths == None or self._usedPaths == None:
            BPUtil.BPLog("_sourcePaths shouldn't be None.")
            return
        self._lock.acquire()
        if path in self._lastUsedPaths:
            del self._lastUsedPaths[path]
        if path in self._themePaths:
            del self._themePaths[path]
        if path in self._unthemePaths:
            del self._unthemePaths[path]
        if path in self._usedPaths:
            del self._usedPaths[path]
        self._lock.release()
            		
    def classifySourceByTheme(self):
        wpsi = w.WallpaperServiceInfo()
        wpsi.getThemeInfo().classifyPathsByTheme( \
                self._unclassifiedPaths, \
                self._themePaths, \
                self._unthemePaths)
		
    def rewindSource(self):
        self._themeReady = False
        BPUtil.BPLog("rewindSource is called.")
        self._unclassifiedPaths = self._usedPaths
        self._usedPaths = OrderedDict()
        self.classifySourceByTheme()
        self._themeReady = True
		
    def prepareSourceForTheme(self):
        self._themeReady = False
        requestedThemeInfo = w.WallpaperServiceInfo().getThemeInfo()
        BPUtil.BPLog("prepareSourceForTheme is called with " + requestedThemeInfo._theme.stringValue())
        timer = Timer(1.1, self.prepareSourceForThemeInternal, [requestedThemeInfo])
        timer.start()
        
    def prepareSourceForThemeInternal(self, requestedThemeInfo):
        if (requestedThemeInfo.equals(w.WallpaperServiceInfo().getThemeInfo())):
            self._lock.acquire()
            self._unclassifiedPaths = self._themePaths
            backupPaths = self._unthemePaths
            self._themePaths = OrderedDict()
            self._unthemePaths = OrderedDict()
            self.classifySourceByTheme()
            self._unclassifiedPaths = backupPaths
            self.classifySourceByTheme()
            self._lock.release()
            self._themeReady = True
        BPUtil.BPLog("prepareSourceForTheme is done with " + requestedThemeInfo._theme.stringValue())
 
    def isThemeReady(self):
        return self._themeReady
		
    def getImageStat(self, path):
        self._lock.acquire()
        index = len(self._usedPaths) + len(self._unthemePaths)
        i = list(self._lastUsedPaths.keys()).index(path)
        if (i >= 0): # current image is in the mid offset
            index = index - len(self._lastUsedPaths) + i
            stat = str(index + 1) + " of " + str(self.getTotalImageCount())
        self._lock.release()
        return stat

    def getTotalImageCount(self):
        total = len(self._usedPaths) + len(self._themePaths) + len(self._unthemePaths)
        return total

    def readListCache(self):
        self._usingListCache = False
        self._unclassifiedPaths.clear()
        if (BPUtil.fileExists(_wallpaperListCacheFile)):
            self.waitForListFileWriting()
            with open(_wallpaperListCacheFile, mode = 'r', encoding = "utf-8") as f:
                path = f.readline().strip()
                if (path == self._sourceRootPath):
                    for line in f:
                        path_exif = line.strip().split('\t')
                        self._unclassifiedPaths[path_exif[0]] = ""
        if (BPUtil.fileExists(_photoListCacheFile)):
            self.waitForListFileWriting()
            with open(_photoListCacheFile, mode = 'r', encoding = "utf-8") as f:
                path = f.readline().strip()
                if (path == self._sourceRootPath):
                    for line in f:
                        path_exif = line.strip().split('\t')
                        exif =  path_exif[1] if len(path_exif) > 1 else ""
                        self._unclassifiedPaths[path_exif[0]] = exif
        self._usingListCache = len(self._unclassifiedPaths) > 0
        return self._usingListCache

    # None to delete
    def writeListCache(self, paths, listCacheFile):
        if (paths != None):
            self.waitForListFileWriting()
            self._writeFileThread = Thread(target = self.writeListCacheInternal, args = (paths, listCacheFile))
            self._writeFileThread.start()

    def writeListCacheInternal(self, paths, listCacheFile):
        BPUtil.BPLog("writeListCache", listCacheFile, "started")
        with open(listCacheFile + ".tmp", mode = 'w', encoding = "utf-8") as f:
            f.write(self._sourceRootPath + "\n")
            for key, value in paths.items():
                if (self._writeInterrupt):
                    BPUtil.BPLog("writeListCache is interrupted for", listCacheFile)
                    break
                wpath = WPath.WPath(key, value)
                f.write(wpath.path + "\t" + wpath.exif + "\n")
        if not self._writeInterrupt:
            if (BPUtil.fileExists(listCacheFile)):
                os.remove(listCacheFile)
            os.rename(listCacheFile + ".tmp", listCacheFile)
        else:
            os.remove(listCacheFile + ".tmp")
        BPUtil.BPLog("writeListCache", listCacheFile, "ended" )

    def waitForListFileWriting(self):
        if (self._writeFileThread != None) :
            BPUtil.BPLog("waitForListFileWriting started")
            self._writeFileThread.join()
            BPUtil.BPLog("waitForListFileWriting ended")

    def replaceCacheWithRealPaths(self, realPaths, realPaths2 = None):
        self._themeReady = False
        self._unclassifiedPaths = realPaths
        self._themePaths.clear()
        self._unthemePaths.clear()
        self.classifySourceByTheme()
        if realPaths2 != None:
            self._unclassifiedPaths = realPaths2
            self.classifySourceByTheme()
        for key, _ in self._usedPaths.items():
            # remove from _themePaths which was already used from cache
            # python must check key exists before del
            if key in self._themePaths:
                del self._themePaths[key]
        self._usingListCache = False
        self._themeReady = True
        WallpaperWidgetProvider.updateLabelWidget("Image list is updated.")

_wallpaperListCacheFile = ".wallpaper_list.txt"
_photoListCacheFile = ".photo_list.txt"

def getDefaultRootPath():
    return os.path.expanduser('~/Pictures') 
