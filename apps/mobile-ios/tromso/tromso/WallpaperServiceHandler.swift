//
//  WallpaperServiceHandler.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/15/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import SwiftUI

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
    func handleMessage(_ command:Int, _ intOption:Int, _ object:Any? = nil) {
		let wpsi = WallpaperServiceInfo.getInstance()
		switch command {
			case MSG.CUSTOM_CONFIG:
				print("WallpaperServiceHandler - MSG.CUSTOM_CONFIG")
				let customConfigString = object as! String
				_service.updateServiceCustomConfig(customConfigString: customConfigString)
				_service.restartTimer()
			case MSG.SET_THEME:
				print("WallpaperServiceHandler - MSG.SET_THEME")
				_service.updateServiceTheme(theme: Theme(rawValue: intOption)!)
				_service.restartTimer()
			case MSG.REQUEST_INFO:
				print("WallpaperServiceHandler - MSG.REQUEST_INFO")
			case MSG.PAUSE:
				print("WallpaperServiceHandler - MSG.PAUSE")
				wpsi.setPause((intOption == 1))
				_service.pause_resume_service()
				if (wpsi.getPause()) {
					_service.setIdleTimerDisabled(false)
				} else {
					_service.setIdleTimerDisabled(true)
				}
			case MSG.PREVIOUS:
				print("WallpaperServiceHandler - MSG.PREVIOUS")
				_service.restartTimer();
				_service.naviageWallpaper(offset: -1)
			case MSG.NEXT:
				print("WallpaperServiceHandler - MSG.NEXT")
				_service.restartTimer();
				_service.naviageWallpaper(offset: 1)
			case MSG.SET_INTERVAL:
				print("WallpaperServiceHandler - MSG.SET_INTERVAL")
				if (intOption > 0) {
					wpsi.setInterval(intOption);
					_service.setInterval(interval: intOption);
					_service.restartTimer()
				}
			case MSG.PREVIOUS_THEME:
				print("WallpaperServiceHandler - MSG.PREVIOUS_THEME")
				_service.updateServiceThemeWithPrevious()
			case MSG.NEXT_THEME:
				print("WallpaperServiceHandler - MSG.NEXT_THEME")
				_service.updateServiceThemeWithNext()
			case MSG.SET_MODE:
				print("WallpaperServiceHandler - MSG.SET_MODE")
				wpsi.setMode(ServiceMode(rawValue: intOption)!)
			case MSG.SET_SAVER:
				print("WallpaperServiceHandler - MSG.SET_SAVER")
				wpsi.setSaver((intOption == 1))
            case MSG.SET_OFFLINE_MODE:
                print("WallpaperServiceHandler - MSG.SET_OFFLINE_MODE")
                _service.stopService()
                wpsi.setOfflineMode((intOption == 1))
                _service.startService()
			case MSG.SET_SAVERTIME:
				print("WallpaperServiceHandler - MSG.SET_SAVERTIME")
				wpsi.setSaverTime(intOption)
			default:
				print("WallpaperServiceHandler - Invalid Command Error")
		}
		// should be called at last to reflect pause informtion is updated
		_service.resetSaverTimer()
	}
	func unbind() {
		_incomingMessenger = nil
	}
	
	private var _incomingMessenger: WallpaperServiceConnection? = nil
	lazy private var _service = WallpaperServiceInfo.getInstance().getWallpaperService()
}
