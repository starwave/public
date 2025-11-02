//
//  WallpaperNotification.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/11/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import Cocoa

class WallpaperNotification:NSObject, NSMenuDelegate {
	
	override init() {
		super.init()

		// Must load nib manuallly
		Bundle.main.loadNibNamed("StatusBarMenu", owner: self, topLevelObjects:nil)
		_statusMenu.delegate = self
		self.preparePathInMenu()

		let statusBar = NSStatusBar.system
		_statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
		_statusBarItem?.highlightMode = true
		_statusBarItem?.button?.image = NSImage(named: "toolicon.png")
		_statusBarItem?.button?.target = self
		_statusBarItem?.button?.setButtonType(NSButton.ButtonType.momentaryLight)

		_statusBarItem?.button?.action = #selector(self.statusBarButtonClicked(sender:))
		_statusBarItem?.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
		// TODO sometimes UI thread is stuck while timer events are accumulated
		NSApp.activate(ignoringOtherApps: true)
		let themeLabels = ThemeInfo.getLabels()
		var index = 0
		for label in themeLabels {
			let menuItem = NSMenuItem()
            menuItem.target = self
            menuItem.state = NSControl.StateValue.off
			menuItem.title = label
			menuItem.representedObject = Int(index)
			menuItem.isEnabled = true
			menuItem.action = #selector(themeMenuItemSelected)
			_themeMenu.addItem(menuItem)
			index += 1
		}
		updateThemeSelectionInMenu(theme: .default1)
	}
	
	func buildNotification(wpath: WPath?, thumbnail: NSImage?, theme: Theme) {
        _previousThumbnail = thumbnail
		DispatchQueue.main.async { [weak self] in
			self?.updatePathsInMenu(wpath)
            self?.setResumeOrPauseOnMenuItem()
			self?.setThumbnail(wpath: wpath, thumbnail: thumbnail)
			self?.updateThemeSelectionInMenu(theme: theme)
		}
	}
    
    private func setThumbnail(wpath: WPath?, thumbnail: NSImage?) {
		// TODO maybe copy thumbnail to be safe
        if thumbnail != nil {
            _thumbnailMenuItem.image = thumbnail
        } else {
            _thumbnailMenuItem.image = NSImage(named: "thirdwave.png")
        }
        _thumbnailMenuItem.target = self
        _thumbnailMenuItem.representedObject = wpath
        if (wpath != nil) {
            _thumbnailMenuItem.action = #selector(imageMenuItemSelected)
            _thumbnailMenuItem.isEnabled = true
        } else {
            _thumbnailMenuItem.action = nil
            _thumbnailMenuItem.isEnabled = false
        }
    }
	
	private func setResumeOrPauseOnMenuItem() {
		let wpsi = WallpaperServiceInfo.getInstance()
		if (wpsi.getPause()) {
			_pauseMenuItem?.title = "Resume"
		} else {
			_pauseMenuItem?.title = "Pause"
		}
	}
    
    private func preparePathInMenu() {
        _wallpaperMenu.removeAllItems()
        for index in (0..._maxImageList - 1).reversed() {
            let menuItem = NSMenuItem()
            menuItem.target = self
            menuItem.state = NSControl.StateValue.off
            if index < _pathsInMenu.count {
				menuItem.title = _pathsInMenu.getWPath(at: index).label()
                menuItem.representedObject = _pathsInMenu.getWPath(at: index)
                menuItem.isEnabled = true
                menuItem.action = #selector(imageMenuItemSelected)
				if (_pathsInMenu.getWPath(at: index).path == _previousPath.path) {
                    menuItem.state = NSControl.StateValue.on
                }
            } else {
                menuItem.title = "(Empty)"
                menuItem.representedObject = nil
                menuItem.isEnabled = false
                menuItem.action = nil
            }
            _wallpaperMenu.addItem(menuItem)
        }
    }
	
