//
//  BPUtil.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/12/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation

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
    
    enum TruncationPosition {
        case head
        case middle
        case tail
    }
	
    class func getFolderName(_ path: String) -> String {
		return URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent
    }
    
    class func getOnlyFileName(_ path: String) -> String {
		return URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
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
    
    class func swiftprintf(_ format: String, _ arguments: CVarArg... ) -> String? {
        return withVaList(arguments) { va_list in
            var buffer: UnsafeMutablePointer<Int8>? = nil
            return format.withCString { cString in
                guard vasprintf(&buffer, cString, va_list) != 0 else {
                    return nil
                }
                return String(validatingUTF8: buffer!)
            }
        }
    }
	
	class func fileExists(_ path: String) -> Bool {
		let fm = FileManager.default
		if (fm.fileExists(atPath: path)) {
			return true
		}
		return false
	}

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
    
    static func getHomeDirectoryUrl() -> URL {
        #if os(tvOS)
            // ✅ .cachesDirectory: Recommended for writable storage. Files persist until the system needs to free up space.
            // 🚫 .documentDirectory: Read-only on tvOS. Cannot be used for writing.
            // ⚠️ .temporaryDirectory: Short-lived storage, deleted when the app is terminated.
            return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        #else
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        #endif
    }
    
    static func getHomeDirectory() -> String {
        return getHomeDirectoryUrl().path
    }
    
    static func ensureDirectories(for url: URL) -> Bool {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        if !fileManager.fileExists(atPath: url.path, isDirectory:&isDir) || !isDir.boolValue {
            do {
                
                let targetDir:URL =  URL(fileURLWithPath: url.deletingLastPathComponent().path, isDirectory: true)
                try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true, attributes: nil)
                return true
            } catch {
                print("FileSyncManager: Error creating directories: \(error)")
                return false
            }
        }
        return true
    }
    
    static func getAllLocalFiles(in rootFileUrl: URL) -> [String] {
        guard let enumerator = FileManager.default.enumerator(at: rootFileUrl, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        var files: [String] = []
        for case let fileURL as URL in enumerator {
            do {
                let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                if fileAttributes.isRegularFile! {
                    if (fileURL.lastPathComponent.starts(with:".")) {
                        continue
                    }
                    let relativePath = BPUtil.relativePath(with: fileURL, from: rootFileUrl)
                    // print("getAllLocalFiles: adding " + fileURL.path + " => " + relativePath)
                    files.append(relativePath)
                }
            } catch { print(error, fileURL) }
        }
        return files
    }
    
    static func relativePath(with src: URL, from base: URL) -> String {
        // some API in device has this prefix
        var srcPath = src.path
        if srcPath.hasPrefix("/private") {
            srcPath = String(src.path.dropFirst("/private".count))
        }
        guard srcPath.starts(with: base.path) else {
            return src.path
        }
        let relativePath = srcPath.replacingOccurrences(of: base.path + "/", with: "")
        return relativePath
    }
	
	private static let _fileLock:NSObject = NSObject()
    private static var _bp_log_path:String = "BPLog.txt"
}

extension DispatchQueue {
    static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }
}

@discardableResult
public func synchronized<T>(_ lock: AnyObject, closure:() -> T) -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }

    return closure()
}

extension Date {
	func getDiffInSecond(since date: Date) -> Int  {
		let calendar = Calendar.current
		let dateComponents = calendar.dateComponents([Calendar.Component.second], from: date, to: self)
		let seconds = dateComponents.second
		return Int(seconds!)
	}
    init(dateString: String) {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        if let d = dateStringFormatter.date(from: dateString) {
            self.init(timeInterval: 0, since: d)
        } else {
			let defaultdate = dateStringFormatter.date(from: "1971-10-01")
			self.init(timeInterval: 0, since: defaultdate!)
        }
    }
}
