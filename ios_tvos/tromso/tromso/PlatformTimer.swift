//
//  WallpaperSwitchScheduler.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/11/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation

class PlatformTimer {

    init(_ wallpaperService: WallpaperService) {
        _wallpaperService = wallpaperService
    }

    private func scheduleSwitchWallpaper(seconds: Int) {
        if (_switchHandler != nil) {
            cancelSwitchWallpaper();
        }
        _switchHandler = RepeatingTimer(timeInterval: TimeInterval(seconds))
        _switchHandler!.eventHandler = {
			print("PlatformTimer.eventHandler{}")
			if (!self._pause) {
				self._wallpaperService.wallpaperSwitchCallback();
			}
        }
        _pause = false;
        _switchHandler!.resume()
    }
    
    func cancelSwitchWallpaper() {
        if (_switchHandler != nil) {
			_switchHandler?.suspend()
            _switchHandler = nil;
        }
        _pause = true
    }
    
    func resetTimer() {
        if (!_pause) {
            resume();
        }
    }
    
    func pause() {
		// print("PlatformTimer.pause()")
        cancelSwitchWallpaper();
    }
    
    func resume() {
		// print("PlatformTimer.resume()")
        scheduleSwitchWallpaper(seconds: _interval);
    }
    
    func setInterval(interval: Int) {
        _interval = interval;
        if (!_pause) {
            resume();
        }
    }
    
    private var _wallpaperService: WallpaperService;
    private var _switchHandler:RepeatingTimer? = nil;
    private var _interval:Int = 5;
    private var _pause:Bool = false;

}
