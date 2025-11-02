//
//  PlatformPreference.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/17/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation

class PlatformPreference {
	
    class func getPreferences() -> WallpaperInfoPreference {
		let defaults = UserDefaults.standard
		
		defaults.register(defaults: ["root_path" : "BP Photo" ])
		defaults.register(defaults: ["theme" : String(Theme.default1.rawValue) ])
		defaults.register(defaults: ["custom_root" : ThemeInfo._default_custom_root ])
		defaults.register(defaults: ["custom_allow" : ThemeInfo._default_custom_allow ])
		defaults.register(defaults: ["custom_filter" : ThemeInfo._default_custom_filter ])
		defaults.register(defaults: ["pause" : String(false) ])
        defaults.register(defaults: ["interval" : String(WallpaperServiceInfo._defaultInterval) ])
        defaults.register(defaults: ["offline_mode" : String(true) ])
        defaults.register(defaults: ["last_sync_time" : "" ])

        return WallpaperInfoPreference(root_path: defaults.string(forKey: "root_path")!,
									   theme: Theme(rawValue: Int(defaults.string(forKey: "theme")!)!)!,
									   custom_root: defaults.string(forKey: "custom_root")!,
									   custom_allow: defaults.string(forKey: "custom_allow")!,
									   custom_filter: defaults.string(forKey: "custom_filter")!,
									   pause: Bool(defaults.string(forKey: "pause")!)!,
									   interval: Int(defaults.string(forKey: "interval")!)!,
                                       offline_mode: Bool(defaults.string(forKey: "offline_mode")!)!,
                                       last_sync_time: defaults.string(forKey: "last_sync_time")!)
	}
	
	class func setPreference(key:String, value:String) {
		let defaults = UserDefaults.standard
		defaults.set(value, forKey: key)
	}
}

public struct WallpaperInfoPreference {
    var root_path: String
	var theme: Theme
	var custom_root:String
	var custom_allow:String
    var custom_filter: String
    var pause: Bool
    var interval: Int
    var offline_mode: Bool
    var last_sync_time: String
}
