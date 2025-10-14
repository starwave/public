//
//  PlatformInfo.swift
//  tromso
//
//  Created by Brad Park on 5/20/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import UIKit
import Foundation
import SystemConfiguration.CaptiveNetwork

enum DeviceType {
	case AppleTV
	case iPhone
	case iPad
	case Unspecified
}

class PlatformInfo {
	
	public static func collectDeviceInformation() {
		switch UIDevice.current.userInterfaceIdiom {
		case .tv:
			PlatformInfo._deviceType = .AppleTV
			PlatformInfo._agent = "tappletv"
		case .phone:
			PlatformInfo._deviceType = .iPhone
			PlatformInfo._agent = "tiphone"
		case .pad:
			PlatformInfo._deviceType = .iPad
			PlatformInfo._agent = "tipad"
		default:
			PlatformInfo._deviceType = .Unspecified
		}
	}
	
	public static func calcScreenDimension() {
		let screenRect = UIScreen.main.bounds
		let screenScale = UIScreen.main.scale
		let screenWidth = Int(screenRect.size.width * screenScale)
		let screenHeight = Int(screenRect.size.height * screenScale)
		let ratio = screenWidth*1000 / screenHeight
		var dimension = String(screenWidth) + "x" + String(screenHeight)
		if ([ .iPhone,.iPad ].contains(_deviceType)) {
			if (1150 < ratio && ratio <= 1550) {			// iPadPro (1.334)
				dimension = "2732x2048"
			} else if (1550 < ratio && ratio <= 1950) {		// HD or UHD (1.778)
				if (screenWidth > 1920) {
					dimension = "3840x2160"
				} else {
					dimension = "1920x1080"
				}
			} else if (1950 < ratio && ratio <= 2350) {		// iPhoneMax Landscape (2.164)
				dimension = "2688x1242"
			} else if (600 < ratio && ratio <= 900) {		// iPad Pro Landscape (0.749)
				dimension = "2048x2732"
			} else if (300 < ratio && ratio <= 600) {		// GalaxyS Portrait (0.474)
				dimension = "1080x2280"
			}
		}
		if (ratio > 1000) {
			WallpaperServiceInfo.getInstance().setOrientation("L") // Landscape
		} else {
			WallpaperServiceInfo.getInstance().setOrientation("P") // Portrait
		}
		_dimension = dimension
	}

	public static var _dimension:String = "1920x1200"
	public static var _deviceType:DeviceType = .AppleTV
	public static var _agent:String = "tios"
}

// make config.plist
// create release.xconfig, debug.xconfig
// update project configurations with created xconfig files
// edit Info.plist
final class EnvironmentConfiguration {
    private let config: NSDictionary
    
    init(dictionary: NSDictionary) {
        config = dictionary
    }
    
    convenience init() {
        let bundle = Bundle.main
        let configPath = bundle.path(forResource: "config", ofType: "plist")!
        let config = NSDictionary(contentsOfFile: configPath)!
        
        let dict = NSMutableDictionary()
        if let commonConfig = config["Common"] as? [AnyHashable: Any] {
            dict.addEntries(from: commonConfig)
            
        }
        if let environment = bundle.infoDictionary!["ConfigEnvironment"] as? String {
            if let environmentConfig = config[environment] as? [AnyHashable: Any] {
                dict.addEntries(from: environmentConfig)
            }
        }
        self.init(dictionary: dict)
    }
}

extension EnvironmentConfiguration {
    var nGorongoroServer: String {
        let localIP = getLocalIPAddress()
        if let ip = localIP, ip.hasPrefix("192.168.1.") {
            return config["ngorongoro_server"] as! String
        } else {
            return config["ngorongoro_server_ext"] as! String
        }
    }

    var nGorongoroCache: Bool {
        return config["ngorongoro_cache"] as! Bool
    }

    private func getLocalIPAddress() -> String? {
        var address: String?

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" || name == "eth0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                    break
                }
            }
        }

        freeifaddrs(ifaddr)
        return address
    }
}
