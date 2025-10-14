//
//  ImageFileManager.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/12/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import UIKit

class ImageFileManager {
	
    init() {
    }

    func resetFiles() {
        objc_sync_enter(self._fileLock)
        _themeReady = false
        _unclassifiedPaths = WLinkedHashMap<String, String>() // will be overridden
        _wallpaperPaths = WLinkedHashMap<String, String>() // will be overridden
        _themePaths = WLinkedHashMap<String, String>()
        _unthemePaths = WLinkedHashMap<String, String>()
        _usedPaths = WLinkedHashMap<String, String>()
        _lastUsedPaths = WLinkedHashMap<String, String>()
        let wpsi = WallpaperServiceInfo.getInstance()
        wpsi.setLastUsedPaths(_lastUsedPaths);
        _sourceRootPath = BPUtil.getHomeDirectoryUrl().appendingPathComponent("CloudStation/" + wpsi.getSourceRootPath()).path
        objc_sync_exit(self._fileLock)
    }
    
    func saveCurrentListCache() {
        var tempWallpaperPaths = WLinkedHashMap<String, String>()
        var tempPhotoPaths = WLinkedHashMap<String, String>()
        objc_sync_enter(_fileLock)
        for wpaths in [self._themePaths, self._unthemePaths, self._usedPaths] {
            var iter = wpaths!.makeIterator()
            while let wppath = iter.nextWPath() {
                if wppath.path.firstIndex(of :"/BP Wallpaper/") != nil {
                    tempWallpaperPaths.put(value: wppath.exif, forKey: wppath.path);
                } else if wppath.path.firstIndex(of :"/BP Photo/") != nil {
                    tempPhotoPaths.put(value: wppath.exif, forKey: wppath.path);
                }
            }
        }
        objc_sync_exit(_fileLock)
        self.writeListCache(paths:tempWallpaperPaths, listCacheFile: self._wallpaperListCacheFile)
        self.writeListCache(paths:tempPhotoPaths, listCacheFile: self._photoListCacheFile)
    }
	
    func setSourceRootPath() {
        resetFiles()
        _writeInterrupt = false
        if (!BPUtil.fileExists(_sourceRootPath)) {
            if !BPUtil.ensureDirectories(for: URL(fileURLWithPath: _sourceRootPath)) {
                print("ImageFileManager: error during root directory creation at " + _sourceRootPath)
                return
            }
        }
        if (readListCache()) {
            objc_sync_enter(_fileLock)
            print("ImageFileManager.readListCache.");
            WPath.setPlatformRootPath(path: _unclassifiedPaths.getWPath(at: 0)!.path)
            classifySourceByTheme()
            objc_sync_exit(_fileLock)
            _themeReady = true
        }        
        _platformFileManager.fileReadFinished = { (filePaths) in
            print("ImageFileManager: fileReadFinished.")
            self._wallpaperPaths = filePaths
            self.writeListCache(paths:self._wallpaperPaths, listCacheFile: self._wallpaperListCacheFile)
            objc_sync_enter(self._fileLock)
            // compare count to determine to use it over cache list.
            if (self._wallpaperPaths.count > self.getTotalImageCount()) {
                self.replaceCacheWithRealPaths(realPaths: self._wallpaperPaths)
            }
            objc_sync_exit(self._fileLock)
        }
        _platformFileManager.exifReadFinished = { (exifPaths) in
            print("ImageFileManager: exifReadFinished")
            self._unclassifiedPaths = exifPaths
            self.writeListCache(paths:self._unclassifiedPaths, listCacheFile: self._photoListCacheFile)
            objc_sync_enter(self._fileLock)
            if (self._usingListCache) {
                self.replaceCacheWithRealPaths(realPaths: self._unclassifiedPaths, realPaths2: self._wallpaperPaths)
            } else {
                self.classifySourceByTheme()
            }
            objc_sync_exit(self._fileLock)
            self.syncServerFiles()
        }
        _platformFileManager.startSyncedFilesScanning(sourceRootPath: _sourceRootPath)
        print("ImageFileManager: setSourceRootPath _sourceRootPath at " + _sourceRootPath)
    }
    
