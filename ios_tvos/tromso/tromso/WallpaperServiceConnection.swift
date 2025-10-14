//
//  WindowServiceConnection.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/15/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation

class WallpaperServiceConnection {

	init(_ contentView: ContentView) {
		_delegate = contentView
	}
	
    public static func startService() {
        WallpaperServiceHandler.startService()
    }
    
    public static func stopService() {
        WallpaperServiceHandler.stopService()
    }
    
	public static func broadcastToService(_ action:Int, extras:Any? = nil) {
        WallpaperServiceInfo.getInstance().getWallpaperService().broadcastReceiver(action, extras)
    }
	
    func sendMessageToService(command:Int, intOption:Int = 0, objectOption:Any? = nil) {
		if _wallpaperServiceHandler != nil {
			_wallpaperServiceHandler?.handleMessage(command, intOption, objectOption)
		}
    }
	
	class func bindService(contentView: ContentView) -> WallpaperServiceConnection {
		let wallpaperServiceConnection = WallpaperServiceConnection(contentView)
		wallpaperServiceConnection._wallpaperServiceHandler = WallpaperServiceHandler.incomingHandler(incomingMessenger: wallpaperServiceConnection)
		return wallpaperServiceConnection
	}
	
	func unbindService() {
		_wallpaperServiceHandler?.unbind()
		_wallpaperServiceHandler = nil
	}

	var _delegate: ContentView
	private var _wallpaperServiceHandler: WallpaperServiceHandler? = nil
}
