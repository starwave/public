//
//  ExifInterface.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/12/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import ImageIO


// let exifInterface = ExifInterface(path: path);
// let description:String = exifInterface.getAttribute(attribute: ExifInterface.TAG_IMAGE_DESCRIPTION)
// let orientation:Int = exifInterface.getAttribute(attribute: ExifInterface.TAG_ORIENTATION)

class ExifInterface {
    
    var _path: String
    var _dict: NSDictionary
    
    init(path: String) {
        _path = path
        let url = NSURL(fileURLWithPath: path)
        let cgiSrc = CGImageSourceCreateWithURL(url,nil)
		//let optionDic = NSDictionary.init(objects: [true], forKeys: [kCGImageSourceShouldCache as! NSCopying] )
		// TODO Crash with zero size file and IMG_1740.jpg
        let cfD:CFDictionary = CGImageSourceCopyPropertiesAtIndex(cgiSrc!, 0, nil)!
        _dict = NSDictionary(dictionary: cfD)
    }
    
    func getAttribute(attribute: Int) -> String {
        if (attribute == ExifInterface.TAG_IMAGE_DESCRIPTION) {
			if let subDict = _dict["{TIFF}"] as? NSDictionary {
				let description = subDict["ImageDescription"]
				if (description == nil) {
					return ""
				} else {
					return description as! String
				}
			}
        }
        return ""
    }
    
    func getAttribute(attribute: Int) -> Int {
        if (attribute == ExifInterface.TAG_ORIENTATION) {
            return _dict["Orientation"] as! Int
        }
        return 0
    }
    
    static let TAG_IMAGE_DESCRIPTION:Int = 100 // "ImageDescription"
    static let TAG_ORIENTATION:Int = 101 // "Orientation"
    static let ORIENTATION_UNDEFINED:Int = 0
    static let ORIENTATION_NORMAL:Int = 1
    static let ORIENTATION_ROTATE_180:Int = 3
    static let ORIENTATION_ROTATE_90:Int = 6
    static let ORIENTATION_ROTATE_270:Int = 8
    
}
