//
//  TromsoTVExtension.swift
//  tromso_tv
//
//  Created by Brad Park on 9/15/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import SwiftUI

struct Slider: UIViewControllerRepresentable {
	
	init<V>(value: Binding<V>, in bounds: ClosedRange<V> = 0...1, onEditingChanged: @escaping (Bool) -> Void = { _ in }) where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint {
		
	}

	func makeUIViewController(context: Context) -> UIViewController {
		let viewController = UIViewController()
		return viewController;
	}
	
	func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
	}
}

/*

extension View {
	public func gesture<T>(_ gesture: T, including mask: GestureMask = .all) -> some View where T : Gesture {
		let gesture2 = Gesture()
		return gesture2
	}
}

public struct Gesture {
}

public struct TapGesture : Gesture {
}

*/
