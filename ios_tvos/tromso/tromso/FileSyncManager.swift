//
//  FileSyncManager.swift
//  tromso
//
//  Created by brad on jafaga on 11/8/24.
//  Copyright © 2024 Brad Park. All rights reserved.
//

import Foundation

class FileSyncManager {

    init(serverBase: String, force: Bool) {
        self._serverBase = serverBase
        _onEvent = {(event, wpath) in }
        _force = force
    }

    func syncFiles(fileSyncDoneCallback: @escaping () -> Void, onEvent:  @escaping (Int, WPath) -> Void) {
        if (FileSyncManager._isSyncing) {
            return
        }
        FileSyncManager._isSyncing = true
        _onEvent = onEvent
        let wpsi = WallpaperServiceInfo.getInstance()
        fetchServerFileListVer { versionDate in
            print("FileSyncManager: server = \(versionDate), client = \(wpsi.getlastSyncTime())")
            let sourceRootPath = BPUtil.getHomeDirectoryUrl().appendingPathComponent("CloudStation/" + wpsi.getSourceRootPath()).path
            if (versionDate != wpsi.getlastSyncTime() || !BPUtil.fileExists(sourceRootPath)) {
                print("FileSyncManager: background sync started")
                DispatchQueue.global(qos: .background).async {
                    self.syncFilesImpl{
                        fileSyncDoneCallback()
                        wpsi.setlastSyncTime(versionDate)
                        FileSyncManager._isSyncing = false
                    }
                }
            } else {
                print("FileSyncManager: sync isn't needed")
                fileSyncDoneCallback()
                FileSyncManager._isSyncing = false
            }
        }
    }
    
    private func syncFilesImpl(completion: @escaping () -> Void) {
        fetchServerFileList { serverFiles in
            handleServerFile(serverFiles: serverFiles)
        }
        
        func handleServerFile(serverFiles: [ServerFile]) {
            let wpsi = WallpaperServiceInfo.getInstance()
            func reduceFileCountsToSync() {
                _fileCountsToSync -= 1
                let fileProcessed = serverFiles.count - _fileCountsToSync
                let label = wpsi.getcurrentWPath()?.label() ?? ""
                if (fileProcessed % 100 == 0) {
                    wpsi.getWallpaperService().updateLabelWidget(labelString: "syncing \(fileProcessed) of \(serverFiles.count)\n\(label)")
                }
                if (self._fileCountsToSync == 0 && localFilesSet.count == 0) {
                    wpsi.getWallpaperService().updateLabelWidget(labelString: "sync finished \(fileProcessed) of \(serverFiles.count)\n\(label)")
                    completion()
                }
            }
            _fileCountsToSync = serverFiles.count
            let localFiles = BPUtil.getAllLocalFiles(in: WallpaperService._offlineImagesRoot)
            // print("FileSyncManager: local file count = \(localFiles.count) under \(WallpaperService._offlineImagesRoot)")
            var localFilesSet = Set(localFiles)
            for (_, serverFile) in serverFiles.enumerated() {
                let localFileURL = WallpaperService._offlineImagesRoot.appendingPathComponent(serverFile.p)
                localFilesSet.remove(serverFile.p)
                // print("FileSyncManager: checking \(index + 1) '\(serverFile.p)'")
                let fileAdd = !_fileManager.fileExists(atPath: localFileURL.path)
                let fileModified = isFileModified(serverFile: serverFile, localFile: localFileURL)
                if fileAdd || fileModified {
                    usleep(200000)
                    if BPUtil.ensureDirectories(for: localFileURL) {
                        //print("FileSyncManager: downloading exists? \(_fileManager.fileExists(atPath: localFileURL.path)) modified? \(isFileModified(serverFile: serverFile, localFile: localFileURL))")
                        DownloadManager.shared.downloadFile(from: serverFile, to: localFileURL) { success, error in
                            if success {
                                print("FileSyncManager: Downloaded to \(serverFile.p)")
                                let path = localFileURL.path
                                let event = fileAdd ? FileSyncManager.ADD : FileSyncManager.MODIFIED
                                let pathExtension = URL(fileURLWithPath: path).pathExtension
                                if (pathExtension == "jpg") {
                                    if (path.contains("/BP Photo/")) {
                                        let exif = BPUtil.getExifDescription(path: path)
                                        self._onEvent(event, WPath(path: path, exif: exif))
                                    } else {
                                        self._onEvent(event, WPath(path: path, exif: ""))
                                    }
                                }
                            } else {
                                print("FileSyncManager: Download failed: \(String(describing: error))")
                            }
                            reduceFileCountsToSync()
                        }
                    } else {
                        print("FileSyncManager: directory creation failed for \(localFileURL.path)")
                        reduceFileCountsToSync()
                    }
                } else {
                    reduceFileCountsToSync()
                }
            }
            if (localFilesSet.count > 0) {
                for localFile in localFilesSet {
                    try? _fileManager.removeItem(atPath: WallpaperService._offlineImagesRoot.appendingPathComponent(localFile).path)
                    self._onEvent( FileSyncManager.DELETE, WPath(path: localFile, exif: ""))
                }
                localFilesSet = [];
                if (self._fileCountsToSync == 0) {
                    wpsi.getWallpaperService().updateLabelWidget(labelString: "sync finished \(serverFiles.count - _fileCountsToSync) of \(serverFiles.count)")
                    completion()
                }
            }
        }
    }
   
