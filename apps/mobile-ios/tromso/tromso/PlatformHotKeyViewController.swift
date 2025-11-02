//
//  PlatformHotKeyViewController.swift
//  tromso_tv
//
//  Created by Brad Park on 5/23/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

protocol SiriRemoteDelegate {
	func buttonPressed(_ buttonType:UIPress.PressType) -> Bool
	func touchPadSwiped(_ swipeDirection:UISwipeGestureRecognizer.Direction)
	func touchPadTapped(_ count:Int)
}

extension SiriRemoteDelegate {
	func buttonPressed(_ buttonType:UIPress.PressType) -> Bool { return false }
	func touchPadSwiped(_ swipeDirection:UISwipeGestureRecognizer.Direction) {}
	func touchPadTapped(_ count:Int) {}
}

class PlatformHotKeyViewController:UIViewController, SiriRemoteDelegate {
	
	override func viewDidLoad() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.respondToTapGesture))
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.respondToDoubleTapGesture))
        #if os(iOS)
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: nil)
            tapGesture.require(toFail: pinchGesture)
            doubleTapGesture.require(toFail: pinchGesture)
        #endif
        tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)
        doubleTapGesture.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(doubleTapGesture)
        // make it react only to single tap
        tapGesture.require(toFail: doubleTapGesture)

        let directions:[UISwipeGestureRecognizer.Direction] = [.left, .right, .up, .down]
        // must assign direction one by one to distinguish each direction
        for direction in directions {
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
            swipeGesture.direction = direction
            swipeGesture.require(toFail: doubleTapGesture) // doesn't do any effect much for now
            #if os(iOS)
                swipeGesture.require(toFail: pinchGesture)
            #endif
            self.view.addGestureRecognizer(swipeGesture)
        }
	}
	
	@objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
		if let swipeGesture = gesture as? UISwipeGestureRecognizer {
			touchPadSwiped(swipeGesture.direction)
		}
	}
	
	@objc func respondToTapGesture(gesture: UIGestureRecognizer) {
		if gesture is UITapGestureRecognizer {
			touchPadTapped(1)
		}
	}

	@objc func respondToDoubleTapGesture(gesture: UIGestureRecognizer) {
		if gesture is UITapGestureRecognizer {
			touchPadTapped(2)
		}
	}

	override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		guard let buttonPress = presses.first?.type else { return }
		if buttonPressed(buttonPress) {
			return
		}
		super.pressesBegan(presses, with: event)
	}
	
	// SiriRemoteDelegate Implementation
	func buttonPressed(_ buttonType: UIPress.PressType) -> Bool {
        print("WallpaperServiceHandler.buttonPressed = " + String(buttonType.rawValue))
		switch buttonType {
		case .rightArrow:
			WallpaperServiceConnection.broadcastToService(MSG.NEXT)
		case .leftArrow:
			WallpaperServiceConnection.broadcastToService(MSG.PREVIOUS)
		case .downArrow:
			WallpaperServiceConnection.broadcastToService(MSG.NEXT_THEME)
		case .upArrow:
			WallpaperServiceConnection.broadcastToService(MSG.PREVIOUS_THEME)
		case .playPause, .select:
			WallpaperServiceConnection.broadcastToService(MSG.TOGGLE_PAUSE)
		case .menu:
            print("menu button is pressed")
            let wpsi = WallpaperServiceInfo.getInstance()
            return wpsi.getPause()
		default:
			break
		}
        return false
	}
	
	func touchPadSwiped(_ swipeDirection: UISwipeGestureRecognizer.Direction) {
        print("WallpaperServiceHandler.touchPadSwiped = " + String(swipeDirection.rawValue))
		switch swipeDirection {
		case .right:
			WallpaperServiceConnection.broadcastToService(MSG.PREVIOUS)
		case .left:
			WallpaperServiceConnection.broadcastToService(MSG.NEXT)
		case .down:
			WallpaperServiceConnection.broadcastToService(MSG.NEXT_THEME)
		case .up:
			WallpaperServiceConnection.broadcastToService(MSG.PREVIOUS_THEME)
		default:
			break
		}
	}
	
	func touchPadTapped(_ count:Int) {
        print("WallpaperServiceHandler.touchPadTapped = " + String(count))
		// TVOS causes mixed event with .select
		if (PlatformInfo._deviceType == .iPhone || PlatformInfo._deviceType == .iPad) {
			if (count == 1) {
				WallpaperServiceConnection.broadcastToService(MSG.TOGGLE_PAUSE)
			} else if (count == 2) {
				WallpaperServiceConnection.broadcastToService(MSG.OPEN_SETTING_UI)
			}
		} else if (PlatformInfo._deviceType == .AppleTV) {
			if (count == 2) {
				WallpaperServiceConnection.broadcastToService(MSG.OPEN_SETTING_UI)
			}
		}
	}
}
