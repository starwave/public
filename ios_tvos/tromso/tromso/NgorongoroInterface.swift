//
//  NgorongoroInterface.swift
//  tromso_tv
//
//  Created by Brad Park on 8/12/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import UIKit

class NgorongoroInterface {
	
    private init() {
	}

    private static var sharedNgorongoroInterface: NgorongoroInterface = {
        let instance = NgorongoroInterface()
        return instance
    }()
    
    class func getInstance() -> NgorongoroInterface {
        return sharedNgorongoroInterface
    }
	
	class func getNewImage(themeInfo: ThemeInfo) {
		NgorongoroInterface.getInstance().getNewImage(themeInfo: themeInfo)
	}
	
	public func getNewImage(themeInfo: ThemeInfo) {
		if _nGorongoroCacheEnabled {
			if (getFromCache(themeInfo: themeInfo)) {
				return
			}
		}
        print("ng cache: request [*] (" +
            String(_explicitThemeCachePendingPaths.count) + "," +
            String(_spareThemeCachePendingPaths.count) + ") " + themeInfo._theme.stringValue)
		ngorongoro(themeString: themeInfo._theme.stringValue,
				   themeOption: themeInfo.getOption(),
				   onSuccess: { (valid_image, serverCoden) in
					let wpsi = WallpaperServiceInfo.getInstance()
					let service = wpsi.getWallpaperService()
					if service.setNewWallpaper(serverCoden: serverCoden, image: valid_image, cacheFile: nil) {
						print("Success: ngorongoro - Set Wallpaper with Ngorongoro Image")
					} else {
						print("Error: ngorongoro - Store Local File Error")
					}
		},
				   onFailure: { (error) in
					print("Error: ngorongoro - " + error)
		})
	}
	
	class func getNewCacheFileName(prefix:String, postfix:String) -> String {
		return NgorongoroInterface.getInstance().getNewCacheFileName(prefix:prefix, postfix:postfix)
	}
	
	public func getNewCacheFileName(prefix:String, postfix:String) -> String {
		_cacheNameIndex = (_cacheNameIndex + 1) % NgorongoroInterface._maxCacheNameIndex
		return prefix + String(format: "%06d", _cacheNameIndex) + "-" + postfix + ".jpg"
	}
    
	private func getFromCache(themeInfo: ThemeInfo) -> Bool {
        downloadCacheInBackground(themeInfo: _currentExplicitThemeInfo)
        objc_sync_enter(_cacheLock)
		// check theme is changed
        if (!themeInfo.equals(_currentExplicitThemeInfo)) {
            _cacheThemePaths.removeAll(keepCapacity: 0)
            _cacheUnthemePaths.removeAll(keepCapacity: 0)
            _explicitThemeCachePaths.removeAll(keepCapacity: 0)
			_historyPaths.removeAll(keepCapacity: 0)
			_consecutiveHitCount = 0
            themeInfo.classifyPathsByTheme(source: _cachePaths, theme: &_cacheThemePaths, untheme: &_cacheUnthemePaths)
            for path_dict in _cachePaths {
                let path_key = path_dict.0
                let path_value = path_dict.1
                // existing custom theme cache shouldn't be added to explict theme path due to config string difference
                if (themeInfo._theme != .custom && path_value.contains("-"+themeInfo._theme.stringValue+".jpg")) {
                  _explicitThemeCachePaths.put(value: path_value, forKey: path_key)
                }
            }
            _currentExplicitThemeInfo = themeInfo.copy() as! ThemeInfo
            print("ng cache: theme is updated with " + _currentExplicitThemeInfo._theme.label)
        }
        if (_cacheThemePaths.count > 0) {
            let index = Int.random(in: 0..<_cacheThemePaths.count)
            var serverPath = _cacheThemePaths.keys[index]
            var cacheFile = _cacheThemePaths.values[index]
            // explict cache is preferred but spare cache has starving issue.
            // So by 1/5 ratio, given non-explict cache will be chosen
            if (_explicitThemeCachePaths.count > 0 && _explicitThemeCachePaths[serverPath] == nil) {
                let ratio = Double(_cacheThemePaths.count - _explicitThemeCachePaths.count) / Double(_cacheThemePaths.count) * Double(_explicitThemeCachePaths.count) * 5.0
                let random_index = Int.random(in: 0..<Int(ratio))
                if (random_index >= _explicitThemeCachePaths.count) {
                    print("ng cache: cache [S->E] from " + cacheFile + " by ratio = " + String(ratio))
                    serverPath = _explicitThemeCachePaths.keys[random_index % _explicitThemeCachePaths.count]
                    cacheFile = _explicitThemeCachePaths.values[random_index % _explicitThemeCachePaths.count]
                } else {
                    print("ng cache: cache [S->S] with " + cacheFile + " by ratio = " + String(ratio))
                }
            } else {
				// == 0 means all S cache, != 0 means chosen path is E cache
                (_explicitThemeCachePaths.count == 0) ?
                    print("ng cache: cache [S] with " + cacheFile + " due to no explicit cache.") :
                    print("ng cache: cache [E] with " + cacheFile)
            }
            // following check is needed in case theme is changed during download or custom config is updated after cache is created
            if (!themeInfo.isThemeImage(coden: serverPath)) {
                print("ng cache: skip in getFromCache - give up cache and try realtime due to theme change - " + cacheFile)
                objc_sync_exit(_cacheLock)
                return false
            }
            _cacheThemePaths.removeValueForKey(key: serverPath)
            _explicitThemeCachePaths.removeValueForKey(key: serverPath)
            _cachePaths.removeValueForKey(key: serverPath)
            objc_sync_exit(_cacheLock)
            do {
                let cacheFileURL = PlatformFileManager._localCacheDir.appendingPathComponent(cacheFile)
                let localFileURL = PlatformFileManager._localCacheDir.appendingPathComponent("f" + cacheFile)
                try FileManager.default.moveItem(at: cacheFileURL, to: localFileURL)
            } catch {
                print("ng cache: error in getFromCache - renaming cache file - f" + cacheFile)
                return false
            }
            let service = WallpaperServiceInfo.getInstance().getWallpaperService()
			if service.setNewWallpaper(serverCoden: serverPath, image:nil, cacheFile: "f" + cacheFile) {
                return true
            }
            print("ng cache: error in getFromCache - Set Wallpaper with Ngorongoro Image")
            return false
        }
        objc_sync_exit(_cacheLock)
        return false
    }
	
