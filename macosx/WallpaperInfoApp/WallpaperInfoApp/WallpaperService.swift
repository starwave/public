//
//  WallpaperService.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/11/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import Cocoa
import NIOPosix

class WallpaperService {
    
    init() {
        activateHotkey()
        let bonjourService = BPBonjourService()
        bonjourService.start()
        let fileTransferServer = BPFileReceiver()
        fileTransferServer.start()
    }
    
    deinit {
        if (_started) {
            onDestroy()
        }
    }
    
    func startService() {
        onStartCommand()
    }

    func stopService() {
        _imageFileManager.stopWatching()
        onDestroy()
    }

    private func onDestroy() {
        // stop timer when service is destroyed to prevent service is rerunning
        _platformTimer?.pause()

        // update widget for default view
        let wpsi = WallpaperServiceInfo.getInstance()
        wpsi.setcurrentWPath(nil)
        wpsi.setThumbnail(nil)
        
        if (_started) {
			// removing observer
            NotificationCenter.default.removeObserver(self)
            _started = false
        }
        broadcastServiceUpdate()
    }
	
	public func broadcastReceiver(_ action:Int, _ extras:Any?) {
        if (!_started) {
            return
        }
		switch action {
		case MSG.SET_THEME:
            BPUtil.BPLog("WallpaperServicebroadcastReceiver - MSG.SET_THEME")
			if let theme = Theme(rawValue: extras as! Int) {
				updateServiceTheme(theme: theme)
				broadcastServiceUpdate()
			}
		case MSG.PREVIOUS:
            BPUtil.BPLog("WallpaperServicebroadcastReceiver - MSG.PREVIOUS")
			restartTimer()
			naviageWallpaper(offset: -1)
		case MSG.NEXT:
            BPUtil.BPLog("WallpaperServicebroadcastReceiver - MSG.NEXT")
			restartTimer()
			naviageWallpaper(offset: 1)
		case MSG.PREVIOUS_THEME:
            BPUtil.BPLog("WallpaperServicebroadcastReceiver - MSG.PREVIOUS_THEME")
			updateServiceThemeWithPrevious()
			broadcastServiceUpdate()
		case MSG.NEXT_THEME:
            BPUtil.BPLog("WallpaperServicebroadcastReceiver - MSG.NEXT_THEME")
			updateServiceThemeWithNext()
			broadcastServiceUpdate()
        case MSG.TOGGLE_PAUSE:
            BPUtil.BPLog("WallpaperServicebroadcastReceiver - MSG.TOGGLE_PAUSE")
            togglePause()
		default:
            BPUtil.BPLog("WallpaperServicebroadcastReceiver -Invalid Action")
		}
	}
    