    func isFileModified(serverFile: ServerFile, localFile: URL) -> Bool {
        guard let localAttributes = try? _fileManager.attributesOfItem(atPath: localFile.path),
              let localModDate = localAttributes[.modificationDate] as? Date,
              let localFileSize = localAttributes[.size] as? Int64 else {
            return true
        }
        var isModDateDifferent = true
        if let modifydate = ISO8601DateFormatter().date(from: serverFile.m) {
            isModDateDifferent = abs(modifydate.timeIntervalSince(localModDate)) > _modifyWindow
        }
        let isSizeDifferent = serverFile.s != localFileSize
        if (isModDateDifferent || isSizeDifferent) {
            print("FileSyncManager: \(serverFile.p) time change=>\(isModDateDifferent), size change=> \(isSizeDifferent) \(serverFile.s) \(localFileSize)")
        }
        return isModDateDifferent || isSizeDifferent
    }
    
    func fetchServerFileListVer(completion: @escaping (String) -> Void) {
        var urlComponents = URLComponents()
        let config = EnvironmentConfiguration()
        urlComponents.scheme = "http"
        urlComponents.port = 8080
        urlComponents.path = "/file-list-ver"
        urlComponents.host = config.nGorongoroServer
        urlComponents.queryItems = [URLQueryItem(name: "p", value: self._serverBase)]
        guard let url = urlComponents.url  else {
            print("Invalid URL")
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Invalid response")
                return
            }
            if let data = data, let value = String(data: data, encoding: .utf8) {
                print("Value: \(value)")
                completion(value)
            } else {
                print("No data received")
            }
        }
        task.resume()
    }
 
    func fetchServerFileList(completion: @escaping ([ServerFile]) -> Void) {
        var urlComponents = URLComponents()
        let config = EnvironmentConfiguration()
        urlComponents.scheme = "http"
        urlComponents.port = 8080
        urlComponents.path = "/file-list"
        urlComponents.host = config.nGorongoroServer
        if _force {
            urlComponents.queryItems = [URLQueryItem(name: "p", value: self._serverBase), URLQueryItem(name: "f", value: "1")]
        } else {
            urlComponents.queryItems = [URLQueryItem(name: "p", value: self._serverBase)]
        }
        guard let url = urlComponents.url else {
            print("FileSyncManager: Invalid URL in fetchServerFileList \(urlComponents.host ?? "")")
            completion([])
            return
        }
        print("FileSyncManager: fetching file list from ", url.absoluteString)
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                print("FileSyncManager: Error fetching server file list:", error ?? "Unknown error")
                completion([])
                return
            }
            let receivedBytes = data.count
            let expectedBytes = httpResponse.expectedContentLength
            if expectedBytes > 0 && receivedBytes != expectedBytes {
                print("FileSyncManager: Warning - Received data size does not match expected size")
            }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let serverFiles = try decoder.decode([ServerFile].self, from: data)
                completion(serverFiles)
            } catch DecodingError.dataCorrupted(let context) {
                print("Data corrupted: \(context.debugDescription)")
                print("Coding path: \(context.codingPath)")
                if let index = context.codingPath.first?.intValue {
                    self.printProblematicJSON(jsonData: data, aroundIndex: index)
                }
                completion([])
            } catch {
                print("FileSyncManager: Error decoding JSON:", error)
                completion([])
            }
        }
        task.resume()
    }

    func printProblematicJSON(jsonData: Data, aroundIndex index: Int) {
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            let start = max(0, index - 100)
            let end = min(jsonString.count, index + 100)
            let problematicPart = String(jsonString[jsonString.index(jsonString.startIndex, offsetBy: start)..<jsonString.index(jsonString.startIndex, offsetBy: end)])
            print("Problematic JSON around index \(index):")
            print(problematicPart)
        }
    }
    
    private let _fileManager = FileManager.default
    private let _serverBase: String
    private let _modifyWindow: TimeInterval = 3602  // Modify window in seconds

    private var _fileCountsToSync = 0
    private var _force = false
    var _onEvent:((Int, WPath) -> Void)
    
    static var _isSyncing: Bool = false
    
    static let MOVED_FROM:Int = 0x00000040
    static let MOVED_TO:Int = 0x00000080
    static let CREATE:Int = 0x00000100
    static let DELETE:Int = 0x00000200
    static let ADD:Int = 0x00000180 // MOVED_TO | CREATE
    static let REMOVE:Int = 0x00000240 // MOVED_FROM | DELETE
    static let MODIFIED:Int = 0x00000360
}

