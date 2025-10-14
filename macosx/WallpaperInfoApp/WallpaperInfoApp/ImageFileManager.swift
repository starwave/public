//
//  ImageFileManager.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/12/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation

class ImageFileManager {
	
    init() {
        resetFiles()
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
        objc_sync_exit(self._fileLock)
        stopWatching()
    }
    
    func stopWatching() {
        _writeInterrupt = true
        waitForListFileWriting()
        objc_sync_enter(_fileLock)
        if (_fileObserver != nil) {
            _fileObserver.stopWatching()
            _fileObserver = nil
        }
        objc_sync_exit(_fileLock)
    }
    
    func setSourceRootPath(_ sourceRootPath: String) {
        resetFiles()
        _writeInterrupt = false
        _sourceRootPath = sourceRootPath
		if (!BPUtil.fileExists(sourceRootPath)) {
			return
		}
        if (readListCache()) {
            objc_sync_enter(_fileLock)
            BPUtil.BPLog("ImageFileManager.readListCache.");
            WPath.setPlatformRootPath(path: _unclassifiedPaths.getWPath(at: 0).path)
            classifySourceByTheme()
            objc_sync_exit(_fileLock)
            _themeReady = true
        }
        _fileObserver = PlatformFileObserver(path:_sourceRootPath)
        _fileObserver.onEvent =  { event, wppath in
            switch event {
                case PlatformFileObserver.ADD:
					self.addWPath(wppath)
                    break
                case PlatformFileObserver.REMOVE:
					self.removePath(path:wppath.path)
                    break
                default:
                    return
            }
        }
        _fileObserver.fileWatchingStarted = { (sourcePaths) in
            BPUtil.BPLog("ImageFileManager.fileWatchingStarted.")
			self._wallpaperPaths = sourcePaths
            self.writeListCache(paths:self._wallpaperPaths, listCacheFile: self._wallpaperListCacheFile)
            objc_sync_enter(self._fileLock)
            // compare count to determine to use it over cache list.
            if (self._wallpaperPaths.count > self.getTotalImageCount()) {
                self.replaceCacheWithRealPaths(realPaths: self._wallpaperPaths)
            }
			objc_sync_exit(self._fileLock)
        }
		_fileObserver.exifReadFinished = { (exifFilePaths) in
            BPUtil.BPLog("ImageFileManager.exifReadFinished.")
            self._unclassifiedPaths = exifFilePaths
            self.writeListCache(paths:self._unclassifiedPaths, listCacheFile: self._photoListCacheFile)
            objc_sync_enter(self._fileLock)
            if (self._usingListCache) {
                self.replaceCacheWithRealPaths(realPaths: self._unclassifiedPaths, realPaths2: self._wallpaperPaths)
            } else {
                self.classifySourceByTheme()
            }
			objc_sync_exit(self._fileLock)
        }
        // it's background scanning. _themeReady flag will protect to access the file source during scanning
        // It will call fileWatchingStarted when it's done
        BPUtil.BPLog("ImageFileManager.setSourceRootPath at " + sourceRootPath)
        _fileObserver.startWatching()
    }
    
    private func getRandomPathFromSource() -> WPath? {
		if (_themePaths == nil || _usedPaths == nil) {
            BPUtil.BPLog("_sourcePaths shouldn't be nil.")
			return nil
		}
		objc_sync_enter(_fileLock)
		if (_themePaths.count <= 0) {
			// Rewind from the beginning
			rewindSource()
			if (_themePaths.count <= 0) {
				// when there is no images;
                BPUtil.BPLog("Error: There is no theme image in entire source.");
				objc_sync_exit(_fileLock)
				return nil
			}
		}
		// pick new image path from source
		let index = Int.random(in: 0..<_themePaths.count);
		let newWPath = _themePaths.getWPath(at: index)
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
    }
    
