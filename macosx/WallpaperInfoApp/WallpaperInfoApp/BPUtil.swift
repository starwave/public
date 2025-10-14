//
//  BPUtil.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/12/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import Cocoa

class BPUtil {
    
    class func getExifDescription(path: String) -> String {
        var exif = ""
        let exifInterface = ExifInterface(path: path);
        let imageDescription = exifInterface.getAttribute(attribute:ExifInterface.TAG_IMAGE_DESCRIPTION).trimmingCharacters(in: .whitespacesAndNewlines)
        if (imageDescription != "") {
            exif = imageDescription
        }
        return exif
    }
    
    class func getOnlyFileName(_ path: String) -> String {
        return URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
    }
    
    class func getFolderName(_ path: String) -> String {
		return URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent
    }
    
    class func abbreviate(_ str: String, offset: Int, maxWidth: Int, position: TruncationPosition = .middle, leader: String = "...") -> String! {
        guard str.count > maxWidth else { return str }
        switch position {
        case .head:
            return leader + str.suffix(maxWidth)
        case .middle:
            let headCharactersCount = Int(ceil(Float(maxWidth - leader.count) / 2.0))
            let tailCharactersCount = Int(floor(Float(maxWidth - leader.count) / 2.0))
            return "\(str.prefix(headCharactersCount))\(leader)\(str.suffix(tailCharactersCount))"
        case .tail:
            return str.prefix(maxWidth) + leader
        }
    }
    
	class func fileExists(_ path: String) -> Bool {
		let fm = FileManager.default
		if (fm.fileExists(atPath: path)) {
			return true
		}
		return false
	}
    
    class func BPLog(_ format:String, _ argv: CVarArg...) {
        let logs = PlatformInfo.swiftprintf(format, argv)!
        let now = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy/MM/dd HH:mm:ss"
        let dt_string = format.string(from: now)
        print(dt_string, logs)
        let logFile = URL(fileURLWithPath: getHomeDirectory() + "/logs/WallpaperInfoApp.log")
        guard let data = (dt_string + " " + logs + "\n").data(using: String.Encoding.utf8) else { return }
        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            try? data.write(to: logFile, options: .atomicWrite)
        }
    }

	class func getStringFromFile (fileURL: URL) -> String {
		objc_sync_enter(_fileLock)
		var contents = ""
		do {
			let rawContents = try String(contentsOf: fileURL, encoding: .utf8)
			contents = rawContents
		}
		catch {
			print("Error: BPUtil.getStringFromFile - can't read from file.")
		}
		objc_sync_exit(_fileLock)
		return contents
	}
	
	class func storeStringToFile(fileURL:URL, contents:String) {
		objc_sync_enter(_fileLock)
		do {
			try contents.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
		} catch {
			print("Error: BPUtil.storeStringToFile - can't write to file.")
		}
		objc_sync_exit(_fileLock)
	}
    
    static func getHomeDirectory() -> String {
        return NSHomeDirectory()
    }
    
    static func showImageFile(with path: String) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }

    static func openImagePreview(with path: String) {
        NSWorkspace.shared.openFile(path, withApplication: "Preview")
    }

    static func optionKeyPressed() -> Bool {
        return NSEvent.modifierFlags.contains(NSEvent.ModifierFlags.option)
    }
    
    static func shiftKeyPressed() -> Bool {
        return NSEvent.modifierFlags.contains(NSEvent.ModifierFlags.shift)
    }

    /*
    class func isDirectory(_ path: String) -> Bool {
       let fm = FileManager.default
       var isDir : ObjCBool = false
       if fm.fileExists(atPath: path, isDirectory:&isDir) {
           if isDir.boolValue {
               return true
           }
       }
        return false
    }
     */
    
    enum TruncationPosition {
        case head
        case middle
        case tail
    }
	
	private static let _fileLock:NSObject = NSObject()
    private static var _bp_log_path:String = "BPLog.txt"
}

extension String {
    func bashCommand() -> String {
        let pipe = Pipe()
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", String(format:"%@", self)]
        task.standardOutput = pipe
        let file = pipe.fileHandleForReading
        task.launch()
        if let result = NSString(data: file.readDataToEndOfFile(), encoding: String.Encoding.utf8.rawValue) {
            return result as String
        }
        else {
            return "--- Error running command - Unable to initialize string from file data ---"
        }
    }
}
