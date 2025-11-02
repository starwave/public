//
//  WallpaperWidget.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/13/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import Cocoa

class WallpaperWidgetProvider : NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
        print("WallpaperWidgetProvider.windowDidLoad()")
    }
    
    class func refreshWidgets() {
		clearWidgets(dict: _labelWidgetsDictionary)
		clearWidgets(dict: _themeWidgetsDictionary)
		clearWidgets(dict: _pauseWidgetsDictionary)
        for screen in NSScreen.screens {
			// Label Widget
            let newLabelWidget = WallpaperWidget(contentRect: NSMakeRect(0, 0, 600, 50), styleMask: .titled, backing: .buffered, defer: false)
            let labelWigetController = WallpaperWidgetProvider.init(window: newLabelWidget)
            let dockHeight = PlatformInfo.getDockHeight(screen: screen)
            newLabelWidget.delegate = labelWigetController
            labelWigetController.showWindow(nil)
            newLabelWidget.contentView?.addSubview(newLabelWidget._captionTextField)
			newLabelWidget.setFrameOrigin(CGPoint(x:screen.frame.origin.x + 20,
												  y:screen.frame.origin.y + dockHeight))
            _labelWidgetsDictionary.setValue(newLabelWidget, forKey: String(screen.hashValue))
			
			// Theme Widget
            let newThemeWidget = WallpaperWidget(contentRect: NSMakeRect(0, 0, 100, 50), styleMask: .titled, backing: .buffered, defer: false)
            let themeWigetController = WallpaperWidgetProvider.init(window: newThemeWidget)
            newThemeWidget.delegate = themeWigetController
            themeWigetController.showWindow(nil)
            newThemeWidget.contentView?.addSubview(newThemeWidget._captionTextField)
			newThemeWidget.setFrameOrigin(CGPoint(x:screen.frame.origin.x + screen.frame.width - 200,
												  y:screen.frame.origin.y + screen.frame.height - 80))
            _themeWidgetsDictionary.setValue(newThemeWidget, forKey: String(screen.hashValue))
			
			// Pause Widget
            let newPauseWidget = WallpaperWidget(contentRect: NSMakeRect(0, 0, 600, 50), styleMask: .titled, backing: .buffered, defer: false)
            let pauseWigetController = WallpaperWidgetProvider.init(window: newPauseWidget)
            newPauseWidget.delegate = pauseWigetController
            pauseWigetController.showWindow(nil)
            newPauseWidget.contentView?.addSubview(newPauseWidget._captionTextField)
			newPauseWidget.setFrameOrigin(CGPoint(x:screen.frame.origin.x + screen.frame.width - 200,
												  y:screen.frame.origin.y + dockHeight))
            _pauseWidgetsDictionary.setValue(newPauseWidget, forKey: String(screen.hashValue))
        }
    }
    
    class func updateLabelWidget(text: String, screen screenParm:NSScreen? = nil) {
        DispatchQueue.main.async {
            let labelWidgets = prepareWidgetsArray(dict:_labelWidgetsDictionary, screen:screenParm)
            for labelWidget in labelWidgets {
                labelWidget._captionTextField.stringValue = text
            }
        }
    }
	
	class func updateThemeWidget(themeLabel:String, screen screenParm:NSScreen? = nil, forceShow:Bool = false) {
		let themeWidgets = prepareWidgetsArray(dict:_themeWidgetsDictionary, screen:screenParm)
		for themeWidget in themeWidgets {
			if (themeWidget._captionTextField.stringValue != themeLabel || forceShow) {
				themeWidget._captionTextField.isHidden = false
				themeWidget._captionTextField.stringValue = themeLabel
				_themeChangeCount += 1
			}
			if (!themeWidget._captionTextField.isHidden && !forceShow) {
				let old_value = _themeChangeCount
				DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
					if (old_value == self._themeChangeCount) {
						themeWidget._captionTextField.isHidden = true
					}
				}
			}
        }
	}
	
	class func updatePauseWidget(pause:Bool, screen screenParm:NSScreen? = nil) {
		let pauseWidgets = prepareWidgetsArray(dict:_pauseWidgetsDictionary, screen:screenParm)
		for pauseWidget in pauseWidgets {
			pauseWidget._captionTextField.stringValue = (pause) ? "\u{23F8}" : ""
        }
	}
	
	class private func clearWidgets(dict:NSMutableDictionary) {
        for (_, value) in dict {
			let widget = value as! WallpaperWidget
			widget.close()
        }
        dict.removeAllObjects()
	}
	
	class private func prepareWidgetsArray(dict:NSMutableDictionary, screen screenParm:NSScreen?) -> Array<WallpaperWidget> {
		var widgets:[WallpaperWidget]=[]
		if screenParm != nil {
			widgets.append(dict.value(forKey: String(screenParm.hashValue)) as! WallpaperWidget)
		} else {
			for (_, value) in dict {
				widgets.append(value as! WallpaperWidget)
			}
		}
		return widgets;
	}
	
    private var _screen:NSScreen?
	static var _themeChangeCount = 0
    static var _labelWidgetsDictionary:NSMutableDictionary=NSMutableDictionary()
    static var _themeWidgetsDictionary:NSMutableDictionary=NSMutableDictionary()
    static var _pauseWidgetsDictionary:NSMutableDictionary=NSMutableDictionary()
}

class WallpaperWidget : NSWindow {
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: bufferingType, defer: flag)
		makeWindowWidget(widgetRect:contentRect)
    }

	// make it not responding to any user input
    override var canBecomeKey: Bool { return false }
    override var canBecomeMain: Bool { return false }
    
	private func makeWindowWidget(widgetRect:NSRect) {
        self.isOpaque = false
        self.hasShadow = false
        self.backgroundColor = NSColor.clear
        self.styleMask = NSWindow.StyleMask.borderless
        self.level = NSWindow.Level(rawValue: NSWindow.Level.normal.rawValue - 1)
        // make it not responding option + F3 key
        self.collectionBehavior = NSWindow.CollectionBehavior(rawValue:
            NSWindow.CollectionBehavior.canJoinAllSpaces.rawValue |
            NSWindow.CollectionBehavior.stationary.rawValue |
            NSWindow.CollectionBehavior.ignoresCycle.rawValue);
        //self.title = "BP Wallpaper"
        //self.titleVisibility = .hidden
        //self.titlebarAppearsTransparent = true
		self._captionTextField = makeWidgetTextField(widgetRect:widgetRect)
    }
    
    private func makeWidgetTextField(widgetRect:NSRect) -> NSTextField {
		let captionTextField = NSTextField(frame:
			NSMakeRect(widgetRect.minX + 5,
					   widgetRect.minY + 5,
					   widgetRect.maxX - 10,
					   widgetRect.maxY - 20))
		// let captionTextField = NSTextField(frame: NSMakeRect(5,5,590,30))
        captionTextField.isBezeled         = false
        captionTextField.isEditable        = false
        captionTextField.font = NSFont(name: "Lucida Sans", size: 15)
        captionTextField.drawsBackground = false
        captionTextField.textColor = NSColor.white
        // captionTextField.alignment = .center
        // captionTextField.backgroundColor = NSColor.black

		let shadow: NSShadow = NSShadow()
		shadow.shadowBlurRadius = 2
		shadow.shadowOffset = NSMakeSize(4, 4)
		shadow.shadowColor = NSColor.black
		captionTextField.shadow = shadow
		// make shadow working for EL Capitan
		captionTextField.wantsLayer = true

        return captionTextField
    }
   
    var _captionTextField: NSTextField = NSTextField()
}

