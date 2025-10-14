//
//  ExifInterface.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/12/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import ImageIO

class ExifInterface {
    
    private var path: String
    private var properties: [String: Any]?
    
    init(path: String) {
        self.path = path
        self.properties = ExifInterface.getImageProperties(from: path)
    }
    
    private static func getImageProperties(from path: String) -> [String: Any]? {
        let url = URL(fileURLWithPath: path)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]
    }
    
    func getAttribute(attribute: Int) -> String {
        switch attribute {
        case ExifInterface.TAG_IMAGE_DESCRIPTION:
            if let tiffDict = properties?[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
               let description = tiffDict[kCGImagePropertyTIFFImageDescription as String] as? String {
                return description
            }
        default:
            break
        }
        return ""
    }
    
    func getAttribute(attribute: Int) -> Int {
        switch attribute {
        case ExifInterface.TAG_ORIENTATION:
            if let orientation = properties?[kCGImagePropertyOrientation as String] as? Int {
                return orientation
            }
        default:
            break
        }
        return 0
    }
    
    static let TAG_IMAGE_DESCRIPTION: Int = 100
    static let TAG_ORIENTATION: Int = 101
    static let ORIENTATION_UNDEFINED: Int = 0
    static let ORIENTATION_NORMAL: Int = 1
    static let ORIENTATION_ROTATE_180: Int = 3
    static let ORIENTATION_ROTATE_90: Int = 6
    static let ORIENTATION_ROTATE_270: Int = 8
}