	private func downloadCacheInBackground(themeInfo: ThemeInfo) {
        DispatchQueue.background(delay: 0.5, completion:{
			objc_sync_enter(self._downloadLock)
			// Clean Up timeout pending items - Workaound
			for pendingItem in self._spareThemeCachePendingPaths {
				if (Date().getDiffInSecond(since: pendingItem.1) > 10) {
					print("ng cache: timed out [S] with " + pendingItem.0)
					self._spareThemeCachePendingPaths.removeValueForKey(key: pendingItem.0)
				}
			}
			for pendingItem in self._explicitThemeCachePendingPaths {
				print("ng cache: timed out [E] with " + pendingItem.0)
				if (Date().getDiffInSecond(since: pendingItem.1) > 10) {
					self._explicitThemeCachePendingPaths.removeValueForKey(key: pendingItem.0)
				}
			}
            // Explicit Cache
			let givenThemeInfo = themeInfo.copy() as! ThemeInfo
			for _ in 1...NgorongoroInterface._maxExplicitThemeCachePendingCountPerRequest {
				if (!givenThemeInfo.equals(self._currentExplicitThemeInfo)) {
					print("ng cache: skip in downloadCacheInBackground - theme has changed during background downloading")
					break
				}
				if (!self.getCacheFile(themeInfo:givenThemeInfo,
							 currentCount:self._explicitThemeCachePaths.count + self._explicitThemeCachePendingPaths.count,
							 maxCount:NgorongoroInterface._maxExplicitThemeCacheCount,
							 cacheFileName:self.getNewCacheFileName(prefix:"c", postfix:givenThemeInfo._theme.stringValue),
							 isExplict:true)) {
					break
				}
				usleep(NgorongoroInterface._sleepTimeBetweenDownloads)
			}
            // Spare Cache
            for _ in 1...NgorongoroInterface._maxSpareCachePendingCountPerRequest {
				if (!self.getCacheFile(themeInfo:self._currentSpareThemeInfo,
							 currentCount:self._cachePaths.count + self._explicitThemeCachePendingPaths.count + self._spareThemeCachePendingPaths.count,
							 maxCount:NgorongoroInterface._maxCacheCount,
							 cacheFileName:self.getNewCacheFileName(prefix:"c", postfix: self._currentSpareThemeInfo._theme.stringValue),
					isExplict:false)) {
						break;
				}
				self._currentSpareThemeInfo = self._currentSpareThemeInfo.getNextThemeInfo()
                usleep(NgorongoroInterface._sleepTimeBetweenDownloads)
            }
            objc_sync_exit(self._downloadLock)
		})
	}
	
