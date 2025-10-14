//
//  BPFileReceiver.swift
//  WallpaperInfoApp
//
//  Created by brad on jafaga on 11/1/24.
//  Copyright © 2024 Brad Park. All rights reserved.
//

import Foundation

class BPFileReceiver {
    let port: UInt16 = 8081
    let downloadsPath = NSHomeDirectory() + "/Downloads/"

    func start() {
        var context = CFSocketContext()
        context.version = 0
        context.info = Unmanaged.passRetained(self).toOpaque()
        let callback: CFSocketCallBack = { socket, callbackType, address, data, info in
            guard let info = info else { return }
            let server = Unmanaged<BPFileReceiver>.fromOpaque(info).takeUnretainedValue()
            server.handleConnection(data: data)
        }
        let socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, CFSocketCallBackType.acceptCallBack.rawValue, callback, &context)
        guard let socket = socket else {
            print("BPFileReceiver: Failed to create socket")
            return
        }
        var sin = sockaddr_in()
        sin.sin_family = sa_family_t(AF_INET)
        sin.sin_addr.s_addr = INADDR_ANY
        sin.sin_port = port.bigEndian
        let data = Data(bytes: &sin, count: MemoryLayout<sockaddr_in>.size)
        CFSocketSetAddress(socket, data as CFData)
        let runLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        print("BPFileReceiver: Server listening on port \(port)")
        CFRunLoopRun()
    }

    func handleConnection(data: UnsafeRawPointer?) {
        guard let data = data else {
            print("BPFileReceiver: No data received")
            return
        }
        let clientSocket = data.assumingMemoryBound(to: CFSocketNativeHandle.self).pointee
        handleClient(clientSocket: clientSocket)
    }
    
    func renameFileIfExists(atPath path: String) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyMMdd-HHmmss"
            let timestamp = dateFormatter.string(from: Date())
            let newFilePath = "\(path).\(timestamp).bak"
            print("BPFileReceiver: File renamed to \(newFilePath)")
            do {
                try fileManager.moveItem(atPath: path, toPath: newFilePath)
            } catch {
                print("BPFileReceiver: Error renaming file: \(error)")
            }
        }
    }

    func handleClient(clientSocket: CFSocketNativeHandle) {
        if #available(macOS 10.15.4, *) {
            let fileHandle = FileHandle(fileDescriptor: clientSocket)
            let fileManager = FileManager.default
            do {
                let command = getLongNumber(fileHandle: fileHandle)
                switch (command) {
                    case 0:
                        // Read file name
                        let fileName = getString(fileHandle: fileHandle)
                        print("BPFileReceiver: file name: \(fileName)")
                        // Read file size
                        let fileSize = getLongNumber(fileHandle: fileHandle)
                        print("BPFileReceiver: file size \(fileSize)")
                        // Back up existing file
                        let filePath = downloadsPath + fileName
                        renameFileIfExists(atPath: filePath)
                        // Read file & save
                        fileManager.createFile(atPath: filePath, contents: nil, attributes: nil)
                        let outputFileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: filePath))
                        var bytesReceived: Int64 = 0
                        while bytesReceived < fileSize {
                            let bytesToRead = min(Int(fileSize - bytesReceived), 4096)
                            if let data = try fileHandle.read(upToCount: bytesToRead) {
                                try outputFileHandle.write(contentsOf: data)
                                bytesReceived += Int64(data.count)
                            } else {
                                break
                            }
                        }
                        try outputFileHandle.close()
                        try fileHandle.close()
                        print("BPFileReceiver: File \(fileName) received successfully")
                        break;
                    case 1:
                        // Read album name
                        let albumName = getString(fileHandle: fileHandle)
                        renameFileIfExists(atPath: downloadsPath + albumName)
                        let albumURL = URL(fileURLWithPath: downloadsPath + albumName)
                        try FileManager.default.createDirectory(at: albumURL, withIntermediateDirectories: true, attributes: nil)
                        print("BPFileReceiver: album name: \(albumName)")
                        break;
                    default:
                        break;
                }
            } catch {
                print("BPFileReceiver: Error in file receiving: \(error)")
            }
        }
    }
    
    func getLongNumber(fileHandle: FileHandle) -> Int64 {
        var returnLongNumber:Int64 = -1
        if #available(macOS 10.15.4, *) {
            do {
                guard let longNumberData = try fileHandle.read(upToCount: MemoryLayout<Int64>.size),
                      longNumberData.count == MemoryLayout<Int64>.size else {
                    return returnLongNumber
                }
                returnLongNumber = Int64(bigEndian: longNumberData.withUnsafeBytes { $0.load(as: Int64.self) })
            } catch {
                print("BPFileReceiver: Error in getLongNumber: \(error)")
                return returnLongNumber;
            }
        }
        return returnLongNumber;
    }
    
    func getString(fileHandle: FileHandle) -> String {
        var returnString:String = "";
        let stringLength = getLongNumber(fileHandle: fileHandle)
        if (stringLength < 0) {
            return returnString;
        }
        if #available(macOS 10.15.4, *) {
            do {
                var bytesReceived: Int64 = 0
                let emptyByteArray: [UInt8] = [];
                var bytesName = Data(emptyByteArray)
                while bytesReceived < stringLength {
                    let bytesToRead = min(Int(stringLength - bytesReceived), 4096)
                    if let data = try fileHandle.read(upToCount: bytesToRead) {
                        bytesName.append(contentsOf: data);
                        bytesReceived += Int64(data.count)
                    } else {
                        break
                    }
                }
                guard let utfString = String(data: bytesName, encoding: .utf8) else {
                    return returnString
                }
                returnString = utfString
            } catch {
                print("BPFileReceiver: Error in getString: \(error)")
                return returnString;
            }
        }
        return returnString;
    }
}
