//
//  ViewController.swift
//  tromso-ios
//
//  Created by Brad Park on 5/21/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import UIKit

// to void compile error
typealias ContentView = TromsoIOS9ViewController

class TromsoIOS9ViewController: UIViewController, WallpaperServiceDelegate {

	private var _wallpaperImage: UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width:100, height: 100))
	var _pauseWidget: UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width:100, height: 100))
    var _themeWidget:UITextView = UITextView(frame: CGRect(x: 0, y: 0, width:100, height: 100))
    var _labelWidget:UITextView = UITextView(frame: CGRect(x: 0, y: 0, width:100, height: 100))
    private var _platformHotKeyViewController = PlatformHotKeyViewController()
	private var _observer: NSObjectProtocol?

	override func viewDidLoad() {
		super.viewDidLoad()
		repositionUI()
		_serviceConnection = WallpaperServiceConnection.bindService(contentView: self)
		_wallpaperImage.image = UIImage(named: "tromso")
		_wallpaperImage.contentMode = UIView.ContentMode.scaleAspectFit
		self.view.addSubview(_wallpaperImage)
		self.view.backgroundColor = UIColor.black
		self.view.bringSubviewToFront(_wallpaperImage)
		self.view.addSubview(_platformHotKeyViewController.view)
		_pauseWidget.image = UIImage(named: "media_play")
		_pauseWidget.backgroundColor = UIColor.white
		_pauseWidget.isHidden = true
		self.view.addSubview(_pauseWidget)
		_themeWidget.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.bold)
		_themeWidget.textColor = UIColor.white
		_themeWidget.backgroundColor = UIColor.clear
		_themeWidget.layer.shadowColor = UIColor.black.cgColor
		_themeWidget.layer.shadowOpacity = 0.8
		_themeWidget.layer.shadowOffset = CGSize(width: 3.0, height: 3.0)
		_themeWidget.layer.shadowRadius = 6.0;
		_themeWidget.isHidden = true
		self.view.addSubview(_themeWidget)
        _labelWidget.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.bold)
        _labelWidget.textColor = UIColor.white
        _labelWidget.backgroundColor = UIColor.clear
        _labelWidget.layer.shadowColor = UIColor.black.cgColor
        _labelWidget.layer.shadowOpacity = 0.8
        _labelWidget.layer.shadowOffset = CGSize(width: 3.0, height: 3.0)
        _labelWidget.layer.shadowRadius = 6.0;
        _labelWidget.isHidden = false
        self.view.addSubview(_labelWidget)
		let wpsi = WallpaperServiceInfo.getInstance()
		wpsi.getWallpaperService().setWallpaperServiceDelegate(self)
		_observer = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [unowned self] notification in
            self.themeUpdateOnUI(themeString: wpsi.getTheme().label, forceShow: true)
            // file sync when app becomes foreground
            wpsi.getWallpaperService().syncServerFiles()
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		print("viewDidAppear")
		let wpsi = WallpaperServiceInfo.getInstance()
		setIdleTimerDisabled(!wpsi.getPause())
        self.themeUpdateOnUI(themeString: wpsi.getTheme().label, forceShow: true)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		print("viewWillDisappear")
		setIdleTimerDisabled(false)
	}
	
	deinit {
		print("deinit")
		// move the logic to here since viewWillDisappear is called when modal is up
		let wpsi = WallpaperServiceInfo.getInstance()
		wpsi.getWallpaperService().setWallpaperServiceDelegate(nil)
		// Comment for Now
		// self._serviceConnection?.unbindService()
		// self._serviceConnection = nil
	}
	
    func setWallpaperOnUI(newImage: UIImage) {
        DispatchQueue.main.async {
			self._wallpaperImage.image = newImage
        }
    }
	
	public func setIdleTimerDisabled(_ set:Bool) {
		UIApplication.shared.isIdleTimerDisabled = set
	}

    func playPauseUpdateOnUI(isPaused: Bool) {
		DispatchQueue.main.async {
			struct PauseClicked {
				static var count = 0
                static var isPaused = true
			}
			if (isPaused) {
				self._pauseWidget.image = UIImage(named: "media_pause")
                self.themeUpdateOnUI(themeString: WallpaperServiceInfo.getInstance().getTheme().label, forceShow: true)
			} else {
				self._pauseWidget.image = UIImage(named: "media_play")
			}
            if (isPaused != PauseClicked.isPaused) {
                self._pauseWidget.isHidden = false
                PauseClicked.count += 1
                PauseClicked.isPaused = isPaused
                if (!isPaused) {
                    let old_value = PauseClicked.count
                    DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                        if (old_value == PauseClicked.count) {
                            self._pauseWidget.isHidden = true
                            PauseClicked.count = 0
                        }
                    }
                }
            }
    
		}
    }
    
    func themeUpdateOnUI(themeString: String, forceShow:Bool) {
        DispatchQueue.main.async {
            struct ThemeChange {
                static var count = 0
                static var themeString = ""
            }
            self._themeWidget.text = themeString
            if (themeString != ThemeChange.themeString || forceShow) {
                self._themeWidget.isHidden = false
                ThemeChange.count += 1
                ThemeChange.themeString = themeString
                let old_value = ThemeChange.count
                DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
                    if (old_value == ThemeChange.count) {
                        self._themeWidget.isHidden = true
                        ThemeChange.count = 0
                    }
                }
            }
        }
    }
       
    func labelUpdateOnUI(labelString: String) {
        DispatchQueue.main.async {
            self._labelWidget.text = labelString
        }
    }
	
	func repositionUI() {
		_wallpaperImage.frame = CGRect(x: 0, y: 0,
									 width: UIScreen.main.bounds.size.width,
									 height: UIScreen.main.bounds.size.height)
		_pauseWidget.frame = CGRect(x: UIScreen.main.bounds.size.width - 40,
                                    y: UIScreen.main.bounds.size.height - 30,
                                    width: 15, height: 15)
		_themeWidget.frame = CGRect(x: UIScreen.main.bounds.size.width - 100,
                                    y: 10,
                                    width: 140, height: 50)
        _labelWidget.frame = CGRect(x: 10,
                                    y: UIScreen.main.bounds.size.height - 40,
                                    width: 600, height: 50)
	}
	
	func openSettingUI() {
		print("customConfigButtonPressed")
		CustomConfigDialog.openCustomConfigDialog(viewController: self, completion: { (customConfigString) in
			if let newCustomConfigString = customConfigString {
				self.updateCustomConfigString(customConfigString: newCustomConfigString)
			}
		})
	}
	
	override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
		PlatformInfo.calcScreenDimension()
		repositionUI()
	}
	
	func updateCustomConfigString(customConfigString: String) {
		let wpsi = WallpaperServiceInfo.getInstance()
		// request to update service only when it's different from previous set
		if (wpsi.getCustomConfigString() != customConfigString) {
			_serviceConnection?.sendMessageToService(command: MSG.CUSTOM_CONFIG, objectOption: customConfigString)
		}
	}
	
	public var _serviceConnection:WallpaperServiceConnection? = nil
}