	func notifyGetRandomPathFromSourceDone(newWPath:WPath, image:UIImage?, cacheFile: String?) -> Bool {
		// realtime
		if let valid_image = image {
			if (!_platformFileManager.addCacheFile(image: valid_image, serverPath: newWPath.path)) {
				return false
			}
		// cache
		} else {
			if (!_platformFileManager.addCacheFile(cacheFile: cacheFile!, serverPath: newWPath.path)) {
				return false
			}
		}
        // (in case source is small) Check if new path is still in last used path, then remove it to avoid the loop.
		_lastUsedPaths.removeValueForKey(key: newWPath.path)
		// add to lastusedpaths & mainatain size for _lastUsedPaths
		_lastUsedPaths.put(value: newWPath.exif, forKey: newWPath.path)
		if (_lastUsedPaths.count > WallpaperService._maxLastUsedPaths) {
			if let localFileToRemove = _lastUsedPaths.getWPath(at: 0) {
				if (_platformFileManager.removeCacheFileWithServerPath(serverPath: localFileToRemove.path)) {
					_lastUsedPaths.remove(at: 0)
				} else {
					print("Error: Removing the oldest cache file failed.")
				}
			}
        }
        // add to used path
		_usedPaths.put(value: newWPath.exif, forKey: newWPath.path)
		let themeInfo = WallpaperServiceInfo.getInstance().getThemeInfo()
		//following check is needed in case theme is changed during download
		return themeInfo.isThemeImage(coden: newWPath.coden())
	}
    
    func getLocalImageFromServerPath(serverPath: String) -> UIImage? {
        return _platformFileManager.getCacheImageFromServerPath(serverPath: serverPath)
    }
    
    private func getRandomPathFromSource() -> WPath? {
        if (_usedPaths == nil) {
            print("Error: _usedPaths shouldn't be null.")
            return nil
        }
		let wpsi = WallpaperServiceInfo.getInstance()
        if (wpsi.getOfflineMode()) {
            objc_sync_enter(_fileLock)
            if (_themePaths.count <= 0) {
                // Rewind from the beginning
                rewindSource()
                if (_themePaths.count <= 0) {
                    // when there is no images;
                    print("Error: There is no theme image in entire source.");
                    objc_sync_exit(_fileLock)
                    return nil
                }
            }
            // pick new image path from source
            let index = Int.random(in: 0..<_themePaths.count);
            let newWPath = _themePaths.getWPath(at: index)!
            // remove from source path
            _themePaths.removeValueForKey(key: newWPath.path)
            // (in case source is small) Check if new path is still in last used path, then remove it to avoid the loop.
            _lastUsedPaths.removeValueForKey(key: newWPath.path)
            // add to last used path
            _lastUsedPaths.put(value: newWPath.exif, forKey: newWPath.path);
            // mainatain size for _lastUsedPaths
            if (_lastUsedPaths.count > WallpaperService._maxLastUsedPaths) {
                _lastUsedPaths.remove(at: 0)
            }
            // add to used path
            _usedPaths.put(value: newWPath.exif, forKey: newWPath.path)
            objc_sync_exit(_fileLock)
            return newWPath
        } else {
            NgorongoroInterface.getNewImage(themeInfo: wpsi.getThemeInfo())
            return ImageFileManager._new_file_from_server_by_theme
        }
    }
    
    func retrievePathFromSource(pivotWPath:WPath?, offset:Int) -> WPath? {
		if (pivotWPath == nil || pivotWPath!.path == "" ) {
            return getRandomPathFromSource()
        }
        if (_lastUsedPaths == nil) {
            print("Error - _lastUsedPaths shouldn't be null.")
            return nil
        }
		let index = _lastUsedPaths.firstIndex(of: pivotWPath!.path)
        if (index == nil) {                                        // No matching image
            if (offset == -1) {
                print("Error - shouldn't happen when no index but offset is -1");
            }
            return getRandomPathFromSource();
        } else if (index! + offset < 0) {                        // get previous at the first
			return _lastUsedPaths.getWPath(at:0)
        } else if (index! + offset < _lastUsedPaths.count) {     // get within the range
			return _lastUsedPaths.getWPath(at:index! + offset)
        }
        return getRandomPathFromSource();                     // get next at the last
    }
    
