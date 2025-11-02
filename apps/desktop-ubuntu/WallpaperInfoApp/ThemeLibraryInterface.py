#!/usr/bin/env python3

import os.path
import urllib.request, urllib.parse
import threading
import json
from json import JSONEncoder
from types import SimpleNamespace

import BPUtil
import PlatformInfo
import BPAsset

class ThemeLibraryInterface:

    def __init__(self):
        self._lock = PlatformInfo.BPLock()

    def requestUpdateThemeLibrary(self, label, config, callback):
        self._lock.acquire()
        try:
            option = "a=u&l=" + urllib.parse.quote(label) + "&c=" + urllib.parse.quote(config)
            self._updateThemeCallback = callback
            self.maramboi(option, self.requestUpdateThemeLibraryCallback)
            self._lock.release()
            return True
        except Exception as error:
            BPUtil.BPLog("Error in requestUpdateThemeLibrary: ", str(error))
        self._lock.release()
        return False
    
    def requestUpdateThemeLibraryCallback(self, response):
        BPUtil.storeStringToFile(_themeJsonPath, response)
        self._updateThemeCallback(response)

    def getThemeLibrary(self, callback):
        self._lock.acquire()
        option = "a=g"
        self._getThemeCallback = callback
        self.maramboi(option, self.getThemeLibraryCallback)
        if not BPUtil.fileExists(_themeJsonPath):
            if self.copyAssetFile("themelib", _themeJsonPath):
                contents = BPUtil.getStringFromFile(_themeJsonPath)
                if contents != "":
                    BPUtil.storeStringToFile(_themeJsonPath, contents)
            else:
                BPUtil.BPLog("Error: getThemeLibrary - copying asset themeLib.txt file")
                contents = ""
        else:
            contents = BPUtil.getStringFromFile(_themeJsonPath)
        self._lock.release()
        return contents

    def getThemeLibraryCallback(self, response):
        BPUtil.storeStringToFile(_themeJsonPath, response)
        self._getThemeCallback(response)

    def getReservedWords(self, callback):
        self._lock.acquire()
        option = "a=r"
        self._getReservedCallback = callback
        self.maramboi(option, self.getReservedWordsCallback)
        if not BPUtil.fileExists(_reservedJsonPath):
            if self.copyAssetFile("reservedword", _reservedJsonPath):
                contents = BPUtil.getStringFromFile(_reservedJsonPath)
                if contents != "":
                    BPUtil.storeStringToFile(_reservedJsonPath, contents)
            else:
                BPUtil.BPLog("Error: getReservedWords - copying asset reservedword.txt file")
                contents = ""
        else:
            contents = BPUtil.getStringFromFile(_reservedJsonPath)
        self._lock.release()
        return contents

    def getReservedWordsCallback(self, response):
        BPUtil.storeStringToFile(_reservedJsonPath, response)
        self._getReservedCallback(response)

    def updateThemeLibLocalFileFromList(self, parsedThemeLib):
        try:
            contents = json.dumps(parsedThemeLib, indent = 4, cls=ThemeLibEncoder)
            BPUtil.storeStringToFile(_themeJsonPath, contents)
        except Exception as error:
            BPUtil.BPLog("Error in updateThemeLibLocalFileFromList : " , str(error))

    def copyAssetFile(self, assetName, fileName):
        try:
            asset = BPAsset.BPAsset()
            contents = asset._resource[assetName]
            BPUtil.storeStringToFile(fileName, contents)
            return True
        except Exception as error:
            BPUtil.BPLog("Error in copying asset " + assetName + " file : " , str(error))
        return False

    def parseThemeLib(self, themeLibString):
        try:
            return json.loads(themeLibString, object_hook=lambda d: SimpleNamespace(**d))
        except Exception as error:
            BPUtil.BPLog("Error in parsing json from themelib.txt file. : " , str(error))
        return json.loads("")

    def parseReservedWord(self, reservedWordString):
        try:
            return json.loads(reservedWordString, object_hook=lambda d: SimpleNamespace(**d))
        except Exception as error:
                BPUtil.BPLog("Error in parsing json from reservedword.txt file. : ", str(error))
        return json.loads("")

    def maramboi(self, option, callback):
        url = "http://" + _host + ":8080/maramboi?" + option
        thread = threading.Thread(target=self.maramboi_internal, args=(url, callback))
        thread.start()

    def maramboi_internal(self, url, callback):
        try:
            f = urllib.request.urlopen(url)
            response = f.read().decode('utf-8').strip()
            callback(response)
        except Exception as error:
            BPUtil.BPLog("Error in maramboi: ", str(error))
    
_themeJsonPath = os.path.expanduser('~/Documents/') + ".themelib.txt"
_reservedJsonPath = os.path.expanduser('~/Documents/') + ".reservedword.txt"
_host = "192.168.1.111"

class ThemeLib:
    def __init__(self, label, config):
        self.Label = label
        self.Config = config

class ReservedWord:
    def __init__(self, word, wordPath):
        self.Word = word
        self.WordPath = wordPath

# make it ThemeLib serializable with Json
class ThemeLibEncoder(JSONEncoder):
        def default(self, o):
            return o.__dict__

"""
import time
class myTest:
    def __init__(self):
        self._lib = ThemeLibraryInterface()
    def myCallback1(self, msg):
        theme_json = self._lib.parseThemeLib(msg)
        print("theme", theme_json[0].Label)
        time.sleep(1)
        new_theme =  [{ 'Label': '* Fashion *', 'Config': '/BP Wallpaper/;#nd;' }]
        self._lib.updateThemeLibLocalFileFromList(new_theme)
    def myCallback2(self, msg):
        word_json = self._lib.parseReservedWord(msg)
        print("reserved", word_json[0].Word)
    def test(self):
        self._lib.getThemeLibrary(self.myCallback1)
        self._lib.getReservedWords(self.myCallback2)
my_test = myTest()
my_test.test()
"""
