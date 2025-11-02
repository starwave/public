//
//  WallpaperInfoWindowController.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/11/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import Cocoa

var _wallpaperInfoWindowUI: WallpaperInfoUI?

class WallpaperInfoUI: NSWindowController, NSWindowDelegate {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        // must assign to retain the instance of WallpaperInfoWindowController
        _wallpaperInfoWindowUI = self
		
		if (AppUtil.isMyServiceRunning()) {
			_serviceRunning = true
			_serviceConnection = WallpaperServiceConnection.bindService(WallpaperInfoWindowController: self)
		} else {
			_serviceRunning = false
		}
		_themeComboBox.addItems(withObjectValues: ThemeInfo.getLabels())
        updateLayoutWithServiceInfo()
		self.window?.delegate = self
    }
	
    @IBAction func chooseDirButtonPressed(sender: AnyObject?) {
        BPUtil.BPLog("chooseDirButtonPressed")
		DirectoryChooserDialog.directoryChooserDialog(window: self.window!, completion: { (path) in
			if path != nil {
				self._serviceConnection?.sendMessageToService(command: MSG.SET_ROOT, objectOption: path)
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
					self.updateLayoutWithServiceInfo()
				}
			}
		})
    }
	
	@IBAction func themeComboBoxChanged(sender: AnyObject?) {
        BPUtil.BPLog("themeComboBoxChanged")
		let index = _themeComboBox.indexOfSelectedItem
		_serviceConnection?.sendMessageToService(command:MSG.SET_THEME, intOption: index)
	}
	
	@IBAction func saverButtonPressed(sender: AnyObject?) {
        BPUtil.BPLog("saverButtonPressed")
		_serviceConnection?.sendMessageToService(command:MSG.SET_SAVER, intOption: _saverButton.state == NSControl.StateValue.on ? 1 : 0)
	}
	
	@IBAction func intervalSeekbarChanged(sender: AnyObject?) {
        BPUtil.BPLog("intervalSeekbarChanged " + String(_intervalSeekBar.intValue))
		_serviceConnection?.sendMessageToService(command:MSG.SET_INTERVAL, intOption: Int(_intervalSeekBar.intValue))
	}
	
    @IBAction func startStopButtonPressed(sender: AnyObject?) {
        BPUtil.BPLog("startStopButtonPressed")
        if (AppUtil.isMyServiceRunning()) {
            _serviceRunning = true;
        } else {
            _serviceRunning = false;
        }
        
        if (_serviceRunning) {
			WallpaperServiceConnection.stopService()
			_serviceConnection?.unbindService()
			_serviceConnection = nil
        } else {
			_serviceConnection = WallpaperServiceConnection.bindService(WallpaperInfoWindowController: self)
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				WallpaperServiceConnection.startService()
			}
        }
        _serviceRunning = !_serviceRunning;
		DispatchQueue.main.asyncAfter(deadline: .now()) {
			self.updateLayoutWithServiceInfo()
		}
    }
    
    @IBAction func previousButtonPressed(sender: AnyObject?) {
        BPUtil.BPLog("previousButtonPressed")
		_serviceConnection?.sendMessageToService(command: MSG.PREVIOUS)
    }
    
    @IBAction func pauseButtonPressed(sender: AnyObject?) {
        BPUtil.BPLog("pauseButtonPressed")
        let wpsi = WallpaperServiceInfo.getInstance()
		_serviceConnection?.sendMessageToService(command: MSG.PAUSE, intOption: (!wpsi.getPause()) ? 1:0)
		updateLayoutWithServiceInfo()
    }
    
    @IBAction func nextButtonPressed(sender: AnyObject?) {
        BPUtil.BPLog("nextButtonPressed")
		_serviceConnection?.sendMessageToService(command: MSG.NEXT)
    }
	
	private func updateCustomConfigString(customConfigString:String) {
		let wpsi = WallpaperServiceInfo.getInstance()
		// request to update service only when it's different from previous set
		if (wpsi.getCustomConfigString() != customConfigString) {
			_serviceConnection?.sendMessageToService(command: MSG.CUSTOM_CONFIG, objectOption: customConfigString)
		}
	}

	@IBAction func customConfigStringEdited(sender: AnyObject?) {
        BPUtil.BPLog("customConfigStringEdited")
		let newCustomConfigString = _customConfigStringTextField.stringValue
		updateCustomConfigString(customConfigString: newCustomConfigString)
		// lose focus to be updated
		self.window?.makeFirstResponder(_themeComboBox)
		_themeComboBox.selectText(self)
	}

    @IBAction func customConfigButtonPressed(sender: AnyObject?) {
        BPUtil.BPLog("customConfigButtonPressed")
		CustomConfigDialog.openCustomConfigDialog(window: self.window!, completion: { (customConfigString) in
			if let newCustomConfigString = customConfigString {
				self.updateCustomConfigString(customConfigString: newCustomConfigString)
				// update UI with dialog return
				self._customConfigStringTextField.stringValue = newCustomConfigString
			}
		})
    }
    
    private func updateLayoutWithServiceInfo() {
        if (AppUtil.isMyServiceRunning()) {
            _serviceRunning = true;
        } else {
            _serviceRunning = false;
        }
        let wpsi = WallpaperServiceInfo.getInstance()
		let rootPath = wpsi.getSourceRootPath()
        let pretty_root_path = rootPath.replacingOccurrences(of: BPUtil.getHomeDirectory(), with: "~")
        _rootPathTextField.stringValue = pretty_root_path
		_intervalSeekBar.intValue = Int32(wpsi.getInterval())
		if (!_serviceRunning) {
			_pauseButton.image = NSImage(named: "media_play_pause.png")
		} else if (wpsi.getPause()) {
            _pauseButton.image = NSImage(named: "media_play.png")
        } else {
            _pauseButton.image = NSImage(named: "media_pause.png")
        }
        if (_serviceRunning) {
			_dirButton.isEnabled = true
			_themeComboBox.isEnabled = true
			_themeComboBox.selectItem(at: wpsi.getTheme().intValue)
			_saverButton.isEnabled = true
			_saverButton.state = wpsi.getSaver() ? NSControl.StateValue.on : NSControl.StateValue.off
            _intervalSeekBar.isEnabled = true
			// update only when it's not being edited
			if (_customConfigStringTextField.currentEditor() == nil || _customConfigStringTextField.stringValue == "") {
				_customConfigStringTextField.stringValue = wpsi.getCustomConfigString()
			}
			_customConfigStringTextField.isEnabled = true
            _previousButton.isEnabled = true
            _pauseButton.isEnabled = true
            _nextButton.isEnabled = true
            _startStopButton.image = NSImage(named: "media_stop.png")
        } else {
            _dirButton.isEnabled = false
			_themeComboBox.isEnabled = false
			_saverButton.isEnabled = false
			_saverButton.state = NSControl.StateValue.off
            _intervalSeekBar.isEnabled = false
            _customConfigStringTextField.stringValue = ""
            _customConfigStringTextField.isEnabled = false 
            _previousButton.isEnabled = false
            _pauseButton.isEnabled = false
            _nextButton.isEnabled = false
			_startStopButton.image = NSImage(named: "power_on.png")
            // clear list and update
			_lastUsedPathsList.removeAll()
            //_wallpaperAdapter.notifyDataSetChanged();
        }
        refreshThumbnail();
		/*
        _lastUsedPathsListView.invalidateViews();
        _lastUsedPathsListView.refreshDrawableState();*/
    }
	
	// UI rendering callback
	@objc func wallpaperInfoUpdated(isFullUpdate:Bool) {
		if (isFullUpdate) {
			// let wpsi = WallpaperServiceInfo.getInstance();
			// makeListViewItem(wpsi.getLastUsedPaths());
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			self.updateLayoutWithServiceInfo()
		}
	}

	func refreshThumbnail() {
		if (_serviceRunning) {
			let wpsi = WallpaperServiceInfo.getInstance()
			if (wpsi.getThumbnail() != nil) {
				_thumbnailView.image = wpsi.getThumbnail()
                return
			}
		}
        _thumbnailView.image = NSImage(named: "thirdwave.png")
	}
	
	func refreshlastUsedPathsListView() {
/*		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		String path = wpsi.getcurrentWPath();
		if (path != null) {
			int index = _lastUsedPathsList.indexOf(path);
			if (index < 0) {
				if (_lastUsedPathsList.size() + _lastUsedPathsRemovalCounnt + 1 > WallpaperService._maxLastUsedPaths) {
					_lastUsedPathsList.removeLast();
				}
				_lastUsedPathsList.addFirst(path);
				index =  0;

			}
			_wallpaperAdapter.setSelectedRow(index);
			_lastUsedPathsListView.smoothScrollToPosition(index);
		}
		_wallpaperAdapter.notifyDataSetChanged();
*/
	}
	
	func broadcastReceiver(thumbnail:NSImage?, currentWPath:WPath?, pause:Bool) {
		// print("WallpaperInfoUI.broadcastReceiver()")
		if (WallpaperInfoUI._singleWindow != nil) {
			wallpaperInfoUpdated(isFullUpdate: false)
		} else {
			// print("Error - Broadcast shouldn't be delivered without UI")
		}
	}
	
    // followings are not needed with init(windowNibName: "nib_name")
	/*
    override var windowNibName: String? { return "WallpaperInfoUI" }
    override var owner: AnyObject? { return self }
	*/
	private var _serviceConnection:WallpaperServiceConnection? = nil
    private var _serviceRunning:Bool = false;

    @IBOutlet weak var _rootPathTextField: NSTextField!
    @IBOutlet weak var _themeComboBox: NSComboBox!
    @IBOutlet weak var _saverButton: NSButton!
    @IBOutlet weak var _intervalSeekBar: NSSlider!
    @IBOutlet weak var _dirButton: NSButton!
    @IBOutlet weak var _pauseButton: NSButton!
    @IBOutlet weak var _startStopButton: NSButton!
    @IBOutlet weak var _previousButton: NSButton!
    @IBOutlet weak var _nextButton: NSButton!
    @IBOutlet weak var _thumbnailView: ThumbnailView!
    @IBOutlet weak var _customConfigStringSetButton: NSButton!
    @IBOutlet weak var _customConfigStringTextField: NSTextField!
    @IBOutlet weak var _lastUsedPathsTableView: NSTableView!

    private static var _filterStringEditingColor:NSColor = NSColor.red // Color.parseColor("#FFFCDC");
	private var _lastUsedPathsList:Array<String> = Array<String>()
    private static var _selectedRowColor:NSColor = NSColor.black // = Color.parseColor("#FFFC99");

    // Const value property
    public static var _lastUsedPathsRemovalCounnt:Int = 5
	
	// Ensure NSWindow Single Instance
    class func showOptionWindow(isToggle:Bool = false) {
		if (_singleWindow == nil) {
			let wallpaperInfoWindowController = WallpaperInfoUI.init(windowNibName: "WallpaperInfoUI")
            if let sf = NSScreen.main?.visibleFrame {
                let wf = wallpaperInfoWindowController.window!.frame
                wallpaperInfoWindowController.window!.setFrame(
                    NSMakeRect(NSWidth(sf) - NSWidth(wf),
							   NSHeight(sf) - NSHeight(wf) + sf.minY,
							   wf.size.width,
							   wf.size.height), display: true)
            }
			wallpaperInfoWindowController.showWindow(nil)
			_singleWindow=wallpaperInfoWindowController.window
		} else if (isToggle) {
            _singleWindow?.close()
            _singleWindow = nil
            return
        }
		// Bring Window to front in either case
		NSApp.activate(ignoringOtherApps: true)
	}
	
	func windowWillClose(_ notification: Notification) {
		_serviceConnection?.unbindService()
		WallpaperInfoUI._singleWindow = nil
	}
	
	static public let _defaultCustomConfigString =
					ThemeInfo._default_custom_root + ";" +
					ThemeInfo._default_custom_allow + ";" +
					ThemeInfo._default_custom_filter
	
	static var _singleWindow:NSWindow? = nil
    
}

class ThumbnailView: NSImageView {
    override func mouseDown(with event: NSEvent) {
		super.mouseDown(with: event)
        BPUtil.BPLog("ThumbnailView mouseDown")
		let wpsi = WallpaperServiceInfo.getInstance()
		if let currentWPath = wpsi.getcurrentWPath() {
            if (BPUtil.optionKeyPressed()) {
				BPUtil.showImageFile(with: currentWPath.path)
                } else {
                BPUtil.openImagePreview(with: currentWPath.path)
            }
		}
    }
}