    private func addWPath(_ wppath: WPath) {
        if (_themePaths == nil) {
            print("_themePaths shouldn't be None.")
            return;
        }
        objc_sync_enter(_fileLock)
        let wpsi = WallpaperServiceInfo.getInstance()
        let themeInfo = wpsi.getThemeInfo()
        if (themeInfo.isThemeImage(coden: wppath.coden())) {
            _themePaths.put(value: wppath.exif, forKey: wppath.path);
        } else {
            _unthemePaths.put(value: wppath.exif, forKey: wppath.path);
        }
        objc_sync_exit(_fileLock)
    }
    
    private func removePath(path: String) {
        if (_themePaths == nil || _usedPaths == nil) {
            print("_sourcePaths shouldn't be None.")
            return;
        }
        objc_sync_enter(_fileLock)
        _lastUsedPaths.removeValueForKey(key: path)
        _themePaths.removeValueForKey(key: path)
        _unthemePaths.removeValueForKey(key: path)
        _usedPaths.removeValueForKey(key: path)
        objc_sync_exit(_fileLock)
    }
    
    func classifySourceByTheme() {
        let wpsi = WallpaperServiceInfo.getInstance()
        wpsi.getThemeInfo().classifyPathsByTheme(
            source: _unclassifiedPaths,
            theme: &_themePaths,
            untheme: &_unthemePaths)
    }
    
    private func rewindSource() {
        _themeReady = false
        print("rewindSource is called.")
        _unclassifiedPaths = _usedPaths
        _usedPaths = WLinkedHashMap<String, String>()
        classifySourceByTheme()
        _themeReady = true
    }
    
    func prepareSourceForTheme() {
        _themeReady = false
        let wpsi = WallpaperServiceInfo.getInstance()
        let requestedThemeInfo = wpsi.getThemeInfo().copy() as! ThemeInfo
        print("prepareSourceForTheme is called with " + requestedThemeInfo._theme.stringValue)
        DispatchQueue.background(delay: 1.1, completion:{
            //print("prepareSourceForTheme enters dispatchqueue with " + requestedThemeInfo._theme.stringValue)
            objc_sync_enter(self._fileLock)
            //print("prepareSourceForTheme enters _fileLock with " + requestedThemeInfo._theme.stringValue)
            if (requestedThemeInfo.equals(wpsi.getThemeInfo())) {
                //print("prepareSourceForTheme execution starts with " + requestedThemeInfo._theme.stringValue)
                self._unclassifiedPaths = self._themePaths
                let backupPaths = self._unthemePaths
                self._themePaths = WLinkedHashMap<String, String>()
                self._unthemePaths = WLinkedHashMap<String, String>()
                self.classifySourceByTheme()
                self._unclassifiedPaths = backupPaths
                self.classifySourceByTheme()
                self._themeReady = true
                print("prepareSourceForTheme is done with " + requestedThemeInfo._theme.stringValue)
            }
            objc_sync_exit(self._fileLock)
        })
    }
    
    func isThemeReady() -> Bool {
        return _themeReady
    }
    
    func getTotalImageCount() -> Int {
        objc_sync_enter(_fileLock)
        let count = _usedPaths.count + _themePaths.count + _unthemePaths.count
        objc_sync_exit(_fileLock)
        return count
    }
    
