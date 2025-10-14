//
//  WallpaperInfoUtil.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/13/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import Cocoa

class MSG {
    public static var REQUEST_INFO:Int = 1;
    public static var PAUSE:Int = 2;
    public static var PREVIOUS:Int = 3;
    public static var NEXT:Int = 4;
    public static var SET_ROOT:Int = 5;
    public static var ACTIVITY_REPORT:Int = 6;
    public static var SET_WALLPAPER:Int = 7;
    public static var SET_INTERVAL:Int = 8;
    public static var SERVICE_INFO:Int = 9;
    public static var SET_THEME:Int = 10;
    public static var CUSTOM_CONFIG:Int = 11;
    public static var PREVIOUS_THEME:Int = 12;
    public static var NEXT_THEME:Int = 13;
	public static var TOGGLE_PAUSE:Int = 14;
	public static var SET_MODE:Int = 15;
	public static var SET_SAVER:Int = 16;
	public static var SET_SAVERTIME:Int = 17;
	public static var OPEN_SETTING_UI:Int = 18;
}

class AppUtil {
	
	static func getWordsArray(wordString:String) -> Array<String> {
		// check if empty string to avoid split function to create one empty entry in array
		if (wordString == "") {
			return Array<String>()
		} else {
			return wordString.components(separatedBy: "|")
		}
	}
    
	static func errorAlert(title:String, message:String) {
		let alert = NSAlert()
		alert.messageText = title
		alert.informativeText = message
		alert.alertStyle = .warning
		alert.addButton(withTitle: "OK")
		_ = alert.runModal()
	}
	
    static func isMyServiceRunning() -> Bool {
        let wpsi = WallpaperServiceInfo.getInstance();
        return wpsi.getWallpaperService().isStarted()
    }    
}