	private func updatePathsInMenu(_ wpath: WPath?) {
		if (wpath == nil) {
			return
		}
		if let previous_index = _pathsInMenu.firstIndex(of: _previousPath.path) {
			_wallpaperMenu.items[previous_index].state = NSControl.StateValue.off
		}
		_previousPath = wpath!
		let wpathLabel = wpath!.label()
		_statusBarItem?.toolTip = wpathLabel
		if let index = _pathsInMenu.firstIndex(of: wpath!.path) {
			_wallpaperMenu.items[index].state = NSControl.StateValue.on
		} else {
			_pathsInMenu.insert(value: wpath!.exif, forKey: wpath!.path, at: 0)
			if (_pathsInMenu.count > _maxImageList) {
				_pathsInMenu.remove(at: _maxImageList)
			}
			let menuItem = NSMenuItem()
			menuItem.target = self
			menuItem.state = NSControl.StateValue.on
			menuItem.title = wpathLabel
			menuItem.representedObject = wpath
			menuItem.isEnabled = true
			menuItem.action = #selector(imageMenuItemSelected)
			_wallpaperMenu.insertItem(menuItem, at: 0)
			if (_wallpaperMenu.items.count > _maxImageList) {
				_wallpaperMenu.removeItem(at: _maxImageList)
			}
		}
	}
	
	@objc func imageMenuItemSelected (sender : Any?) {
		let path = ((sender as! NSMenuItem).representedObject as! WPath).path
        BPUtil.BPLog("WallpaperNotification.menuItemSelected() = " + path)
		
        if BPUtil.optionKeyPressed() {
            BPUtil.showImageFile(with: path)
		} else {
            BPUtil.openImagePreview(with: path)
		}
	}
	
	private func updateThemeSelectionInMenu(theme: Theme) {
		if (theme != _previousTheme) {
			_themeMenu.items[_previousTheme.intValue].state = NSControl.StateValue.off
			_previousTheme = theme
			_themeMenu.items[theme.intValue].state = NSControl.StateValue.on
		}
	}
	
	@objc func themeMenuItemSelected (sender : Any?) {
		let menuItem = sender as! NSMenuItem
		if let theme = Theme(rawValue: (menuItem.representedObject as! Int)) {
			WallpaperServiceConnection.broadcastToService(MSG.SET_THEME, extras:theme.intValue)
		}
	}

    @IBAction func showWallpaperInfoOptionWindow(sender: AnyObject?) {
		WallpaperInfoUI.showOptionWindow()
    }
	
	@IBAction func actionPreviousImage(sender: AnyObject?) {
        WallpaperServiceConnection.broadcastToService(MSG.PREVIOUS)
	}
	
	@IBAction func actionNextImage(sender: AnyObject?) {
        WallpaperServiceConnection.broadcastToService(MSG.NEXT)
	}
	
	@IBAction func actionPauseResume(sender: AnyObject?) {
        WallpaperServiceConnection.broadcastToService(MSG.TOGGLE_PAUSE)
	}
	
	@IBAction func actionAbout(sender:AnyObject?) {
		_platformHotKey.initEventPort()
		NSApplication.shared.orderFrontStandardAboutPanel(nil)
	}
	
	@objc func statusBarButtonClicked(sender: Any?) {
        let event = NSApp.currentEvent!
        if event.type ==  NSEvent.EventType.rightMouseUp {
            if #available(OSX 10.15, *) {
                if let button = _statusBarItem?.button {
                    NSMenu.popUpContextMenu(self._statusMenu, with: event, for:button)
                }
            } else {
                _statusBarItem?.menu = self._statusMenu
                _statusBarItem?.button?.performClick(nil)
            }
        } else {
            WallpaperInfoUI.showOptionWindow(isToggle: true)
        }
	}
	
	// menu will block left click acion. so delete menu and put the action back
	func menuDidClose(_ menu: NSMenu) {
		self._statusBarItem?.menu = nil
		_statusBarItem?.button?.action = #selector(self.statusBarButtonClicked(sender:))
		_statusBarItem?.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
	}
	
	// use strong (by default) over weak reference sicnce menu loaded by code is not retained by weak outlet
	@IBOutlet var _statusMenu:NSMenu!
    @IBOutlet var _thumbnailMenuItem:NSMenuItem!
    @IBOutlet var _pauseMenuItem:NSMenuItem!
    @IBOutlet var _wallpaperMenu:NSMenu!
    @IBOutlet var _themeMenu:NSMenu!
    private var _statusBarItem:NSStatusItem?
    
	private var _pathsInMenu:WLinkedHashMap<String, String> = WLinkedHashMap<String, String>()
    private var _previousPath:WPath = WPath(path: "", exif: "")
	private var _previousTheme:Theme = .default2
    public var _platformHotKey:PlatformHotKey = PlatformHotKey();
    private var _previousThumbnail:NSImage? = nil
    
	private let _maxImageList:Int = 20
    
}