    private func readListCache() -> Bool {
        _usingListCache = false
        _unclassifiedPaths.removeAll(keepCapacity: 0)
        
        // Read wallpaper list cache
        if FileManager.default.fileExists(atPath: _wallpaperListCacheFile) {
            print("readListCache: reading wallpaper list cache file at \(_wallpaperListCacheFile)")
            waitForListFileWriting()
            if let reader = StreamReader(url: URL(fileURLWithPath: _wallpaperListCacheFile)) {
                // TODO: restore  _sourceRootPath.contains(path) to compare root_path
                if let _ = reader.nextLine() {
                    while let line = reader.nextLine() {
                        let wpathInFile = line.components(separatedBy: "\t")
                        _unclassifiedPaths[WallpaperService._offlineImagesRoot.path + "/" + wpathInFile[0]] = ""
                    }
                }
            }
        } else {
            print("readListCache: no wallpaper list cache file")
        }
        
        // Read photo list cache
        if FileManager.default.fileExists(atPath: _photoListCacheFile) {
            print("readListCache: reading photo list cache file at \(_photoListCacheFile)")
            waitForListFileWriting()
            if let reader = StreamReader(url: URL(fileURLWithPath: _photoListCacheFile)) {
                // TODO: restore  _sourceRootPath.contains(path) to compare root_path
                if let _ = reader.nextLine() {
                    while let line = reader.nextLine() {
                        let wpathInFile = line.components(separatedBy: "\t")
                        let exif = wpathInFile.count > 1 ? wpathInFile[1] : ""
                        _unclassifiedPaths[WallpaperService._offlineImagesRoot.path + "/" + wpathInFile[0]] = exif
                    }
                }
            }
        } else {
            print("readListCache: no photo list cache file")
        }
        
        _usingListCache = _unclassifiedPaths.count > 0
        print("readListCache: count = \(_unclassifiedPaths.count)")
        return _usingListCache
    }
    
    private func writeListCache(paths: WLinkedHashMap<String, String>?, listCacheFile: String) {
        guard let paths = paths else { return }
        waitForListFileWriting()
        _writeFileGroup = DispatchGroup()
        _writeFileGroup!.enter()
        DispatchQueue.global(qos: .background).async {
            do {
                print("writeListCache: \(listCacheFile) started")
                let listCacheFileUrlTemp = URL(fileURLWithPath: listCacheFile + ".tmp")
                guard let outputStream = OutputStream(url: listCacheFileUrlTemp, append: false) else { return }
                outputStream.open()
                let relative_root = BPUtil.relativePath(with: URL(fileURLWithPath: self._sourceRootPath), from: WallpaperService._offlineImagesRoot)
                let sourceRootPathData = (relative_root + "\n").data(using: .utf8)!
                let data = sourceRootPathData
                data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
                    if let baseAddress = bytes.baseAddress {
                        let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
                        let _ = outputStream.write(pointer, maxLength: data.count)
                    }
                }
                var iter = paths.makeIterator()
                while let wpath = iter.nextWPath() {
                    if self._writeInterrupt {
                        print("writeListCache: is interrupted for \(listCacheFile)")
                        break
                    }
                    let relative_path = BPUtil.relativePath(with: URL(fileURLWithPath: wpath.path), from: WallpaperService._offlineImagesRoot)
                    let line = "\(relative_path)\t\(wpath.exif)\n"
                    let lineData = line.data(using: .utf8)!
                    lineData.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
                        if let baseAddress = bytes.baseAddress {
                            let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
                            let _ = outputStream.write(pointer, maxLength: lineData.count)
                        }
                    }
                }
                outputStream.close()
                if !self._writeInterrupt {
                    if BPUtil.fileExists(listCacheFile) {
                        try FileManager.default.removeItem(atPath: listCacheFile)
                    }
                    try FileManager.default.moveItem(atPath: listCacheFile + ".tmp", toPath: listCacheFile)
                } else {
                    try FileManager.default.removeItem(at: listCacheFileUrlTemp)
                }
                print("writeListCache: \(listCacheFile) ended")
            } catch {
                print("writeListCache: Error writing to file: \(error)")
            }
            self._writeFileGroup!.leave()
        }
    }
    
    private func waitForListFileWriting() {
        if let writeFileGroup = _writeFileGroup {
            print("waitForListFileWriting started")
            writeFileGroup.wait()
            print("waitForListFileWriting ended")
        }
    }
    
    private func replaceCacheWithRealPaths(realPaths: WLinkedHashMap<String, String>, realPaths2: WLinkedHashMap<String, String>? = nil) {
         _themeReady = false;
         _unclassifiedPaths = realPaths;
        _themePaths.removeAll(keepCapacity: 0)
         _unthemePaths.removeAll(keepCapacity: 0)
         classifySourceByTheme()
        if (realPaths2 != nil) {
            _unclassifiedPaths = realPaths2;
            classifySourceByTheme();
        }
        var iter = _usedPaths.makeIterator()
        while let wpath = iter.nextWPath() {
            // remove from _themePaths which was already used from cache
            _themePaths.removeValueForKey(key: wpath.path)
        }
         _usingListCache = false
         _themeReady = true
        let wpsi = WallpaperServiceInfo.getInstance()
        wpsi.getWallpaperService().updateLabelWidget(labelString: "Image list is updated.")
    }
    
    func syncServerFiles() {
        let wpsi = WallpaperServiceInfo.getInstance()
        let fileManager = FileSyncManager(serverBase: wpsi.getSourceRootPath(), force: false)
        wpsi.setIsSyncing(true)
        fileManager.syncFiles(fileSyncDoneCallback: {
            wpsi.setIsSyncing(false)
            print("ImageFileManager: file sync is finished")
            self.saveCurrentListCache()
        }, onEvent: { (event, wppath) in
            switch event {
                case FileSyncManager.ADD:
                    print("ImageFileManager: added = \(wppath.path)")
                    self.addWPath(wppath)
                    break
                case FileSyncManager.REMOVE:
                    print("ImageFileManager: removed = \(wppath.path)")
                    self.removePath(path:wppath.path)
                    break
                case FileSyncManager.MODIFIED:
                    print("ImageFileManager: modified = \(wppath.path)")
                    self.removePath(path:wppath.path)
                    self.addWPath(wppath)
                    break
                default:
                    return
            }
        })
    }
	
	private var _platformFileManager: PlatformFileManager = PlatformFileManager()
    private var _unclassifiedPaths: WLinkedHashMap<String, String>!
    private var _wallpaperPaths: WLinkedHashMap<String, String>!
    private var _themePaths: WLinkedHashMap<String, String>!
    private var _unthemePaths: WLinkedHashMap<String, String>!
    private var _usedPaths: WLinkedHashMap<String, String>!
    private var _lastUsedPaths: WLinkedHashMap<String, String>!
    private var _sourceRootPath: String = ""
    private var _themeReady = false
    private var _usingListCache = false
    private var _writeFileGroup:DispatchGroup? = nil
    private var _writeInterrupt = false
	static let _new_file_from_server_by_theme = WPath(coden: "new_file_from_server_by_theme")
    private let _wallpaperListCacheFile = BPUtil.getHomeDirectory() + "/.wallpaper_list.txt"
    private let _photoListCacheFile = BPUtil.getHomeDirectory() + "/.photo_list.txt"
    // only for Mac OS X, iOS
    private var _fileLock = NSObject()
}

