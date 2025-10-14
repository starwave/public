//
//  BPBonjourService.swift
//  WallpaperInfoApp
//
//  Created by brad on jafaga on 9/25/24.
//  Copyright © 2024 Brad Park. All rights reserved.
//
import Foundation
import Cocoa

class BPBonjourService: NSObject, NetServiceDelegate {

    var service: NetService!
    func start() {
        let serviceName = getHostName() + "-BPImage"
        let serviceType = "_http._tcp."
        let serviceDomain = "local."
        let servicePort: Int32 = 8082

        // Create and publish the service
        service = NetService(domain: serviceDomain, type: serviceType, name: serviceName, port: servicePort)
        service.delegate = self
        service.publish(options: .listenForConnections)
    }

    // Called when the service is successfully published
    func netServiceDidPublish(_ sender: NetService) {
        print("Service published: \(sender.name) on port \(sender.port)")
    }

    // Called when the service fails to publish
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("Failed to publish service: \(errorDict)")
    }
    
    func getHostName() -> String {
        let capacity = Int(NI_MAXHOST)
        var hostname = [CChar](repeating: 0, count: capacity)
        guard gethostname(&hostname, capacity) == 0 else {
            return "Unknown"
        }
        return String(cString: hostname)
    }
}

