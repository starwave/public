//
//  PlatformWallpaper.swift
//  tromso
//
//  Created by Brad Park on 8/21/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import UIKit

class PlatformWallpaper {
	
	init() {
	}
	
	func setWallpaperServiceDelegate(_ delegate:WallpaperServiceDelegate?) {
		_wallpaperServiceDelegate = delegate
	}
	
	func setIdleTimerDisabled(_ set:Bool) {
		if let delegate = _wallpaperServiceDelegate {
			delegate.setIdleTimerDisabled(set)
		} else {
			print("No delegate is assigned yet.")
		}
	}
	
	func playPauseUpdateOnUI(isPaused: Bool) {
		if let delegate = _wallpaperServiceDelegate {
			delegate.playPauseUpdateOnUI(isPaused: isPaused)
		} else {
			print("No delegate is assigned yet.")
		}
	}
	
    func themeStringUpdateOnUI(themeString: String, forceShow: Bool = false) {
		if let delegate = _wallpaperServiceDelegate {
			delegate.themeUpdateOnUI(themeString: themeString, forceShow: forceShow)
		} else {
			print("No delegate is assigned yet.")
		}
	}
    
    func labelStringUpdateOnUI(labelString: String) {
        let wpsi = WallpaperServiceInfo.getInstance()
        if (wpsi.getOfflineMode()) {
            if let delegate = _wallpaperServiceDelegate {
                delegate.labelUpdateOnUI(labelString: labelString)
            } else {
                print("No delegate is assigned yet.")
            }
        }
    }

	func setWallpaperOnUI(newImage: UIImage){
		if let delegate = self._wallpaperServiceDelegate {
			delegate.setWallpaperOnUI(newImage: newImage)
		} else {
			print("No delegate is assigned yet.")
		}
	}
	
	func openSettingUI() {
		if let delegate = self._wallpaperServiceDelegate {
			delegate.openSettingUI()
		} else {
			print("No delegate is assigned yet.")
		}
	}
	
	private var _wallpaperServiceDelegate: WallpaperServiceDelegate? = nil
}