    private func onStartCommand() {
        if (!_started) {
            BPUtil.BPLog("Wallpaper Info Service Started.")
            _platformWallpaper = PlatformWallpaper()
            _imageFileManager = ImageFileManager()
            let wpsi = WallpaperServiceInfo.getInstance()
            setNewSourceRootPath(wpsi.getSourceRootPath())
			WallpaperWidgetProvider.refreshWidgets()
            _started = true;
            _platformTimer = PlatformTimer(self);
            setInterval(interval: wpsi.getInterval())
            pause_resume_service()
			// adding screen change observer
            NotificationCenter.default.addObserver(self, selector: #selector(screenChangeCallback), name: NSApplication.didChangeScreenParametersNotification, object: nil)
		} else {
			WallpaperWidgetProvider.refreshWidgets()
		}
		resetSaverTimer()
    }
	
	func resetSaverTimer() {
        BPUtil.BPLog("WallpaperService.resetSaverTimer")
		_saverTimer?.suspend()
		let wpsi = WallpaperServiceInfo.getInstance()
		if (wpsi.getSaver() && wpsi.getMode() != .wallpaper && !wpsi.getPause()) {
			_saverTimer = RepeatingTimer(timeInterval: TimeInterval(60 * wpsi.getSaverTime()))
			_saverTimer?.eventHandler = {
                BPUtil.BPLog("WallpaperService.resetSaverTimer - suspended after %d minutes of idle time.", wpsi.getSaverTime())
				self._saverTimer?.suspend()
				self._saverTimer = nil
				wpsi.setPause(true)
				self.pause_resume_service()
			}
			_saverTimer?.resume()
		} else {
			_saverTimer = nil
		}
	}
    
    @objc func screenChangeCallback() {
        BPUtil.BPLog("WallpaperService.screenChangeCallback")
        WallpaperWidgetProvider.refreshWidgets()
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
    
    func setNewSourceRootPath(_ newSourceRootPath: String) {
        let wpsi = WallpaperServiceInfo.getInstance()
        wpsi.setcurrentWPath(nil)
        wpsi.setThumbnail(nil)
        wpsi.setSourceRootPath(newSourceRootPath)
        _imageFileManager.setSourceRootPath(newSourceRootPath)
    }
    
    func naviageWallpaper(offset: Int) {
		// wait for theme preparation is done for forward navigation
		if (!_imageFileManager.isThemeReady() && offset == 1) {
            BPUtil.BPLog("skip new image during theme preparation")
			return
		}
        let wpsi = WallpaperServiceInfo.getInstance()
		if let currentWPath = wpsi.getcurrentWPath() {
			var imagePath = _imageFileManager.retrievePathFromSource(pivotWPath: currentWPath, offset: offset)
            if (imagePath == nil) { // there is no image in source
                _platformWallpaper.makeThumbnailFromScreenWallpaper()
                broadcastServiceUpdate()
                BPUtil.BPLog("naviageWallpaper skipped by no image.")
                return;
            }

            // Check when previous image is filtered one while option is on
			while (offset == -1 && !wpsi.getThemeInfo().isThemeImage(coden: imagePath?.coden())) {
				let PreviousImagePath = _imageFileManager.retrievePathFromSource(pivotWPath: imagePath, offset: -1)
                // must avoid infinite loop by checking previous image stays same
				if (PreviousImagePath!.path == imagePath!.path) {
                    // BPUtil.BPLog("%s", "naviageWallpaper skipped by no previous unfiltered image.")
                    BPUtil.BPLog ("naviageWallpaper skipped by no previous theme image.")
                    return
				}
                imagePath = PreviousImagePath
            }

            // change Wallpaper only if there is new image
			if (imagePath!.path != currentWPath.path) {
				changeWallpaper(wpath: imagePath)
            } else {
                // BPUtil.BPLog("%s", "naviageWallpaper skipped by no previous image.")
                BPUtil.BPLog("naviageWallpaper skipped by no previous image.")
            }
        } else {
            // Change with the first Wallpaper
            if (offset == 1) {
                changeWallpaper(wpath: nil)
            } else {
                BPUtil.BPLog("naviageWallpaper skipped by no previous image.")
            }
        }
    }
    
    func setWallpaperFromLastUsedPaths(imagePath: WPath) {
        restartTimer();
        changeWallpaper(wpath: imagePath)
    }
    
    func restartTimer() {
        _platformTimer?.resetTimer()
    }
    
	private func changeWallpaper(wpath: WPath?) {
        // Only true for the first image
        let fm = FileManager.default
        var currentWPath = wpath
		if (currentWPath == nil || !(fm.fileExists(atPath: currentWPath!.path))) {
            currentWPath = _imageFileManager.retrievePathFromSource(pivotWPath: nil, offset: 1)
            if (currentWPath == nil) { // there is no image in source
                _platformWallpaper.makeThumbnailFromScreenWallpaper()
                broadcastServiceUpdate()
                BPUtil.BPLog("changeWallpaper skipped by no image.")
                return;
            }
        }

        let wpsi = WallpaperServiceInfo.getInstance()
        var count:Int = 0;
        let total:Int? = _imageFileManager.getTotalImageCount()
		while (!wpsi.getThemeInfo().isThemeImage(coden: currentWPath?.coden())) {
            currentWPath = _imageFileManager.retrievePathFromSource(pivotWPath: currentWPath, offset: 1)
            // must avoid infinite loop in case all files are filtered
            // reach end of source due to all filtered files
            count += 1
            if (count >= total!) {
                BPUtil.BPLog("changeWallpaper skipped by no theme image.")
				// pause service otherwise service is hanging
				wpsi.setPause(true)
				wpsi.setLastUsedPaths(WLinkedHashMap<String, String>())
                pause_resume_service()
                broadcastServiceUpdate()
                return
            }
        }
		let pretty_path = currentWPath!.label()
		if (_platformWallpaper.setWallpaper(path: currentWPath!.path)) {
            wpsi.setcurrentWPath(currentWPath!);
            BPUtil.BPLog("{WP} " + pretty_path + " [" + _imageFileManager.getImageStat(path:currentWPath!.path) + "]")
            broadcastServiceUpdate()
        } else {
			// code sync with windows
			wpsi.setcurrentWPath(nil);
            BPUtil.BPLog("{WP} " + pretty_path + " is failed. [" + _imageFileManager.getImageStat(path:currentWPath!.path) + "]")
        }
    }
	
	func updateServiceTheme(theme: Theme) {
		let wpsi = WallpaperServiceInfo.getInstance()
		wpsi.setThemeInfo(ThemeInfo.getThemeInfo(theme: theme))
		_imageFileManager.prepareSourceForTheme()
		WallpaperWidgetProvider.updateThemeWidget(themeLabel: theme.label)
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
			_imageFileManager.prepareSourceForTheme()
		}
	}
	
    private func broadcastServiceUpdate() {
		//print("WallpaperService.broadcastServiceUpdate()")
		let wpsi = WallpaperServiceInfo.getInstance()
		// To Notification
		_wallpaperNotification.buildNotification(wpath: wpsi.getcurrentWPath(), thumbnail: wpsi.getThumbnail(), theme: wpsi.getTheme())
		// To Widget
		WallpaperWidgetProvider.updatePauseWidget(pause:wpsi.getPause())
		WallpaperWidgetProvider.updateThemeWidget(themeLabel: wpsi.getTheme().label, forceShow: wpsi.getPause())
		if let currentWPath = wpsi.getcurrentWPath() {
			WallpaperWidgetProvider.updateLabelWidget(text: currentWPath.label())
		} else {
            WallpaperWidgetProvider.updateLabelWidget(text: "")
		}
		// To UI
		_wallpaperServiceHandler.replyToClient(thumbnail: wpsi.getThumbnail(), currentWPath: wpsi.getcurrentWPath(), pause: wpsi.getPause())
    }
    
    public func activateHotkey() {
        _wallpaperNotification._platformHotKey.initEventPort()
    }
    
    public func runBPHTTPHandler() {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: ProcessInfo.processInfo.activeProcessorCount)
        let bootstrap = ServerBootstrap(group: group)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(BPHTTPHandler())
                }
            }
            .bind(host: "localhost", port: 8080)
        let channel = try? bootstrap.wait()
        if (channel != nil) {
            // BPUtil.BPLog("Server running on \(channel?.localAddress!)")
            try? channel?.closeFuture.wait()
            // running
        }
    }
	
    private var _imageFileManager: ImageFileManager = ImageFileManager()
    private var _platformTimer: PlatformTimer? = nil
	private var _saverTimer:RepeatingTimer? = nil
    private var _started : Bool = false
    lazy private var _platformWallpaper: PlatformWallpaper = PlatformWallpaper()
	lazy public var _wallpaperServiceHandler: WallpaperServiceHandler = WallpaperServiceHandler()

    // service const values
    public static var _maxLastUsedPaths : Int = 50
	
	// only for Mac OS X, Windows, Linux
	private var _wallpaperNotification: WallpaperNotification = WallpaperNotification()
    func isStarted() -> Bool { return _started }
}
