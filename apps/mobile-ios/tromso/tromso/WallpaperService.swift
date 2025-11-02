//
//  WallpaperService.swift
//  tromso
//
//  Created by Brad Park on 5/19/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import UIKit

protocol WallpaperServiceDelegate {
	func setWallpaperOnUI(newImage: UIImage)
	func setIdleTimerDisabled(_ set:Bool)
	func playPauseUpdateOnUI(isPaused: Bool)
    func themeUpdateOnUI(themeString: String, forceShow: Bool)
    func labelUpdateOnUI(labelString: String)
	func openSettingUI()
}

class WallpaperService {
	
    func startService() {
        onStartCommand()
        let wpsi = WallpaperServiceInfo.getInstance()
        if (wpsi.getOfflineMode()) {
            print("WallpaperService started with offline mode")
            self._imageFileManager.setSourceRootPath()
        } else {
            print("WallpaperService started with online mode")
            self._imageFileManager.resetFiles()
        }
    }
	
    func stopService() {
        _platformWallpaper.labelStringUpdateOnUI(labelString: "")
        onDestroy()
    }
	
    private func onDestroy() {
        // stop timer when service is destroyed to prevent service is rerunning
        _platformTimer?.pause()
        if (_started) {
            _started = false
        }
    }
	
	public func broadcastReceiver(_ action:Int, _ extras:Any?) {
        if (!_started) {
            return
        }
		switch action {
		case MSG.SET_THEME:
			print("WallpaperServicebroadcastReceiver() - MSG.SET_THEME")
			if let theme = Theme(rawValue: extras as! Int) {
				updateServiceTheme(theme: theme)
				broadcastServiceUpdate()
			}
		case MSG.PREVIOUS:
			print("WallpaperServicebroadcastReceiver() - MSG.PREVIOUS")
			restartTimer()
			naviageWallpaper(offset: -1)
		case MSG.NEXT:
			print("WallpaperServicebroadcastReceiver() - MSG.NEXT")
			restartTimer()
			naviageWallpaper(offset: 1)
		case MSG.PREVIOUS_THEME:
			print("WallpaperServicebroadcastReceiver() - MSG.PREVIOUS_THEME")
			updateServiceThemeWithPrevious()
			broadcastServiceUpdate()
		case MSG.NEXT_THEME:
			print("WallpaperServicebroadcastReceiver() - MSG.NEXT_THEME")
			updateServiceThemeWithNext()
			broadcastServiceUpdate()
        case MSG.TOGGLE_PAUSE:
            print("WallpaperServicebroadcastReceiver() - MSG.TOGGLE_PAUSE")
            togglePause()
			let wpsi = WallpaperServiceInfo.getInstance()
			if (wpsi.getPause()) {
				setIdleTimerDisabled(false)
			} else {
				setIdleTimerDisabled(true)
			}
		case MSG.OPEN_SETTING_UI:
			print("WallpaperServicebroadcastReceiver() - MSG.OPEN_SETTING_UI")
			openSettingUI()
		default:
			print("WallpaperServicebroadcastReceiver() - Invalid Action")
			return
		}
		resetSaverTimer()
	}
	
    private func onStartCommand() {
        if (!_started) {
            print("Wallpaper Info Service Started.")
            let wpsi = WallpaperServiceInfo.getInstance()
            _started = true;
            _platformTimer = PlatformTimer(self);
            setInterval(interval: wpsi.getInterval())
            pause_resume_service()
		}
		resetSaverTimer()
    }
	
	func resetSaverTimer() {
		struct IdleTime {
			static var minutes = 0
		}
		// print("resetSaverTimer - reset saver timer on", Date())
		IdleTime.minutes = 0
		_saverTimer?.suspend()
		let wpsi = WallpaperServiceInfo.getInstance()
		if (wpsi.getSaver() && wpsi.getMode() != .wallpaper && !wpsi.getPause()) {
			_saverTimer = RepeatingTimer(timeInterval: TimeInterval(60))
			_saverTimer?.eventHandler = {
				IdleTime.minutes += 1
				if (IdleTime.minutes == wpsi.getSaverTime()) {
					print("resetSaverTimer - pause service after ", wpsi.getSaverTime()," minutes of idle time on", Date())
					wpsi.setPause(true)
					self.pause_resume_service()
					self.broadcastServiceUpdate()
				} else if (IdleTime.minutes > wpsi.getSaverTime()) {
					print("resetSaverTimer - disable idle timer after ", wpsi.getSaverTime() + 1," minutes of idle time on", Date())
					self._saverTimer?.suspend()
					self._saverTimer = nil
					self.setIdleTimerDisabled(false)
				}
			}
			_saverTimer?.resume()
		} else {
			_saverTimer = nil
		}
	}
	
    func setInterval(interval: Int ) {
        _platformTimer?.setInterval(interval: interval)
    }
	
