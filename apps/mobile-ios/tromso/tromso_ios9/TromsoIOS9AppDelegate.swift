//
//  AppDelegate.swift
//  tromso-ios
//
//  Created by Brad Park on 5/21/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import UIKit

@UIApplicationMain
class TromsoIOS9AppDelegate: UIResponder, UIApplicationDelegate {
	
	var _window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		PlatformInfo.collectDeviceInformation()
		PlatformInfo.calcScreenDimension()
		PlatformInfo._agent += "9"
		_window = UIWindow(frame: UIScreen.main.bounds)
        if let window = _window {
            window.backgroundColor = UIColor.black
            window.rootViewController = TromsoIOS9ViewController()
            window.makeKeyAndVisible()
        }
		let wpsi = WallpaperServiceInfo.getInstance()
        switch (UIDevice.current.name) {
            case "iPhone 16 Pro Max":
                wpsi.setSourceRootPath("BP Photo/2024")
                break
            case "Brad iPad Air":
                // wpsi.setSourceRootPath("")
                break
            default:
                //wpsi.setSourceRootPath("BP Photo")
                print ("device name = " + UIDevice.current.name)
                break
        }
		wpsi.getWallpaperService().startService()
		return true
	}

	@available(iOS 13.0, *)
	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	@available(iOS 13.0, *)
	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
	}
}
