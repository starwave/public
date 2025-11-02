//
//  AppDelegate.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/11/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import Cocoa
import ScriptingBridge

typealias EventTapCallback = @convention(block) (CGEventType, CGEvent) -> CGEvent?

@NSApplicationMain
class WallpaperInfoAppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        addObserverForWakeAndSleep()
        let wpsi = WallpaperServiceInfo.getInstance();
		let _ = wpsi.getWallpaperService()
		wpsi.getWallpaperService().startService()
        _cleanTimer.eventHandler = {
			if (AppUtil.isMyServiceRunning()) {
				let wpsi = WallpaperServiceInfo.getInstance()
				if (!wpsi.getPause()) {
					PlatformInfo.cleanWallpaperCache()
				}
			}
		}
        _cleanTimer.resume()
        let quickShareManager = QuickShareManager()
        quickShareManager.startAdvertising()
        quickShareManager.startBrowsing()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
		NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.didWakeNotification, object: nil)
		NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.willSleepNotification, object: nil)
		_cleanTimer.suspend()
    }
    
    private func addObserverForWakeAndSleep() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onWakeNote(note:)),
            name: NSWorkspace.didWakeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onSleepNote(note:)),
            name: NSWorkspace.willSleepNotification, object: nil)
    }
	
    @objc func onWakeNote(note: NSNotification) {
        print("Received wake note: \(note.name)")
        let wpsi = WallpaperServiceInfo.getInstance()
        wpsi.getWallpaperService().activateHotkey()
    }

    @objc func onSleepNote(note: NSNotification) {
        print("Received sleep note: \(note.name)")
    }
    
	var _cleanTimer:RepeatingTimer = RepeatingTimer(timeInterval: TimeInterval(60))
}
