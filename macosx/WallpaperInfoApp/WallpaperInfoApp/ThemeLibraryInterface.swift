//
//  WallpaperThemeLibrary.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 9/11/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation

class ThemeLibraryInterface {
	
	public func requestUpdateThemeLibrary(label:String, config:String, completion: @escaping (String?) -> Void) -> Bool {
		let options = [URLQueryItem(name: "a", value: "u"), URLQueryItem(name: "l", value: label), URLQueryItem(name: "c", value: config)]
		return maramboi(options: options, completion: { (response) in
			BPUtil.storeStringToFile(fileURL: self._themeJsonPath, contents: response)
			completion(response)
		})
	}
	
	public func getThemeLibrary(completion: @escaping (String) -> Void) -> String? {
		var contents:String? = nil
		objc_sync_enter(self)
		let options = [URLQueryItem(name: "a", value: "g")]
		_ = maramboi(options: options, completion: { (response) in
			BPUtil.storeStringToFile(fileURL: self._themeJsonPath, contents: response)
			completion(response)
		})
		if (!BPUtil.fileExists(_themeJsonPath.path)) {
			if let path = Bundle.main.url(forResource: "themelib", withExtension: "txt") {
				contents = BPUtil.getStringFromFile(fileURL: path)
				if contents != nil {
					BPUtil.storeStringToFile(fileURL: _themeJsonPath, contents: contents!)
				}
			} else {
                BPUtil.BPLog("Error: getThemeLibrary - copying asset themeLib.txt file")
			}
		} else {
			contents = BPUtil.getStringFromFile(fileURL: _themeJsonPath)
		}
		objc_sync_exit(self)
		return contents
	}
	
	public func getReservedWords(completion: @escaping (String) -> Void) -> String? {
		var contents:String? = nil
		objc_sync_enter(self)
		let options = [URLQueryItem(name: "a", value: "r")]
		_ = maramboi(options: options, completion: { (response) in
			BPUtil.storeStringToFile(fileURL: self._reservedJsonPath, contents: response)
			completion(response)
		})
		if (!BPUtil.fileExists(_reservedJsonPath.path)) {
			if let path = Bundle.main.url(forResource: "reservedword", withExtension: "txt") {
				contents = BPUtil.getStringFromFile(fileURL: path)
				if contents != nil {
					BPUtil.storeStringToFile(fileURL: _reservedJsonPath, contents: contents!)
				}
			} else {
                BPUtil.BPLog("Error: getReservedWords - copying asset reservedword.txt file")
			}
		} else {
			contents = BPUtil.getStringFromFile(fileURL: _reservedJsonPath)
		}
		objc_sync_exit(self)
		return contents
	}
	
	public func updateThemeLibLocalFileFromList(_ themeLibs: [ThemeLib]) {
		objc_sync_enter(self)
		do {
			let jsonEncoder = JSONEncoder()
			jsonEncoder.outputFormatting = .prettyPrinted
			let jsonData = try jsonEncoder.encode(themeLibs)
			let themeLibString = String(data: jsonData, encoding: String.Encoding.utf8)
			BPUtil.storeStringToFile(fileURL: _themeJsonPath, contents: themeLibString!)
		} catch {
            BPUtil.BPLog("Error: updateThemeLibLocalFileFromList - can't make json")
		}
		objc_sync_exit(self)
    }
	
	public func parseThemeLib(_ themeLibString: String) -> [ThemeLib] {
		var themeLibs = [ThemeLib]()
		let jsonData = themeLibString.data(using: .utf8)!
		// id property of ThemeLib must be let to match to json file
		if let jArray = try? JSONDecoder().decode([ThemeLib].self, from: jsonData) {
			themeLibs = jArray
        } else {
            BPUtil.BPLog("Error in parsing json from themelib.txt file.")
        }
		return themeLibs
	}
	
	public func parseReservedWord(_ reservedWordString: String) -> [ReservedWord] {
		var reservedWords = [ReservedWord]()
		let jsonData = reservedWordString.data(using: .utf8)!
		if let jArray = try? JSONDecoder().decode([ReservedWord].self, from: jsonData) {
			reservedWords = jArray
        } else {
            BPUtil.BPLog("Error in parsing json from reservedword.txt file.")
        }
		return reservedWords
	}
	
	private func maramboi(options:[URLQueryItem], completion: @escaping (String) -> Void) -> Bool {
		objc_sync_enter(_maramboiLock)
		var success = false
		var urlComponents = URLComponents()
		urlComponents.host = _host
		urlComponents.scheme = "http"
		urlComponents.port = 8080
		urlComponents.path = "/maramboi"
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
                        BPUtil.BPLog("ThemeLibraryInterface.maramboi - urlsession failure \(error)")
						return
					}
					objc_sync_enter(self._maramboiLock)
					if let valid_data = data {
						let response = String(decoding: valid_data, as: UTF8.self)
						completion(response)
					} else {
                        BPUtil.BPLog("ThemeLibraryInterface.maramboi - Invalid nil Data Return")
					}
					objc_sync_exit(self._maramboiLock)
				}
				task.resume()
				success = true
			}
		}
		objc_sync_exit(_maramboiLock)
		return success
	}
	
	private let _maramboiLock:NSObject = NSObject()
	public let _urlRequestTimeout:TimeInterval = TimeInterval(5.0)
	public let _themeJsonPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("/.themelib.txt")
	public let _reservedJsonPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("/.reservedword.txt")
	public let _host = "192.168.1.111"
}

struct ThemeLib: Codable, Identifiable, Hashable {
    let id = UUID()
    var Label:String
    var Config:String
    
    // this should be defined to avoid warning for id part
    enum CodingKeys: String, CodingKey {
        case Label
        case Config
    }
}

struct ReservedWord: Codable {
    var Word:String
    var WordPath:String
}