typealias WLinkedHashMap = LinkedHashMap
extension WLinkedHashMap {
	func getWPath(at index:Int) -> WPath? {
		if let key = self.keys[index] as? String {
			if let value = self[self.keys[index]] as? String {
				return WPath(path: key, exif: value)
			}
		}
        assertionFailure("Error - Fail to get WPath from WLinkedHashMap")
        return nil
	}
}

extension LinkedHashMapIterator {
    mutating func nextWPath() -> WPath? {
        if let (k, v) = next() {
            return WPath(path:k as! String, exif:v as! String)
        } else {
            return nil
        }
    }
}

class StreamReader {
    private let fileHandle: FileHandle
    private let delimiter: Data
    private var buffer: Data
    private var atEof: Bool

    init?(url: URL, delimiter: String = "\n") {
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else { return nil }
        self.fileHandle = fileHandle
        self.delimiter = delimiter.data(using: .utf8)!
        self.buffer = Data(capacity: 4096)
        self.atEof = false
    }

    deinit {
        fileHandle.closeFile()
    }

    func nextLine() -> String? {
        if atEof { return nil }
        repeat {
            if let range = buffer.range(of: delimiter) {
                let line = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
                buffer.removeSubrange(buffer.startIndex..<range.upperBound)
                return String(data: line, encoding: .utf8)
            }
            let tempData = fileHandle.readData(ofLength: 4096)
            if tempData.count > 0 {
                buffer.append(tempData)
            } else {
                atEof = true
                if !buffer.isEmpty {
                    let line = buffer
                    buffer = Data()
                    return String(data: line, encoding: .utf8)
                }
            }
        } while !atEof
        return nil
    }
}
