#!/usr/bin/env python3

from enum import IntEnum
import WPath
import AppUtil
from datetime import date

class Theme(IntEnum):

    default1 = 0
    default2 = 1
    custom = 2
    photo = 3
    recent = 4
    wallpaper = 5
    landscape = 6
    movie1 = 7
    movie2 = 8
    special1 = 9
    special2 = 10
    all = 11

    def stringValue(self):
        stringValues = [
            "default1",
            "default2",
            "custom",
            "photo",
            "recent",
            "wallpaper",
            "landscape",
            "movie1",
            "movie2",
            "special1",
            "special2",
            "all"
        ]
        return stringValues[self]

    def label(self):
        labels = [
            "Default",
            "Default+",
            "Custom",
            "Photo",
            "Recent",
            "Wallpaper",
            "Landscape",
            "Movie",
            "* Movie+ *",
            "* Special *",
            "* Special+ *",
            "* All *"
        ]
        return labels[self]

class ThemeInfo:

    def __init__(self, theme, root, allow, filter):
        self._theme = theme
        self._root = root
        self._allow = allow
        self._filter = filter
        self.prepareTheme()

    def isThemeImage(self, coden):
        if coden == None:
            return False
        # It must begins with root
        underRoot = False
        for root in self._rootsArray:
            if coden.startswith(root):
                underRoot = True
                break
        if not underRoot:
            return False
        # for case insensitive match
        codenLowercase = coden.lower()
        # It must contains any of allow words unless allow is empty
        if self._allow != "":
            allowed = False
            for word in self._allowWords:
                if word in codenLowercase:
                    allowed = True
                    break
            if not allowed:
                return False
        # It must not contain any of filter words
        for word in self._filterWords:
            if word in codenLowercase:
                return False
        return True

    def classifyPathsByTheme(self, source, theme, untheme):
        for path, exif in source.items():
            wpath = WPath.WPath(path, exif)
            if self.isThemeImage(wpath.coden()):
                theme[path] = exif
            else:
                untheme[path] = exif

    def getOption(self):
        option = ""
        if self._theme == Theme.custom :
            option = " -r '" + self._root + "' -a '" + self._allow + "' -f '" + self._filter + "'"
        return option

    def equals(self, themeInfo):
        if themeInfo._theme == self._theme:
            if self._theme == Theme.custom:
                if themeInfo.getOption() == self.getOption():
                    return True
                else:
                    return False
            else:
                return True
        return False

    def prepareTheme(self):
        self._rootsArray = AppUtil.getWordsArray(self._root)
        self._allowWords = AppUtil.getWordsArray(self._allow.lower())
        self._filterWords = AppUtil.getWordsArray(self._filter.lower())

    def getNextThemeInfo(self):
        if self._theme == _themes[len(_themes) - 1]._theme:
            return _themes[ThemeInfo._themes[0]._theme]
        return _themes[self._theme + 1]
        
    def getPrevousThemeInfo(self):
        if self._theme == _themes[0]._theme:
            return _themes[_themes[len(_themes) - 1]._theme]
        return _themes[self._theme - 1]

def getThemeInfo(theme):
    return _themes[theme]

def getLabels():
    labels = []
    for theme in _themes:
       labels.append(theme._theme.label())
    return labels

def setCustomConfigDetail(root, allow, filter):
    global _themes
    _themes[Theme.custom]._root = root
    _themes[Theme.custom]._allow = allow
    _themes[Theme.custom]._filter = filter
    _themes[Theme.custom].prepareTheme()
    return _themes[Theme.custom]

def parseCustomConfig(customConfigString):
    configWords = customConfigString.split(';')
    root = configWords[0] if len(configWords) > 0 and customConfigString != "" else _default_custom_root
    allow = configWords[1] if len(configWords) > 1 and customConfigString != "" else _default_custom_allow
    filter = configWords[2] if len(configWords) > 2 and customConfigString != "" else _default_custom_filter
    return ThemeInfo(Theme.custom, root, allow, filter)

def setCustomConfig(customConfigString):
    wpti = parseCustomConfig(customConfigString)
    return setCustomConfigDetail(wpti._root, wpti._allow, wpti._filter)

def getRecentYears():
    year = date.today().year
    recentyears = f"/BP Photo/{year - 4:d}/|/BP Photo/{year - 3:d}/|" + \
        f"/BP Photo/{year - 2:d}/|/BP Photo/{year - 1:d}/|/BP Photo/{year:d}/"
    return recentyears

_default_custom_root = "/"
_default_custom_allow = ""
_default_custom_filter = "#nd#|#sn#"

_themes = [
        ThemeInfo(Theme.default1,
                "/", "", "#nd#|#sn#|/People/"),
        ThemeInfo(Theme.default2,
                "/", "", "#nd#|#sn#" ),
        ThemeInfo(Theme.custom,
                _default_custom_root, _default_custom_allow, _default_custom_filter ),
        ThemeInfo(Theme.photo,
                "/BP Photo/", "", "#nd#|#sn#" ),
        ThemeInfo(Theme.recent,
                getRecentYears(), "", "#nd#|#sn#" ),
        ThemeInfo(Theme.wallpaper,
                "/BP Wallpaper/", "", "#nd#|#sn#" ),
        ThemeInfo(Theme.landscape,
                "/BP Wallpaper/", "/Landscapes/|/Nature/|/USA/|/Architecture/|/Korea/", "#nd#|#sn#" ),
        ThemeInfo(Theme.movie1,
                "/BP Wallpaper/", "/Animations/|/Movies/|/TVShow/", "#nd#|#sn#" ),
        ThemeInfo(Theme.movie2,
                "/BP Wallpaper/", "/Animations/|/Movies/|/TVShow/|/Performance/", "" ),
        ThemeInfo(Theme.special1,
                "/BP Wallpaper/", "#nd#|#sn#", "/Animations|Anime/" ),
        ThemeInfo(Theme.special2,
                "/", "/People/|#nd#|#sn#", "" ),
        ThemeInfo(Theme.all,
                "/", "", "")
        ]

#print(Theme.special1.stringValue())
#print(Theme.all.label())
#themeInfo = getThemeInfo(Theme.photo)
#print(getLabels())

