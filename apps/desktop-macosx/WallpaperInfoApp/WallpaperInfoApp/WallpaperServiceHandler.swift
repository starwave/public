//
//  WallpaperServiceHandler.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/15/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import Cocoa

class WallpaperServiceHandler {
	
	static func incomingHandler(incomingMessenger: WallpaperServiceConnection) -> WallpaperServiceHandler {
		let wpsi = WallpaperServiceInfo.getInstance()
		wpsi.getWallpaperService()._wallpaperServiceHandler._incomingMessenger = incomingMessenger
		return wpsi.getWallpaperService()._wallpaperServiceHandler
	}
    
    static func startService() {
        WallpaperServiceInfo.getInstance().getWallpaperService().startService()
    }
    
    static func stopService() {
		WallpaperServiceInfo.getInstance().getWallpaperService().stopService()
    }
	
	func replyToClient(thumbnail:NSImage?, currentWPath:WPath?, pause:Bool) {
		if (_incomingMessenger != nil) {
			_incomingMessenger?._delegate.broadcastReceiver(thumbnail:thumbnail, currentWPath:currentWPath, pause:pause)
		}
	}
    
    func handleMessage(_ command:Int, _ intOption:Int, _ object:Any? = nil) {
		let wpsi = WallpaperServiceInfo.getInstance()
		switch command {
			case MSG.CUSTOM_CONFIG:
                BPUtil.BPLog("WallpaperServiceHandler - MSG.CONF_CUSTOM")
				let customConfigString = object as! String
				_service.updateServiceCustomConfig(customConfigString: customConfigString)
				_service.restartTimer()
			case MSG.SET_THEME:
                BPUtil.BPLog("WallpaperServiceHandler - MSG.SET_THEME")
				_service.updateServiceTheme(theme: Theme(rawValue: intOption)!)
				_service.restartTimer();
			case MSG.REQUEST_INFO:
                BPUtil.BPLog("WallpaperServiceHandler - MSG.REQUEST_INFO")
			case MSG.PAUSE:
                BPUtil.BPLog("WallpaperServiceHandler - MSG.PAUSE")
				wpsi.setPause(intOption == 1)
				_service.pause_resume_service()
			case MSG.PREVIOUS:
                BPUtil.BPLog("WallpaperServiceHandler - MSG.PREVIOUS")
				_service.restartTimer();
				_service.naviageWallpaper(offset: -1)
			case MSG.NEXT:
                BPUtil.BPLog("WallpaperServiceHandler - MSG.NEXT")
				_service.restartTimer();
				_service.naviageWallpaper(offset: 1)
			case MSG.SET_INTERVAL:
                BPUtil.BPLog("WallpaperServiceHandler - MSG.SET_INTERVAL")
				if (intOption > 0) {
					wpsi.setInterval(intOption)
					_service.setInterval(interval: intOption)
					_service.restartTimer()
				}
			case MSG.PREVIOUS_THEME:
                BPUtil.BPLog("WallpaperServiceHandler - MSG.PREVIOUS_THEME")
				_service.updateServiceThemeWithPrevious()
			case MSG.NEXT_THEME:
                BPUtil.BPLog("WallpaperServiceHandler - MSG.NEXT_THEME")
				_service.updateServiceThemeWithNext()
			case MSG.SET_MODE:
                BPUtil.BPLog("WallpaperServiceHandler - MSG.SET_MODE")
				wpsi.setMode(ServiceMode(rawValue: intOption)!)
			case MSG.SET_SAVER:
                BPUtil.BPLog("WallpaperServiceHandler - MSG.SET_SAVER")
				wpsi.setSaver((intOption == 1))
			case MSG.SET_SAVERTIME:
                BPUtil.BPLog("WallpaperServiceHandler - MSG.SET_SAVERTIME")
				wpsi.setSaverTime(intOption)
			case MSG.SET_ROOT:
                BPUtil.BPLog("WallpaperServiceHandler - MSG.SET_ROOT")
				let path = object as! String
				_service.setNewSourceRootPath(path)
			case MSG.ACTIVITY_REPORT:
                BPUtil.BPLog("WallpaperServiceHandler - MSG.ACTIVITY_REPORT")
			case MSG.SET_WALLPAPER:
                BPUtil.BPLog("WallpaperServiceHandler - MSG.SET_WALLPAPER")
			default:
                BPUtil.BPLog("WallpaperServiceHandler - Invalid Command Error")
		}
		// should be called at last to reflect pause informtion is updated
		_service.resetSaverTimer()
    }
	
	func unbind() {
		_incomingMessenger = nil
	}

	private var _incomingMessenger: WallpaperServiceConnection? = nil
	// must use lzay to avoid circular definition around WallpaperServiceInfo singleton
	lazy private var _service = WallpaperServiceInfo.getInstance().getWallpaperService()
}
