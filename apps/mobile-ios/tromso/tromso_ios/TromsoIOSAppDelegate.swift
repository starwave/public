//
//  AppDelegate.swift
//  tromso_ios
//
//  Created by Brad Park on 5/20/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import UIKit

@UIApplicationMain
class TromsoIOSAppDelegate: UIResponder, UIApplicationDelegate {

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		PlatformInfo.collectDeviceInformation()
		let wpsi = WallpaperServiceInfo.getInstance()
        switch (UIDevice.current.name) {
            case "iPhone 16 Pro Max":
                wpsi.setSourceRootPath("BP Photo/1990")
                break
            default:
                // commment to keep original configuration
                // wpsi.setSourceRootPath("BP Photo")
                // wpsi.setSourceRootPath("BP Photo/2025") // for iPad 10
                print ("device name = " + UIDevice.current.name)
                break
        }
		wpsi.getWallpaperService().startService()
		return true
	}

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
	}
}