    func retrievePathFromSource(pivotWPath:WPath?, offset:Int) -> WPath? {
		if (pivotWPath == nil || pivotWPath!.path == "" ) {
			return getRandomPathFromSource()
		}
		if (_lastUsedPaths == nil) {
            BPUtil.BPLog("_lastUsedPaths shouldn't be nil.")
			return nil
		}
		objc_sync_enter(_fileLock)
		let index = _lastUsedPaths.firstIndex(of: pivotWPath!.path)
		if (index == nil) {                                        // No matching image
			if (offset == -1) {
                BPUtil.BPLog("shouldn't happen when no index but offset is -1")
			}
			objc_sync_exit(_fileLock)
			return getRandomPathFromSource();
		} else if (index! + offset < 0) {                        // get previous at the first
			objc_sync_exit(_fileLock)
			return _lastUsedPaths.getWPath(at: 0)
		} else if (index! + offset < _lastUsedPaths.count) {     // get within the range
			objc_sync_exit(_fileLock)
			return _lastUsedPaths.getWPath(at: index! + offset)
		}
		objc_sync_exit(_fileLock)
		return getRandomPathFromSource();                     // get next at the last
    }
    
	private func addWPath(_ wppath: WPath) {
		if (_themePaths == nil) {
            BPUtil.BPLog("_sourcePaths shouldn't be None.")
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
            BPUtil.BPLog("_sourcePaths shouldn't be None.")
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
        BPUtil.BPLog("rewindSource is called.")
        _unclassifiedPaths = _usedPaths
        _usedPaths = WLinkedHashMap<String, String>()
        classifySourceByTheme()
		_themeReady = true
	}
	
	func prepareSourceForTheme() {
		_themeReady = false
		let wpsi = WallpaperServiceInfo.getInstance()
        let requestedThemeInfo = wpsi.getThemeInfo().copy() as! ThemeInfo
        BPUtil.BPLog("prepareSourceForTheme is called with " + requestedThemeInfo._theme.stringValue)
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
                BPUtil.BPLog("prepareSourceForTheme is done with " + requestedThemeInfo._theme.stringValue)
			}
			objc_sync_exit(self._fileLock)
		})
	}
    
    func isThemeReady() -> Bool {
        return _themeReady
    }
	
    func getImageStat(path: String) -> String {
		var index = _usedPaths.count + _unthemePaths.count
		objc_sync_enter(_fileLock)
		if let i = _lastUsedPaths.firstIndex(of: path) {  // current image is in the mid offset
			index = index - _lastUsedPaths.count + i
		}
		objc_sync_exit(_fileLock)
		return String(index + 1)  + " of " + String(getTotalImageCount())
    }
    
    func getTotalImageCount() -> Int {
		objc_sync_enter(_fileLock)
		let count = _usedPaths.count + _themePaths.count + _unthemePaths.count
		objc_sync_exit(_fileLock)
		return count
    }
	
    static func getDefaultSourceRootPath() -> String {
		return NSHomeDirectory() + "/Pictures"
    }

    private func readListCache() -> Bool {
        _usingListCache = false;
        _unclassifiedPaths.removeAll(keepCapacity: 0)
       if (BPUtil.fileExists(_wallpaperListCacheFile)) {
           BPUtil.BPLog("readListCache: reading wallpaper list cache file at \(_wallpaperListCacheFile)")
           waitForListFileWriting()
           if let reader = StreamReader(url: URL(fileURLWithPath:_wallpaperListCacheFile)) {
               if let path = reader.nextLine() {
                   if (path == _sourceRootPath) {
                       var line = reader.nextLine()
                       while(line != nil) {
                           let wpathInFile = line!.components(separatedBy: "\t")
                           _unclassifiedPaths.put(value: "", forKey: wpathInFile[0])
                           line = reader.nextLine()
                       }
                   }
               }
           }
       } else {
           BPUtil.BPLog("readListCache: no wallpaper list cache file")
       }
        if (BPUtil.fileExists(_photoListCacheFile)) {
            BPUtil.BPLog("readListCache: reading photo list cache file at \(_photoListCacheFile)")
            waitForListFileWriting()
            if let reader = StreamReader(url: URL(fileURLWithPath:_photoListCacheFile)) {
                if let path = reader.nextLine() {
                    if (path == _sourceRootPath) {
                        var line = reader.nextLine()
                        while(line != nil) {
                            let wpathInFile = line!.components(separatedBy: "\t")
                            let exif = wpathInFile.count > 1 ? wpathInFile[1] : ""
                            _unclassifiedPaths.put(value: exif, forKey: wpathInFile[0])
                            line = reader.nextLine()
                        }
                    }
                }
            }
        } else {
            BPUtil.BPLog("readListCache: no photo list cache file")
        }
       _usingListCache = _unclassifiedPaths.count > 0;
        return _usingListCache;
    }

    // nil to delete
    private func writeListCache(paths:WLinkedHashMap<String, String>?, listCacheFile:String) {
        if (paths != nil) {
            waitForListFileWriting()
            _writeFileGroup = DispatchGroup()
            _writeFileGroup!.enter()
            DispatchQueue.global(qos: .background).async {
                do {
                    BPUtil.BPLog("writeListCache \(listCacheFile) started")
                    let listCacheFileUrlTemp = URL(fileURLWithPath:listCacheFile+".tmp")
                    guard let outputStream = OutputStream(url: listCacheFileUrlTemp, append: false) else { return }
                    outputStream.open()
                    try outputStream.write(self._sourceRootPath + "\n")
                    var iter = paths!.makeIterator()
                    while let wpath = iter.nextWPath() {
                        if (self._writeInterrupt) {
                            BPUtil.BPLog("writeListCache is interrupted for \(listCacheFile)")
                            break
                        }
                        try outputStream.write(wpath.path + "\t" + wpath.exif + "\n")
                    }
                    outputStream.close()
                    if (!self._writeInterrupt) {
                        if (BPUtil.fileExists(listCacheFile)) {
                            try FileManager.default.removeItem(atPath: listCacheFile)
                        }
                        try FileManager.default.moveItem(atPath: listCacheFile + ".tmp", toPath: listCacheFile)
                    } else {
                        try FileManager.default.removeItem(at: listCacheFileUrlTemp)
                    }
                    BPUtil.BPLog("writeListCache \(listCacheFile) ended")
                } catch {
                    print(error)
                    return
                }
                self._writeFileGroup!.leave()
            }
        }
    }
    
    private func waitForListFileWriting() {
        if let writeFileGroup = _writeFileGroup {
            BPUtil.BPLog("waitForListFileWriting started")
            writeFileGroup.wait()
            BPUtil.BPLog("waitForListFileWriting ended")
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
         WallpaperWidgetProvider.updateLabelWidget(text: "Image list is updated.")
    }
    
    private var _fileObserver: PlatformFileObserver!
    private var _unclassifiedPaths: WLinkedHashMap<String, String>!
    private var _wallpaperPaths: WLinkedHashMap<String, String>!
    private var _themePaths: WLinkedHashMap<String, String>!
    private var _unthemePaths: WLinkedHashMap<String, String>!
    private var _usedPaths: WLinkedHashMap<String, String>!
    private var _lastUsedPaths: WLinkedHashMap<String, String>!
    private var _sourceRootPath: String!
	private var _themeReady = false
    private var _usingListCache = false
    private var _writeInterrupt = false
    private var _writeFileGroup:DispatchGroup? = nil
    private let _wallpaperListCacheFile = BPUtil.getHomeDirectory() + "/Documents/.wallpaper_list.txt"
    private let _photoListCacheFile = BPUtil.getHomeDirectory() + "/Documents/.photo_list.txt"
    // only for Mac OS X
    private var _fileLock = NSObject()
}

typealias WLinkedHashMap = LinkedHashMap
extension WLinkedHashMap {
	func getWPath(at index:Int) -> WPath {
		if let key = self.keys[index] as? String {
			if let value = self[self.keys[index]] as? String {
				return WPath(path: key, exif: value)
			}
		}
		assertionFailure("Error - Fail to get WPath from WLinkedHashMap")
		return WPath(path: "", exif: "")
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
