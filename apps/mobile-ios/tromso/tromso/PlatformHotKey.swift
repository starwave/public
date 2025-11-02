//
//  PlatformHotKey.swift
//  tromso
//
//  Created by Brad Park on 5/18/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import SwiftUI

struct PlatformHotKey: UIViewControllerRepresentable {

	func makeUIViewController(context: Context) -> UIViewController {
		let myViewController = PlatformHotKeyViewController()
		return myViewController;
	}
	
	func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
	}
}


