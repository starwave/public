#!/usr/bin/env python3

import BPUtil
import re

class WPath:

    _platformRootPath = ""

    def __init__(self, *args):
        if len(args) == 1:
            self.path = args[0]
            self.exif = BPUtil.getExifDescription(args[0])
        elif len(args) == 2:
            self.path = args[0]
            self.exif = args[1]

    def coden(self):
        coden = re.sub(WPath._platformRootPath, "", self.path)
        if self.exif != "":
            extension = coden[coden.rfind("."):]
            return re.sub(extension, "", coden)+"%" + self.exif + extension
        return coden

    def label(self):
        _maxImageDescriptionLength = 63
        label = ""
        rawImageName = BPUtil.getOnlyFileName(self.path)
        imageName = re.sub("^[0-9]{8}_[0-9]{6}@", "", rawImageName)
        if (self.exif != ""):
            label = BPUtil.getFolderName(self.path) + " / #" + self.exif + " | " + imageName
        else:
            label = BPUtil.getFolderName(self.path) + " / " + imageName;
        label = re.sub("#nd#", "!", re.sub("#sn#", "~", label));
        return BPUtil.abbreviate(label, _maxImageDescriptionLength)
    
    def equals(self, wpath):
        if wpath != None and self.path == wpath.path and self.exif == wpath.exif:
            return True
        else:
            return False

    @staticmethod
    def setPlatformRootPath(path):
        WPath._platformRootPath = ""
        index = path.find("/BP Wallpaper/")
        if index >= 0:
            WPath._platformRootPath = path[:index]
        else:
            index = path.find("/BP Photo/")
            if index >= 0:
                WPath._platformRootPath = path[:index]
        return WPath._platformRootPath

#path = "/home/starwave/CloudStation/BP Photo/1997/19970719_134622-C.jpg"
#path = "/home/starwave/CloudStation/BP Photo/2022/20220103_095802.jpg"
#path = "/home/starwave/CloudStation/BP Wallpaper/Animations/Cars (10).jpg"
#wpath = WPath(path)
#print(wpath.label())
#print(WPath.setPlatformRootPath(path))
#print(wpath.coden())