	private func togglePause() {
        let wpsi = WallpaperServiceInfo.getInstance()
        wpsi.setPause(!wpsi.getPause())
        pause_resume_service()
    }
	
    func pause_resume_service() {
        let wpsi = WallpaperServiceInfo.getInstance()
        if (wpsi.getPause()) {
            _platformTimer?.pause()
        } else {
            _platformTimer?.resume()
            DispatchQueue.main.async { [weak self] in
                self?.naviageWallpaper(offset: 1)
            }
        }
		broadcastServiceUpdate()
    }
	
    func wallpaperSwitchCallback() {
		// print("WallpaperService.wallpaperSwitchCallback()")
		DispatchQueue.main.async { [weak self] in
			objc_sync_enter(self!)
			let wpsi = WallpaperServiceInfo.getInstance();
			if (!wpsi.getPause()) {
				self?.naviageWallpaper(offset: 1);
			}
			objc_sync_exit(self!)
		}
    }
	
	func naviageWallpaper(offset: Int) {
        let wpsi = WallpaperServiceInfo.getInstance()
        let currentWPath = wpsi.getcurrentWPath()
        if (currentWPath != nil) {
            var imagePath = _imageFileManager.retrievePathFromSource(pivotWPath: currentWPath, offset: offset)
            if (imagePath == nil) { // there is no image in source
                print("naviageWallpaper skipped by no image.")
                return;
			} else if (imagePath!.equals(to: ImageFileManager._new_file_from_server_by_theme)) {
				return;
			}

            // Check when previous image is filtered one while option is on
			while (offset == -1 && !wpsi.getThemeInfo().isThemeImage(coden: imagePath?.coden())) {
                let PreviousImagePath = _imageFileManager.retrievePathFromSource(pivotWPath: imagePath, offset: -1)
                // must avoid infinite loop by checking previous image stays same
				if (PreviousImagePath!.path == imagePath!.path) {
                    print ("naviageWallpaper skipped by no previous theme image.")
                    return
				// following shouldn't happen but just in case
				} else if (ImageFileManager._new_file_from_server_by_theme.equals(to: PreviousImagePath)) {
					return;
				}
                imagePath = PreviousImagePath
            }

            // change Wallpaper only if there is new image
			if (imagePath!.path != wpsi.getcurrentWPath()!.path) {
                changeWallpaper(path: imagePath)
            } else {
                print("naviageWallpaper skipped by no previous image.")
            }

        } else {
            // Change with the first Wallpaper
            if (offset == 1) {
                changeWallpaper(path: nil)
            } else {
                print("naviageWallpaper skipped by no previous image.")
            }
        }
	}
	
    func setWallpaperFromLastUsedPaths(imagePath: WPath) {
        restartTimer();
        changeWallpaper(path: imagePath)
    }
	
	private func changeWallpaper(path: WPath?) {
		if (ImageFileManager._new_file_from_server_by_theme.equals(to: path)) {
			return;
		}
        // Only true for the first image
        var currentWPath = path
        if (currentWPath == nil) {
            currentWPath = _imageFileManager.retrievePathFromSource(pivotWPath: nil, offset: 1)
            if (currentWPath == nil) { // there is no image in source
                print("changeWallpaper skipped by no image.")
                return
			} else if (ImageFileManager._new_file_from_server_by_theme.equals(to:currentWPath)) {
				return;
			}
        }

        let wpsi = WallpaperServiceInfo.getInstance()
		while (!wpsi.getThemeInfo().isThemeImage(coden: currentWPath?.coden())) {
            currentWPath = _imageFileManager.retrievePathFromSource(pivotWPath: currentWPath, offset: 1)
			// asynchronous return should be handled later
			if (ImageFileManager._new_file_from_server_by_theme.equals(to: currentWPath)) {
				return;
			}
        }
		
		if (setWallpaper(wpath: currentWPath!)) {
            wpsi.setcurrentWPath(currentWPath);
        } else {
			// code sync with windows
			wpsi.setcurrentWPath(nil);
        }
		
    }
	
    func restartTimer() {
        _platformTimer?.resetTimer()
    }
	
	// Service Handler Implementation
	func updateServiceTheme(theme: Theme) {
		let wpsi = WallpaperServiceInfo.getInstance()
		wpsi.setThemeInfo(ThemeInfo.getThemeInfo(theme: theme))
        if (wpsi.getOfflineMode()) {
            _imageFileManager.prepareSourceForTheme()
        }
		broadcastServiceUpdate()
	}
    
    func updateLabelWidget(labelString: String) {
        let wpsi = WallpaperServiceInfo.getInstance()
        _platformWallpaper.labelStringUpdateOnUI(labelString: labelString + (wpsi.getIsSyncing() ? " 🔁" : ""))
    }
	