	private func getCacheFile(themeInfo:ThemeInfo, currentCount:Int, maxCount:Int, cacheFileName:String, isExplict:Bool) -> Bool {
		objc_sync_enter(_cacheLock)
		if (currentCount >= maxCount) ||
			_explicitThemeCachePendingPaths.count + _spareThemeCachePendingPaths.count >= NgorongoroInterface._maxCachePendingCount {
			objc_sync_exit(_cacheLock)
			return false
		}
		(isExplict) ?
			_explicitThemeCachePendingPaths.put(value: Date(), forKey: cacheFileName) :
			_spareThemeCachePendingPaths.put(value: Date(), forKey: cacheFileName)
		objc_sync_exit(_cacheLock)
		print("ng cache: request [", (isExplict) ? "E" : "S", "] (" +
			String(_explicitThemeCachePendingPaths.count) + "," +
			String(_spareThemeCachePendingPaths.count) + ") " + themeInfo._theme.stringValue)
		ngorongoro(themeString: themeInfo._theme.stringValue,
				   themeOption: themeInfo.getOption(),
				   onSuccess: { (valid_image, serverCoden) in
						objc_sync_enter(self._cacheLock)
						(isExplict) ?
							self._explicitThemeCachePendingPaths.removeValueForKey(key: cacheFileName) :
							self._spareThemeCachePendingPaths.removeValueForKey(key: cacheFileName)
						// Decide whether to accept the new cache or not based on _historyPaths existence
						if let _ = self._historyPaths.firstIndex(of: serverCoden) {
							self._consecutiveHitCount += 1
							// must rewind since there is rare possibility to get new image from server
							if (self._consecutiveHitCount > NgorongoroInterface._maxConsecutiveHitCount) {
								self._consecutiveHitCount = 0
								self._historyPaths.removeAll(keepCapacity: 0)
								print("ng cache: rewind cache history with (" + serverCoden + ") #", self._consecutiveHitCount)
							} else {
								print("ng cache: skipped by cache history with (" + serverCoden + ") #", self._consecutiveHitCount)
								objc_sync_exit(self._cacheLock)
								return
							}
						} else {
							self._consecutiveHitCount = 0
						}
						self._historyPaths.put(value: cacheFileName, forKey: serverCoden)
						objc_sync_exit(self._cacheLock)
						if self.saveCacheFile(cacheImage: valid_image, cacheFileName: cacheFileName) {
							print("ng cache: http result [", (isExplict) ? "E" : "S", "] (" +
								String(self._explicitThemeCachePendingPaths.count) + "," +
								String(self._spareThemeCachePendingPaths.count) + ") " + themeInfo._theme.stringValue + "@" + serverCoden)
							objc_sync_enter(self._cacheLock)
							self._cachePaths.put(value: cacheFileName, forKey: serverCoden)
							if (self._currentExplicitThemeInfo.isThemeImage(coden: serverCoden)) {
								self._cacheThemePaths.put(value: cacheFileName, forKey: serverCoden)
							}
							if (self._currentExplicitThemeInfo.equals(themeInfo)) {
								self._explicitThemeCachePaths.put(value: cacheFileName, forKey: serverCoden)
							}
							objc_sync_exit(self._cacheLock)
						} else {
							print("ng cache: error in ngorongoro (" + themeInfo._theme.stringValue + ") during saveCacheFile.")
						}
				   },
				   onFailure: { (error) in
						objc_sync_enter(self._cacheLock)
						(isExplict) ?
							self._explicitThemeCachePendingPaths.removeValueForKey(key: cacheFileName) :
							self._spareThemeCachePendingPaths.removeValueForKey(key: cacheFileName)
						objc_sync_exit(self._cacheLock)
						print("ng cache: error in ngorongoro failure - " + error)
				   })
		return true
	}
  
