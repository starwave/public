//
//  DirectoryChooserDialog.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/14/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import Cocoa

class DirectoryChooserDialog {
	
	class func directoryChooserDialog(window:NSWindow, completion: @escaping (String?) -> Void ) {
		let wpsi = WallpaperServiceInfo.getInstance()
		let panel = NSOpenPanel()
		panel.canChooseFiles = false
		panel.canChooseDirectories = true
		panel.canCreateDirectories = false
		panel.allowsMultipleSelection = false
		panel.directoryURL = URL(fileURLWithPath: wpsi.getSourceRootPath())
		panel.beginSheetModal(for: window, completionHandler: { (response) in
			if (response.rawValue == NSFileHandlingPanelOKButton) {
				for url in panel.urls {
					let fm = FileManager.default
					if (fm.fileExists(atPath: url.path) && url.path != "/") {
						completion(url.path)
						return
					}
				}
			}
			completion(nil)
		})
	}
}
