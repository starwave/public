//
//  BPWallpaperManager.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/11/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import Cocoa

class PlatformWallpaper {

    func setWallpaper(path: String, screen:NSScreen? = nil) -> Bool {
		if (!BPUtil.fileExists(path)) {
            print("Wallpaper " + path + " doesn't exist.")
            return false;
        }
		
		var screens:[NSScreen]
        if screen != nil {
            screens = [screen!]
        } else {
            screens = NSScreen.screens
        }
		return (applyWallpaperFromFile(path: path, screens))
    }
    
    func makeThumbnailFromScreenWallpaper() {
        
    }
    
	private func applyWallpaperFromFile(path: String, _ screens:[NSScreen]) -> Bool {
        do {
            let imgurl = NSURL.fileURL(withPath: path)
            let workspace = NSWorkspace.shared
            var options = [NSWorkspace.DesktopImageOptionKey: Any]()
            options[.allowClipping] = false
            options[.fillColor] = NSColor.black
            options[.imageScaling] = NSImageScaling.scaleProportionallyUpOrDown.rawValue
            // options[.imageScaling] = NSImageScaling.scaleAxesIndependently.rawValue
            // options[.imageScaling] = NSImageScaling.scaleNone.rawValue
            for screen in screens {
                try workspace.setDesktopImageURL(imgurl, for: screen, options: options)
            }
        } catch {
            print(error)
			return false
        }
		
		let thumbnail =  PlatformWallpaper.makeThumbnail(path)
		let wpsi = WallpaperServiceInfo.getInstance();
		wpsi.setThumbnail(thumbnail);
		
        return true;
    }
    
    class func makeThumbnail(_ path: String) -> NSImage {
		if let image = NSImage(contentsOfFile: path) {
			let width:Int = Int(image.size.width * CGFloat(_thumbnail_height)  / image.size.height)
			let height:Int = _thumbnail_height
			let thumbnail = image.getResizedImage(width, height)
			return thumbnail
		}
        return NSImage(named: "thirdwave.png")!
    }
    
    static let _thumbnail_height: Int = 150;
}

