#!/usr/bin/env python3

import configparser
import ImageFileManager
import BPUtil
import ThemeInfo as t
import WallpaperServiceInfo as w

_config_name = ".wallpaperinfoapp.cfg"

def getPreference(wpsi):
    config = configparser.ConfigParser()
    if BPUtil.fileExists(_config_name):
        config.read(_config_name)
    else:
        config = createPreference()
    wpsi._sourceRootPath = config["default"]["root_path"]
    wpsi._theme = int(config["default"]["theme"])
    root = config["default"]["custom_root"]
    allow = config["default"]["custom_allow"]
    filter = config["default"]["custom_filter"]
    wpsi._customThemeInfo = t.ThemeInfo(t.Theme.custom, root, allow, filter)
    wpsi._pause = True if config["default"]["pause"]=="True" else False
    wpsi._interval = int(config["default"]["interval"])

def setPreference(key, value):
    config = configparser.ConfigParser()
    if BPUtil.fileExists(_config_name):
        config.read(_config_name)
    else:
        config = createPreference()
    config['default'][key] = value
    with open(_config_name, 'w') as config_file:
        config.write(config_file)

def createPreference():
    config = configparser.ConfigParser()
    config['default'] = {'root_path': ImageFileManager.getDefaultRootPath(),
                        'theme': str(int(t.Theme.default2)),
                        'custom_root': '/',
                        'custom_allow': '',
                        'custom_filter': '#nd#|#sn#',
                        'pause': str(False),
                        'interval': "7"
                        }
    with open(_config_name, 'w') as config_file:
        config.write(config_file)
    return config

"""
setPreference("interval", "11")
setPreference("interval", str(True))
"""