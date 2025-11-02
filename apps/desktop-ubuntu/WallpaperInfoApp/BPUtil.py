#!/usr/bin/env python3

import os
import subprocess
from pathlib import Path
from datetime import datetime
from Exif import get_with_piexif

import gi
gi.require_version('Gdk', '3.0')
from gi.repository import Gdk

import PlatformInfo
def getExifDescription(path):
    exif = get_with_piexif(path)
    return exif

def getOnlyFileName(path):
    if path == None:
        return ""
    return Path(path).stem

def getFolderName(path):
    if path == None:
        return ""
    fullpath = Path(path)
    return os.path.basename(fullpath.parent.absolute())

def abbreviate(s, n):
    if len(s) <= n:
        return s
    n2 = int((n - 3) / 2)
    n1 = n - 3 - n2
    return '{0}...{1}'.format(s[:n1], s[-n2:])

def fileExists(path):
    return os.path.exists(path);

def BPLog(*argv):
    now = datetime.now()
    dt_string = now.strftime("%Y/%m/%d %H:%M:%S")
    logs = ", ".join(argv)
    print(dt_string, logs)
    file = open(getHomeDirectory() + "/logs/WallpaperInfoApp.log", 'a')
    file.write(dt_string + " " + logs + "\n")
    file.close()

_fileLock = PlatformInfo.BPLock()

def getStringFromFile(filePath):
    global _fileLock
    _fileLock.acquire()
    try:
        text_file = open(filePath, "r")
        data = text_file.read()
        text_file.close()
    except Exception as error:
        BPLog("Error in getStringFromFile: ", str(error))
        data =""
    _fileLock.release()
    return data

def storeStringToFile(filePath, contents):
    global _fileLock
    _fileLock.acquire()
    result = False
    try:
        text_file = open(filePath, "w")
        n = text_file.write(contents)
        text_file.close()
        result = True
    except Exception as error:
        BPLog("Error in storeStringToFile: ", str(error))
    _fileLock.release()
    return result

def getHomeDirectory():
    return os.path.expanduser('~')

def showImageFile(path):
    BPLog("nautilus", path)
    subprocess.run(['nautilus', path], stdout=subprocess.PIPE)

def showImagePreview(path):
    BPLog("xdg-open", path)
    subprocess.Popen(["xdg-open", path])

def altKeyPressed(event):
    return event.state & Gdk.ModifierType.MOD1_MASK

def shiftKeyPressed(event):
    return event.state & Gdk.ModifierType.SHIFT_MASK

def bashCommand(cmd):
    parms = cmd.split(" ")
    output = subprocess.run(parms, stdout=subprocess.PIPE)
    result = output.stdout.decode('utf-8').strip()
    """
    ps = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    result = ps.stdout.read().decode('utf-8').strip()
    ps.stdout.close()
    ps.wait()
    """
    return result

#print(get_screen_info(0))
#print(get_screen_info(1))
#print(get_screen_info(None))
#path = "/home/starwave/CloudStation/BP Photo/1997/19970719_134622-C.jpg" # utf-8 encoding
#path = "/home/starwave/CloudStation/BP Photo/2019/20190205_210616.jpg"  # failed with exifread
#path = "/home/starwave/Downloads/Work/BP Photo/2019/20190328_183016.jpg" # no imagedescription error
#exif = getExifDescription(path)