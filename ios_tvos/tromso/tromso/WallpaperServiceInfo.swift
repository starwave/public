//
//  WallpaperServiceInfo.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/11/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation

class WallpaperServiceInfo {

    private init() {
        let pref = PlatformPreference.getPreferences()
        _pause = pref.pause
        _interval = pref.interval
        _rootSourcePath = pref.root_path
        _offlineMode = pref.offline_mode
        _lastSyncedTime = pref.last_sync_time
        if (_interval < WallpaperServiceInfo._minInterval || _interval > WallpaperServiceInfo._maxInterval) {
            _interval = WallpaperServiceInfo._defaultInterval
        }
		setCustomThemeInfo(ThemeInfo.setCustomConfig(root: pref.custom_root, allow: pref.custom_allow, filter: pref.custom_filter))
		setThemeInfo(ThemeInfo.getThemeInfo(theme: pref.theme))
	}

    private static var sharedWallpaperServiceInfo: WallpaperServiceInfo = {
        let instance = WallpaperServiceInfo()
        return instance
    }()
    
    class func getInstance() -> WallpaperServiceInfo {
        return sharedWallpaperServiceInfo
    }
	
    // persistent property setter/getter
    func getSourceRootPath() -> String { return _rootSourcePath }
    func setSourceRootPath(_ path: String) {
        _rootSourcePath = path;
		PlatformPreference.setPreference(key:"root_path", value:path)
    }
    
	func getTheme() -> Theme { return _themeInfo._theme }
	func getThemeInfo() -> ThemeInfo { return _themeInfo }
	func setThemeInfo(_ themeInfo: ThemeInfo) {
		_themeInfo = themeInfo
		PlatformPreference.setPreference(key:"theme", value:String(themeInfo._theme.intValue))
	}
	func setCustomThemeInfo(_ customThemeInfo: ThemeInfo) {
		_customThemeInfo = customThemeInfo
		PlatformPreference.setPreference(key:"custom_root", value:customThemeInfo._root)
		PlatformPreference.setPreference(key:"custom_allow", value:customThemeInfo._allow)
		PlatformPreference.setPreference(key:"custom_filter", value:customThemeInfo._filter)
    }
	func getCustomConfigString() -> String {
		return _customThemeInfo._root + ";" + _customThemeInfo._allow + ";" + _customThemeInfo._filter
	}
    
    func getPause() -> Bool { return _pause }
    func setPause(_ pause: Bool) {
        _pause = pause;
		PlatformPreference.setPreference(key:"pause", value:String(pause))
    }
    
    func getInterval() -> Int { return _interval }
    func setInterval(_ interval: Int) {
        _interval = interval;
		PlatformPreference.setPreference(key:"interval", value:String(interval))
    }

    func getOfflineMode() -> Bool { return _offlineMode }
    func setOfflineMode(_ offlineMode: Bool) {
        _offlineMode = offlineMode;
        PlatformPreference.setPreference(key:"offline_mode", value:String(offlineMode))
    }
    
    func getlastSyncTime() -> String { return _lastSyncedTime }
    func setlastSyncTime(_ lastSyncedTime: String) {
        _lastSyncedTime = lastSyncedTime;
        PlatformPreference.setPreference(key:"last_sync_time", value:lastSyncedTime)
    }
    
    // runtime property setter/getter
    func getWallpaperService() -> WallpaperService { return _wallpaperService }
    
    func getcurrentWPath() -> WPath? { return _currentWPath }
    func setcurrentWPath(_ path: WPath?) { _currentWPath = path }
    
    func getLastUsedPaths() -> WLinkedHashMap<String, String> { return _lastUsedPaths }
    func setLastUsedPaths(_ lastUsedPaths: WLinkedHashMap<String, String>) { _lastUsedPaths = lastUsedPaths }
	
    func getMode() -> ServiceMode { return _mode }
	func setMode(_ mode:ServiceMode) { _mode = mode }

	func getSaver() -> Bool { return _saver }
	func setSaver(_ saver:Bool) { _saver = saver }

    func getIsSyncing() -> Bool { return _isSyncing }
    func setIsSyncing(_ isSyncing:Bool) { _isSyncing = isSyncing }

	func getSaverTime() -> Int { return _saverTime }
	func setSaverTime(_ saverTime:Int) { _saverTime = saverTime }

	// Platform specific runtime property setter/getter
	func getOrientation() -> String { return _orientation }
	func setOrientation(_ orientation: String) { _orientation = orientation }
	
    // persistent property
	private var _rootSourcePath:String = ""
    private var _themeInfo:ThemeInfo = ThemeInfo.getThemeInfo(theme: .default1);
	private var _customThemeInfo:ThemeInfo = ThemeInfo(theme: .custom,
														 root: ThemeInfo._default_custom_root,
														 allow: ThemeInfo._default_custom_allow,
														 filter: ThemeInfo._default_custom_filter)
    private var _pause:Bool // false
    private var _interval:Int // _defaultInterval // in seconds
    private var _offlineMode:Bool // false
    private var _lastSyncedTime:String

    // runtime property
    private var _currentWPath:WPath? = nil
    //private var _thumbnail:NSImage? = nil;
    private var _lastUsedPaths:WLinkedHashMap<String, String> = WLinkedHashMap<String, String>()
	private var _mode:ServiceMode = .slideshow
	private var _saver:Bool = false;
    private var _isSyncing:Bool = false;
	private var _saverTime:Int = 5;
	
	// Platform specific runtime property
	lazy private var _wallpaperService:WallpaperService = WallpaperService()
	private var _orientation = "L" // L = Landscape, P = Portrait
	//public var _platformHotKey:PlatformHotKey = PlatformHotKey();
    
    //public value from resource
    public static let _defaultInterval:Int = 5; // 15 will not be used. just placeholder.
    public static let _minInterval:Int = 5; // 5 will not be used. just placeholder.
    public static let _maxInterval:Int = 30; // 30 will not be used. just placeholder.
}

enum ServiceMode:Int {
	case wallpaper = 0
	case slideshow
	case cast

	var intValue: Int {
		return rawValue
	}
}
