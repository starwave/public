#!/usr/bin/env python3

import WallpaperServiceHandler
import WallpaperServiceInfo as w
import WallpaperServiceConnection

class WallpaperServiceConnection:

	def __init__(self, wallpaperInfoUI):
		self._wallpaperInfoUI = wallpaperInfoUI
		self._wallpaperServiceHandler = None

	def sendMessageToService(self, command, intOption = 0, objectOption = None):
		if self._wallpaperServiceHandler != None:
			self._wallpaperServiceHandler.handleMessage(command, intOption, objectOption)

	def unbindService(self):
		self._wallpaperServiceHandler.unbind()
		self._wallpaperServiceHandler = None

def startService():
	WallpaperServiceHandler.startService()

def stopService():
	WallpaperServiceHandler.stopService()

def broadcastToService(action, extra = 0):
	w.WallpaperServiceInfo().getWallpaperService().broadcastReceiver(action, extra)

def bindService(wallpaperInfoUI):
	wallpaperServiceConnection = WallpaperServiceConnection(wallpaperInfoUI)
	wallpaperServiceConnection._wallpaperServiceHandler = WallpaperServiceHandler.incomingHandler(wallpaperServiceConnection)
	return wallpaperServiceConnection