	private func ngorongoro(themeString:String, themeOption:String,
                                  onSuccess success: @escaping (_ image: UIImage, _ path: String) -> Void,
                                  onFailure failure: @escaping (_ error: String) -> Void) {
		
		objc_sync_enter(_ngorongoroLock)
        var urlComponents = URLComponents()
        // urlComponents.host = "192.168.1.111" - release.xconfig
        // urlComponents.host = "127.0.0.1" - debug.xconfig
        let config = EnvironmentConfiguration()
        urlComponents.host = config.nGorongoroServer

        urlComponents.scheme = "http"
        urlComponents.port = 8080
        urlComponents.path = "/ngorongoro"
        let options = [URLQueryItem(name: "a", value: PlatformInfo._agent),
                       URLQueryItem(name: "o", value: themeOption),
                       URLQueryItem(name: "d", value: PlatformInfo._dimension),
                       URLQueryItem(name: "t", value: themeString)]
        let orientation = WallpaperServiceInfo.getInstance().getOrientation()
        urlComponents.queryItems = options
        if let url = urlComponents.url {
            // semicolon is not taken cared by swift URLQueryItem so it must call queryStringEscape()
            if let url = URL(string: url.absoluteString.queryStringEscape()) {
				let config = URLSessionConfiguration.default
				config.timeoutIntervalForResource = _urlRequestTimeout // default = 7 days
				config.timeoutIntervalForRequest = _urlRequestTimeout // default = 60 sec
				let session = URLSession(configuration: config)
                print("url = " + url.absoluteString)
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                let task = session.dataTask(with: request) { (data, response, error) in
                    // Check if Error took place
                    if let error = error {
						failure("URLSession.shared.dataTask \(error)")
                        return
                    }
                    // Read HTTP Response Status code
                    if let response = response as? HTTPURLResponse {
                        print("Response HTTP Status code: \(response.statusCode)")
                        var serverPath = ""
                        if #available(iOS 13.0, *) {
                            if let pathInHeaderBase64 = response.value(forHTTPHeaderField: "Coden") {
                                if let pathFromHeader = pathInHeaderBase64.base64Decoded() {
                                    serverPath = pathFromHeader
                                    print(pathFromHeader)
                                }
                            }
                        } else {
                            // for iPad Old, iPod touch
                             if let pathInHeaderBase64 = response.allHeaderFields["Coden"] as? String {
                                if let pathFromHeader = pathInHeaderBase64.base64Decoded() {
                                    serverPath = pathFromHeader
                                    print(pathFromHeader)
                                }
                             }
                        }
                        if let valid_data = data {
                            if let valid_image = UIImage(data: valid_data) {
                                success(valid_image, orientation + serverPath )
                            } else {
                                failure("invalid image data")
                            }
                        } else {
                            failure("data transimission error")
                        }
					} else {
						failure("no http url response error")
					}
                }
                task.resume()
            } else {
                failure("url.absoluteString.queryStringEscape()")
            }
        } else {
            failure("invalid url with option string = " + themeOption)
        }
		objc_sync_exit(_ngorongoroLock)
    }
    
	private func saveCacheFile(cacheImage: UIImage, cacheFileName:String) -> Bool {
        if let data = cacheImage.jpegData(compressionQuality: 1.0) {
            let cachePath = PlatformFileManager._localCacheDir.appendingPathComponent(cacheFileName)
            try? data.write(to: cachePath)
            return true
        }
        return false
    }
	
	private var _historyPaths:WLinkedHashMap<String, String> = WLinkedHashMap<String, String>()
	private var _consecutiveHitCount:Int = 0
	private var _cachePaths: WLinkedHashMap<String, String> = WLinkedHashMap<String, String>()
	private var _cacheThemePaths: WLinkedHashMap<String, String> = WLinkedHashMap<String, String>()
    private var _cacheUnthemePaths: WLinkedHashMap<String, String> = WLinkedHashMap<String, String>()
    
	private var _explicitThemeCachePaths: WLinkedHashMap<String, String> = WLinkedHashMap<String, String>()
	private var _explicitThemeCachePendingPaths: WLinkedHashMap<String, Date> = WLinkedHashMap<String, Date>()
    private var _spareThemeCachePendingPaths: WLinkedHashMap<String, Date> = WLinkedHashMap<String, Date>()

	private let _cacheLock:NSObject = NSObject()
	private let _downloadLock:NSObject = NSObject()
	private let _ngorongoroLock:NSObject = NSObject()

    private var _currentSpareThemeInfo = WallpaperServiceInfo.getInstance().getThemeInfo()
	private var _currentExplicitThemeInfo:ThemeInfo = ThemeInfo.getThemeInfo(theme: .special2).copy() as! ThemeInfo
    
    private var _cacheNameIndex:Int = 0
	private let _urlRequestTimeout:TimeInterval = TimeInterval(5.0)
    private static let _maxCacheNameIndex:Int = 999999

    // Cache Tuning Parameters
    private static let _sleepTimeBetweenDownloads:useconds_t = 500
    private static let _maxCacheCount:Int = (_maxExplicitThemeCacheCount + _maxSpareCacheCountPerTheme) * (Theme.all.intValue + 1)
	private static let _maxExplicitThemeCacheCount:Int = 10
    private static let _maxExplicitThemeCachePendingCountPerRequest:Int = 2
    private static let _maxSpareCacheCountPerTheme:Int = 4
    private static let _maxSpareCachePendingCountPerRequest:Int = 2
	private static let _maxCachePendingCount:Int = 3
	private static let _maxConsecutiveHitCount:Int = 3
    
    // false for Debug, true for Release
	private var _nGorongoroCacheEnabled = EnvironmentConfiguration().nGorongoroCache
	
}

