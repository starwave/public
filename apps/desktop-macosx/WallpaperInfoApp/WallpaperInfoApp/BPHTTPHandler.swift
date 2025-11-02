//
//  BPFileServer.swift
//  WallpaperInfoApp
//
//  Created by brad on jafaga on 9/25/24.
//  Copyright © 2024 Brad Park. All rights reserved.
//

// add SwiftNIO to your project via Swift Package Manager.

import NIO
import NIOHTTP1
import Foundation

final class BPHTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    var receivedData: [UInt8] = []

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)

        switch reqPart {
        case .head(let requestHead):
            print("Received request: \(requestHead.uri)")

        case .body(var byteBuffer):
            let bytes = byteBuffer.readBytes(length: byteBuffer.readableBytes) ?? []
            receivedData.append(contentsOf: bytes)

        case .end:
            let downloadsPath = NSHomeDirectory() + "/Downloads/"
            let fileURL = URL(fileURLWithPath: downloadsPath + "received_image.jpg")
            let fileData = Data(receivedData)
            do {
                try fileData.write(to: fileURL)
                print("File saved successfully at \(fileURL)")
            } catch {
                print("Error saving file: \(error)")
            }
            let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .ok)
            context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
            context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
            receivedData = [] // Clear data after file is saved
        }
    }
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("Error: \(error)")
        context.close(promise: nil)
    }
}

/*
// Create the server and bind it to a port
let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let bootstrap = ServerBootstrap(group: group)
    .childChannelInitializer { channel in
        channel.pipeline.configureHTTPServerPipeline().flatMap {
            channel.pipeline.addHandler(BPHTTPHandler())
        }
    }
    .bind(host: "localhost", port: 8080)

let channel = try bootstrap.wait()

print("Server running on \(channel.localAddress!)")

try channel.closeFuture.wait()
running
*/
