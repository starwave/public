//
//  RecursiveFileObserver.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/11/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation

class PlatformFileObserver {
    
    init(path:String) {
        _sourceRootPath = path
        _fileWatcher = FileWatcher([path])
        onEvent = { (intParm, pathParm) in }
        fileWatchingStarted = { (sourceFilePath) in }
        exifReadFinished = { (exifFilePath) in }
        _sourcePaths = WLinkedHashMap<String, String>()
        _exifPaths = WLinkedHashMap<String, String>()
    }

    deinit {
        self.stopWatching()
    }
    
    func startWatching() {
        if (_fileWatcher.hasStarted) {
            BPUtil.BPLog("Error: startWatching - It's already watching files")
            return
        }
        _interrupt = false
        DispatchQueue.global(qos: .background).async {
            var stack:Stack = Stack<String>();
            stack.push(self._sourceRootPath!);
            self._sourcePaths = WLinkedHashMap<String, String>();
            let fileManager = FileManager.default
            while !stack.empty {
                let parent:String = stack.pop()!;
                do {
                    let filePaths = try fileManager.contentsOfDirectory(atPath: parent)
                    for filePath in filePaths {
                        if (filePath.starts(with:".")) {
                            continue
                        }
                        let fileUrl = URL(fileURLWithPath: parent + "/" + filePath)
                        let isDir = (try fileUrl.resourceValues(forKeys: [.isDirectoryKey])).isDirectory!
                        
                        if isDir {
                            stack.push(parent + "/" + filePath)
                        } else {
                            let pathExtension = fileUrl.pathExtension
                            if (pathExtension.caseInsensitiveCompare("jpg") == .orderedSame) {
                                let full_path = parent + "/" + filePath
								if (full_path.contains("/BP Photo/")) {
									self._exifPaths.put(value: "", forKey: full_path)
								} else {
									self._sourcePaths.put(value: "", forKey: full_path)
								}
                            }
                        }
                    }
                } catch {
                    continue
                }
            }
            // event.path, event.flag, event.description
            // kFSEventStreamEventFlagItemRenamed, kFSEventStreamEventFlagItemCreated, kFSEventStreamEventFlagItemRemoved
            // TODO Not handled yet : dirCreated, **dirRemoved**, dirRenamed, dirModified, fileModified
            self._fileWatcher.callback = { event in
                if (event.created) {
                    BPUtil.BPLog("File Change: CREATE \(event.path)")
                    self.addPathInternal(path: event.path)
                } else if (event.removed) {
                    BPUtil.BPLog("File Change: DELETE \(event.path)")
                    self.onEvent(PlatformFileObserver.REMOVE, WPath(path: event.path, exif: ""))
                } else if (event.renamed) {
                    let fileExists:Bool = FileManager.default.fileExists(atPath: event.path)
                    if (fileExists) {
                        BPUtil.BPLog("File Change: MOVED_TO \(event.path)")
						self.addPathInternal(path: event.path)
                    } else {
                        BPUtil.BPLog("File Change: MOVED_FROM \(event.path)")
                        self.onEvent(PlatformFileObserver.REMOVE, WPath(path: event.path, exif: ""))
                    }
                }
				// TODO Modify should be handled for exif update later
            }
            self._fileWatcher.start()
            if (self._sourcePaths.count > 0) {
                WPath.setPlatformRootPath(path: self._sourcePaths.getWPath(at: 0).path)
            }
			self.fileWatchingStarted(self._sourcePaths)
			self.exifReadStart()
        }
    }
    
    func stopWatching() {
        _interrupt = true
        if _fileWatcher.hasStarted {
            _fileWatcher.stop()
        }
    }
    
	private func addPathInternal(path: String) {
		let pathExtension = URL(fileURLWithPath: path).pathExtension
		if (pathExtension == "jpg") {
			if (path.contains("/BP Photo/")) {
				let exif = BPUtil.getExifDescription(path: path)
				onEvent(PlatformFileObserver.ADD, WPath(path: path, exif: exif))
			} else {
				onEvent(PlatformFileObserver.ADD, WPath(path: path, exif: ""))
			}
		}
	}
	
	private func exifReadStart() {
		for exifPathDict in _exifPaths {
            if (_interrupt) {
                BPUtil.BPLog("exifReadStart is interrupted.")
                return; // must return without calling callback since it's not complete scan
            }
			let path = exifPathDict.0
            let exif = BPUtil.getExifDescription(path: path)
			_exifPaths[path] = exif
		}
        if (_sourcePaths.count == 0 && _exifPaths.count > 0) {
            WPath.setPlatformRootPath(path: _exifPaths.getWPath(at: 0).path)
        }
		exifReadFinished(self._exifPaths)
	}
	
    var _fileWatcher: FileWatcher
    var _sourcePaths: WLinkedHashMap<String, String>
    var _exifPaths: WLinkedHashMap<String, String>
    var _sourceRootPath: String?
    var _interrupt = true
    var onEvent:((Int, WPath) -> Void)
    var fileWatchingStarted:((WLinkedHashMap<String, String>) -> Void)
    var exifReadFinished:((WLinkedHashMap<String, String>) -> Void)

	// Only for Windows & Mac OS X
    static var MOVED_FROM:Int = 0x00000040
    static var MOVED_TO:Int = 0x00000080
    static var CREATE:Int = 0x00000100
    static var DELETE:Int = 0x00000200
	static var ADD:Int = 0x00000180 // MOVED_TO | CREATE
	static var REMOVE:Int = 0x00000240 // MOVED_FROM | DELETE

}
