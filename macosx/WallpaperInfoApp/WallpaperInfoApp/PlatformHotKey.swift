//
//  PlatformHotKey.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/30/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import Cocoa

class PlatformHotKey {
	
	public func initEventPort() {
		_trialCount = 0
		if (!_trying) {
			_trying = true
			if let eventPort = PlatformHotKey._eventPort {
                if CGEvent.tapIsEnabled(tap: eventPort) {
                    CGEvent.tapEnable(tap: eventPort, enable: false)
                }
				PlatformHotKey._eventPort = nil
            }
			initEventPortInternal();
		}
	}
    
    private func initEventPortInternal() {
        let cCallback: CGEventTapCallBack = { proxy, type, event, refcon in
            let innerBlock = unsafeBitCast(refcon, to: EventTapCallback.self)
            return innerBlock(type, event).map(Unmanaged.passUnretained)
        }
        // print("WallpaperInfoApp is trusted? " + String(AXIsProcessTrusted()))
        let refcon = unsafeBitCast(_mycallback, to: UnsafeMutableRawPointer.self)
        guard let eventPort = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                              place: .headInsertEventTap,
                                              options: .defaultTap,
                                              eventsOfInterest: CGEventMask(1 << NX_SYSDEFINED),
                                              callback: cCallback,
                                              userInfo: refcon) else {
                                                BPUtil.BPLog("PlatformHotKey.initEventPort - Error to tab media key")
                                                self.retryInitEventPort()
                                                return
        }
        _trying = false
		PlatformHotKey._eventPort = eventPort
        WallpaperWidgetProvider.updateLabelWidget(text: "Media key is enabled")
        _runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventPort, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), _runLoopSource!, .commonModes)
        CGEvent.tapEnable(tap: eventPort, enable: true)
        // CFRunLoopRun()
    }
    
    private func retryInitEventPort() {
        if _trialCount <= _maxTrialCount {
			_trialCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(_nextTrialInSeconds), execute: {
                // print("retryInitEventPort()")
                if (PlatformHotKey._eventPort == nil) {
					self.initEventPortInternal()
                }
            })
		} else {
			_trying = false;
		}
    }
	
	static func ensureEventPortEnabled() {
		struct Current {
			static var count = 0
			static var lockEventPort = NSObject()
		}
		objc_sync_enter(Current.lockEventPort)
		Current.count += 1
		let originalCount = Current.count
		DispatchQueue.background(delay: 0.8, completion:{
			if (originalCount == Current.count) {
				if (!CGEvent.tapIsEnabled(tap: PlatformHotKey._eventPort!)) {
                    BPUtil.BPLog("PlatformHotKey.ensureEventPortEnabled - Enable eventport again")
					CGEvent.tapEnable(tap: PlatformHotKey._eventPort!, enable: true)
				}
			}
		})
		objc_sync_exit(Current.lockEventPort)
	}
    
	private var _trialCount = 0;
	private var _runLoopSource: CFRunLoopSource? = nil
	private var _trying = false;
	private let _nextTrialInSeconds = 5;
    private let _maxTrialCount = 20;
	private static var _buttonReleased = true
    static private var _eventPort:CFMachPort? = nil
    // callback must be assigned only once in here to avoid any crash during re-assignment
    private let _mycallback: EventTapCallback = {  type, event in
        if (Int(type.rawValue) < 0 || Int(type.rawValue) > 0x7fffffff) { // kCGSLastEventType = 0x7fffffff
            // print ("type = " + String(type.rawValue))
            return nil
        }
		
		// this code is needed since PlatformInfo.bluetoothRemoteExists() sometimes disabled eventport
		PlatformHotKey.ensureEventPortEnabled()
		
        if let nsEvent = NSEvent(cgEvent: event) {
            if (nsEvent.type == .systemDefined && nsEvent.subtype.rawValue == NX_SUBTYPE_AUX_CONTROL_BUTTONS) {
                let keyCode = ((nsEvent.data1 & 0xFFFF0000) >> 16)
                let keyFlags = (nsEvent.data1 & 0x0000FFFF)
                let keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA
                // print("keyCode = " + String(keyCode) + ", KeyState = " + String(keyState) + ", KeyFlags = " +  String(keyFlags))
                switch (Int32(keyCode)) {
                
                case NX_KEYTYPE_PLAY:
                    if (keyState == false) {
                        BPUtil.BPLog("play/pause key/remote pressed")
                        WallpaperServiceConnection.broadcastToService(MSG.TOGGLE_PAUSE)
                    }
                    return nil // preventing from launching iTunes
                
                case NX_KEYTYPE_FAST, NX_KEYTYPE_NEXT :         // NX_KEYTYPE_FAST 19 (key), NX_KEYTYPE_NEXT 17 (remote)
                    if (keyState == true) {
                        if (_buttonReleased) {
                            BPUtil.BPLog("next key/remote pressed")
                            WallpaperServiceConnection.broadcastToService(MSG.NEXT)
                        }
                        _buttonReleased = false
                    } else {
                        _buttonReleased = true
                    }
                    return nil // preventing from doing other tasks
                
                case NX_KEYTYPE_REWIND, NX_KEYTYPE_PREVIOUS :   // NX_KEYTYPE_REWIND 20 (key), NX_KEYTYPE_PREVIOUS 19 (remote)
                    if (keyState == true) {
                        if (_buttonReleased) {
                            BPUtil.BPLog("previous key/remote pressed")
                            WallpaperServiceConnection.broadcastToService(MSG.PREVIOUS)
                        }
                        _buttonReleased = false
                    } else {
                        _buttonReleased = true
                    }
                    return nil // preventing from doing other tasks
                    
                case NX_KEYTYPE_SOUND_UP:                       // NX_KEYTYPE_SOUND_UP 0
					if PlatformInfo.bluetoothRemoteExists() {
						if BPUtil.shiftKeyPressed() {
							return event
						}
					} else {
						if !BPUtil.shiftKeyPressed() {
							return event
						}
					}
                    if (keyState == true) {
                        if (_buttonReleased) {
                            BPUtil.BPLog("previous theme key/remote pressed")
                            WallpaperServiceConnection.broadcastToService(MSG.PREVIOUS_THEME)
                        }
                        _buttonReleased = false
                    } else {
                        _buttonReleased = true
                    }
                    return nil // preventing from doing other tasks
                    
                case NX_KEYTYPE_SOUND_DOWN:   // NX_KEYTYPE_SOUND_UP 1, NX_KEYTYPE_EJECT
					if PlatformInfo.bluetoothRemoteExists() {
						if BPUtil.shiftKeyPressed() {
							return event
						}
					} else {
						if !BPUtil.shiftKeyPressed() {
							return event
						}
					}
                    if (keyState == true) {
                        if (_buttonReleased) {
                            BPUtil.BPLog("next theme string key/remote pressed")
                            WallpaperServiceConnection.broadcastToService(MSG.NEXT_THEME)
                        }
                        _buttonReleased = false
                    } else {
                        _buttonReleased = true
                    }
                    return nil // preventing from doing other tasks
                    
                default:
                    return event
                }
             }
        }
        return event
    }
}
