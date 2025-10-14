//
//  AppDelegate.swift
//  tromso
//
//  Created by Brad Park on 5/6/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import UIKit
import SwiftUI

@UIApplicationMain
class TromsoTVAppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		let contentView = ContentView()
		let window = UIWindow(frame: UIScreen.main.bounds)
		window.rootViewController = UIHostingController(rootView: contentView)
		self.window = window
		window.makeKeyAndVisible()
		PlatformInfo.collectDeviceInformation()
        // tv app can get the dimension immediately due to fixed screen (ios app defers)
        PlatformInfo.calcScreenDimension()
		let wpsi = WallpaperServiceInfo.getInstance()
        switch (UIDevice.current.name) {
            case "Apple TV 4K (3rd generation) (at 1080p)":
                //wpsi.setSourceRootPath("BP Photo/1990")
                break
            default:
                // wpsi.setSourceRootPath("BP Photo")
                print ("device name = " + UIDevice.current.name)
                break
        }
		wpsi.getWallpaperService().startService()
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
	}
}