	func updateServiceThemeWithNext() {
		updateServiceTheme(theme: WallpaperServiceInfo.getInstance().getThemeInfo().getNextThemeInfo()._theme)
	}
	
	func updateServiceThemeWithPrevious() {
		updateServiceTheme(theme: WallpaperServiceInfo.getInstance().getThemeInfo().getPrevousThemeInfo()._theme)
	}
	
    func updateServiceCustomConfig(customConfigString: String) {
		let wpsi = WallpaperServiceInfo.getInstance()
		wpsi.setCustomThemeInfo(ThemeInfo.setCustomConfig(customConfigString: customConfigString))
		// reassign custom theme to invoke prepareTheme() with updated custom config string
		// then prepare source again with it
		if (wpsi.getTheme() == .custom) {
			wpsi.setThemeInfo(ThemeInfo.getThemeInfo(theme: .custom))
            if (wpsi.getOfflineMode()) {
                _imageFileManager.prepareSourceForTheme()
            }
		}
	}

	// _platformWallpaper WallpaperServiceDelegate Methods
	func setWallpaperServiceDelegate(_ delegate:WallpaperServiceDelegate?) {
		_platformWallpaper.setWallpaperServiceDelegate(delegate)
	}

	private func broadcastServiceUpdate() {
		// To Theme Widget
		let wpsi = WallpaperServiceInfo.getInstance()
		_platformWallpaper.themeStringUpdateOnUI(themeString: wpsi.getTheme().label, forceShow: wpsi.getPause())
		_platformWallpaper.playPauseUpdateOnUI(isPaused: wpsi.getPause())
        if let currentWPath = wpsi.getcurrentWPath() {
            _platformWallpaper.labelStringUpdateOnUI(labelString: currentWPath.label())
        } else {
            _platformWallpaper.labelStringUpdateOnUI(labelString: "")
        }
	}

	// called by ngorongoro interface with new wallpaper result either from realtime or cache
	func setNewWallpaper(serverCoden:String, image:UIImage?, cacheFile: String?) -> Bool {
		let wpath = WPath(coden: serverCoden)
		if (image == nil && cacheFile == nil) {
			assertionFailure("It shouldn't happen")
			return false
		}
		if (_imageFileManager.notifyGetRandomPathFromSourceDone(newWPath:wpath, image:image, cacheFile: cacheFile)) {
			// Ngorongoro calls in realtime
			if let valid_image = image {
				_platformWallpaper.setWallpaperOnUI(newImage: valid_image)
				let wpsi = WallpaperServiceInfo.getInstance()
				wpsi.setcurrentWPath(wpath)
				return true
			// Ngorongoro calls with cache results
			} else {
				return setWallpaper(wpath: wpath)
			}
		} else {
			print("ngorongoro: Skip setNewWallpaper due to theme change during download or error with invalid cache file." )
		}
		return false
	}

	// called by WallpaperService (fed by cache or local file navigation)
	private func setWallpaper(wpath:WPath) -> Bool {
        let wpsi = WallpaperServiceInfo.getInstance()
        if (wpsi.getOfflineMode()) {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: wpath.path)) {
                if let image = UIImage(data: data) {
                    _platformWallpaper.setWallpaperOnUI(newImage: image)
                    let wpsi = WallpaperServiceInfo.getInstance()
                    wpsi.setcurrentWPath(wpath)
                    broadcastServiceUpdate()
                    return true
                }
            }
            print("Error in setWallpaper: Invalid path or image.")
            return false
        } else {
            if let image = _imageFileManager.getLocalImageFromServerPath(serverPath:wpath.path) {
                _platformWallpaper.setWallpaperOnUI(newImage: image)
                let wpsi = WallpaperServiceInfo.getInstance()
                wpsi.setcurrentWPath(wpath)
                return true
            }
            print("Error in setWallpaper: Invalid serverPath.")
            return false
        }
	}
	
	func setIdleTimerDisabled(_ set:Bool) {
		_platformWallpaper.setIdleTimerDisabled(set)
	}
	
	private func openSettingUI() {
		_platformWallpaper.openSettingUI()
	}

    func syncServerFiles() {
        _imageFileManager.syncServerFiles()
    }
	
    private var _imageFileManager: ImageFileManager = ImageFileManager()
    private var _platformTimer: PlatformTimer? = nil
	private var _saverTimer:RepeatingTimer? = nil
    private var _started : Bool = false
	private var _platformWallpaper: PlatformWallpaper = PlatformWallpaper()
	public var _wallpaperServiceHandler: WallpaperServiceHandler = WallpaperServiceHandler()
    
    static public let _offlineImagesRoot:URL = BPUtil.getHomeDirectoryUrl().appendingPathComponent("CloudStation")

	func isStarted() -> Bool { return _started }

    // service const values
    public static var _maxLastUsedPaths : Int = 50
}


