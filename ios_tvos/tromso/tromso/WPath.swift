//
//  WPath.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 9/29/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation

class WPath {
	var path: String
	var exif: String
	init(path _path:String, exif _exif:String) {
		path = _path
		exif = _exif
	}
	init(coden _coden:String) {
		path = _coden
		exif = ""
		if let indexPercent = _coden.lastIndex(of: "%") {
			let exifWithExt = "\(_coden[_coden.index(indexPercent, offsetBy: 1)...])"
			if let indexDot = exifWithExt.lastIndex(of: ".") {
				let pathExtension = "\(exifWithExt[indexDot...])"
				path = "\(_coden[..<indexPercent])" + pathExtension
				exif = "\(exifWithExt[..<indexDot])"
			}
		}
	}
	func coden() -> String {
		let coden = path.replacingOccurrences(of:WPath._platformRootPath, with:"")
		if (exif != "") {
            if let index = path.lastIndex(of: ".") {
                let pathExtension = String(path[path.index(index, offsetBy: -1)...])
                return coden.replacingOccurrences(of: pathExtension,
                                                 with: "%" + exif + pathExtension)
            }
		}
        return coden
	}
	func label() -> String {
		var label = ""
		let rawImageName = BPUtil.getOnlyFileName(path)
        let regex = try! NSRegularExpression(pattern: "^[0-9]{8}_[0-9]{6}@", options:NSRegularExpression.Options(rawValue: 0))
        let range = NSMakeRange(0, rawImageName.count)
        let imageName = regex.stringByReplacingMatches(in: rawImageName, options: [], range: range, withTemplate: "")
		if (exif != "") {
			label = BPUtil.getFolderName(path) + " / #" + exif + " | " + imageName
		} else {
			label = BPUtil.getFolderName(path) + " / " + imageName
		}
		label = label.replacingOccurrences(of: "#sn#", with: "~").replacingOccurrences(of: "#nd#", with: "!")
		return BPUtil.abbreviate(label, offset:0, maxWidth:WPath._maxImageDescriptionLength)
	}
	public func equals(to wpath:WPath?) -> Bool {
		if (wpath != nil && path == wpath!.path && exif == wpath!.exif) {
			return true
		}
		return false
	}
	public static func setPlatformRootPath(path: String) {
		if let index = path.firstIndex(of :"/BP Wallpaper/") {
			_platformRootPath = String(path[..<index])
		} else if let index = path.firstIndex(of :"/BP Photo/") {
			_platformRootPath = String(path[..<index])
		}
	}
	private static var _platformRootPath:String = ""
    // 63 is upper bound for Windows Tooltip
    private static let _maxImageDescriptionLength: Int = {
        #if os(tvOS)
        return 63 + 37  // 100 characters for Apple TV
        #else
        return 63       // 63 characters for other platforms
        #endif
    }()
}