struct ServerFile: Codable {
    let p: String   // path
    let m: String   // modifiedDate
    let s: Int64    // filesize
}

class DownloadManager {
    
    static let shared = DownloadManager()
    private init() {}
    private let downloadQueue = DispatchQueue(label: "com.thirdwavesoft.tromso-ios", attributes: .concurrent)
    private let semaphore = DispatchSemaphore(value: 5)
    
    func downloadFile(from serverFile: ServerFile, to localURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        downloadQueue.async { [weak self] in
            guard let self = self else { return }
            self.semaphore.wait()
            // print("acutal downloading starts with " + serverFile.p)            
            var urlComponents = URLComponents()
            let config = EnvironmentConfiguration()
            urlComponents.scheme = "http"
            urlComponents.port = 8080
            urlComponents.path = "/file-download"
            urlComponents.host = config.nGorongoroServer
            guard let downloadUrl = urlComponents.url else {
                self.semaphore.signal()
                completion(false, NSError(domain: "Invalid URL", code: 400, userInfo: nil))
                return
            }
            let baseUrl = downloadUrl.absoluteString
            let allowedCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
            guard let encodedFilePath = serverFile.p.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet),
                  let url = URL(string: "\(baseUrl)?f=\(encodedFilePath)") else {
                self.semaphore.signal()
                completion(false, NSError(domain: "Invalid URL", code: 400, userInfo: nil))
                return
            }
            
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 10 // Timeout for request in seconds
            configuration.timeoutIntervalForResource = 20 // Timeout for resource in seconds            
            let task = URLSession(configuration: configuration).downloadTask(with: url) { tempLocalURL, response, error in
                self.semaphore.signal()
                if let error = error {
                    completion(false, error)
                    return
                }
                
                guard let tempLocalURL = tempLocalURL else {
                    completion(false, NSError(domain: "Download Error", code: 500, userInfo: nil))
                    return
                }
                
                do {
                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: localURL.path) {
                        try fileManager.removeItem(at: localURL)
                    }
                    try fileManager.moveItem(at: tempLocalURL, to: localURL)
                    if let modifydate = ISO8601DateFormatter().date(from: serverFile.m) {
                        try fileManager.setAttributes([.modificationDate: modifydate], ofItemAtPath: localURL.path)
                    } else {
                        print("Invalid ISO 8601 date string with \(serverFile.p) \(serverFile.m)")
                    }
                    completion(true, nil)
                } catch {
                    completion(false, error)
                }
            }
            task.resume()
        }
    }
}
