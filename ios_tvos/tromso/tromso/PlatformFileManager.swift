//
//  PlatformFileManager.swift
//  tromso
//
//  Created by Brad Park on 5/19/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import UIKit

class PlatformFileManager {
	
    init() {
        fileReadFinished = { (sourceFilePath) in }
        exifReadFinished = { (exifFilePath) in }
        print("PlatformFileManager: init _localCacheDir at " + PlatformFileManager._localCacheDir.absoluteString)
		removeAllCacheFiles()
	}
	
	func getCacheImageFromServerPath(serverPath: String) -> UIImage? {
		if let localFilePath = getCacheFilePathWithServerPath(serverPath) {
			let fileurl = PlatformFileManager._localCacheDir.appendingPathComponent(localFilePath)
			if let data = try? Data(contentsOf: fileurl) {
				let image = UIImage(data: data)
				return image
			}
		}
		return nil
	}
	
	func getCacheFilePathWithServerPath(_ serverPath: String) -> String? {
		if let localFilePath = _cacheFilePaths[serverPath] {
			return localFilePath
		}
		return nil
	}
	
	func addCacheFile(image:UIImage, serverPath:String) -> Bool {
		let fileName = NgorongoroInterface.getNewCacheFileName(prefix:"f_", postfix:"nocache")
		if saveCacheFile(localImage: image, localFileName: fileName) {
			_cacheFilePaths.updateValue(fileName, forKey: serverPath)
			return true
		}
		return false
	}
	
	func addCacheFile(cacheFile:String, serverPath:String) -> Bool {
		_cacheFilePaths.updateValue(cacheFile, forKey: serverPath)
		return true
	}
	
	func removeCacheFileWithServerPath(serverPath:String) -> Bool {
		if let cachePath = _cacheFilePaths[serverPath] {
			do {
				let fileManager = FileManager.default
				let localFileURL = PlatformFileManager._localCacheDir.appendingPathComponent(cachePath)
				try fileManager.removeItem(at: localFileURL)
				_cacheFilePaths.removeValue(forKey: serverPath)
				print("File " + localFileURL.absoluteString + " is removed successfully")
				return true
			} catch {
				print("Error: Can't delete the oldest cache file.")
			}
		}
		return false
	}
	
	private func saveCacheFile(localImage: UIImage, localFileName:String) -> Bool {
		if let data = localImage.jpegData(compressionQuality: 1.0) {
			let cachePath = PlatformFileManager._localCacheDir.appendingPathComponent(localFileName)
			try? data.write(to: cachePath)
			return true
		}
		return false
	}
	
	private func removeAllCacheFiles() {
		do {
			let fileManager = FileManager.default
			if (BPUtil.fileExists(PlatformFileManager._localCacheDir.path)) {
				do {
					try fileManager.removeItem(at: PlatformFileManager._localCacheDir)
					print("Delete existing cache directory.")
				} catch {
					let fileURLs = try FileManager.default.contentsOfDirectory(at: PlatformFileManager._localCacheDir,
																			   includingPropertiesForKeys: nil,
																			   options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
					for fileURL in fileURLs {
						if fileURL.pathExtension == "jpg" {
							try FileManager.default.removeItem(at: fileURL)
						}
					}
					print("Delete all cache files in existing directory.")
				}
			}
			try fileManager.createDirectory(at: PlatformFileManager._localCacheDir, withIntermediateDirectories: true, attributes: nil)
		} catch {
			print("Error: Can't create or clean up cache files.")
		}
	}
    
    func startSyncedFilesScanning(sourceRootPath: String) {
        DispatchQueue.global(qos: .background).async {
            self._sourceRootPath = sourceRootPath
            let syncedFilePaths = BPUtil.getAllLocalFiles(in:URL(fileURLWithPath: self._sourceRootPath))
            self._sourcePaths = WLinkedHashMap<String, String>()
            if (syncedFilePaths.count > 0) {
                for syncedFilePath in syncedFilePaths {
                    let synchedFileFullpath = URL(fileURLWithPath: sourceRootPath).appendingPathComponent(syncedFilePath)
                    let pathExtension = synchedFileFullpath.pathExtension
                    if (pathExtension.caseInsensitiveCompare("jpg") == .orderedSame) {
                        if (synchedFileFullpath.path.contains("/BP Photo/")) {
                            // print("PHOTO:" + syncedFilePath)
                            self._exifPaths.put(value: "", forKey: synchedFileFullpath.path)
                        } else {
                            // print("Wallpaper:" + syncedFilePath)
                            self._sourcePaths.put(value: "", forKey: synchedFileFullpath.path)
                        }
                    }
                }
            }
            if (self._sourcePaths.count > 0) {
                WPath.setPlatformRootPath(path: self._sourcePaths.getWPath(at: 0)!.path)
            }
            self.fileReadFinished(self._sourcePaths)
            self.exifReadStart()
        }
    }
    
    private func exifReadStart() {
        // print("exifReadStart: \(_exifPaths.count)")
        for exifPathDict in _exifPaths {
            if (_interrupt) {
                print("exifReadStart is interrupted.")
                return; // must return without calling callback since it's not complete scan
            }
            let path = exifPathDict.0
            let exif = BPUtil.getExifDescription(path: path)
            _exifPaths[path] = exif
        }
        if (_sourcePaths.count == 0 && _exifPaths.count > 0) {
            WPath.setPlatformRootPath(path: _exifPaths.getWPath(at: 0)!.path)
        }
        exifReadFinished(self._exifPaths)
    }

    private var _sourcePaths: WLinkedHashMap<String, String> = WLinkedHashMap<String, String>()
    private var _exifPaths: WLinkedHashMap<String, String> = WLinkedHashMap<String, String>()
    private var _sourceRootPath: String = ""
    var _interrupt = false
    var fileReadFinished:((WLinkedHashMap<String, String>) -> Void)
    var exifReadFinished:((WLinkedHashMap<String, String>) -> Void)
	private var _cacheFilePaths: Dictionary<String, String> = Dictionary<String, String>();
	public static let _maxLocalFileCount:Int = WallpaperService._maxLastUsedPaths
	public static let _maxLocalFileIndex:Int = _maxLocalFileCount * 5
	public static let _localCacheDir:URL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("wpcache", isDirectory: true)
}

