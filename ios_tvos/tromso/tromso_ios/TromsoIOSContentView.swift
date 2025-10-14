//
//  ContentView.swift
//  tromso_ios
//
//  Created by Brad Park on 5/20/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import SwiftUI

struct ContentView: View, WallpaperServiceDelegate {
    @State var _wallpaperImage: UIImage? = UIImage(named: "tromso")
    @State var _pauseIndicatorImage: UIImage? = UIImage(named: "media_play")
    @State var _themeWidgetString:String = "Default"
    @State var _labelWidgetString:String = ""
    @State private var _isShowingThemeWidget:Bool = false
    @State private var _isShowingLabelWidget:Bool = true
    @State private var _isShowingPauseWidget:Bool = false
	@State private var _isShowingTromsoOptionUI = false
	@State public var _serviceConnection:WallpaperServiceConnection? = nil
	@GestureState var scale: CGFloat = 1.0

    var body: some View {
        NavigationView {
            ZStack {
                Image(uiImage: self._wallpaperImage!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(minWidth: CGFloat(0), maxWidth: .infinity, minHeight: CGFloat(0), maxHeight: .infinity)
                    .background(Color.black)
                    .edgesIgnoringSafeArea(.all)
					.prefersHomeIndicatorAutoHidden(true)
					.scaleEffect(scale)
                PlatformHotKey()
					.gesture(MagnificationGesture()
						.updating($scale, body: { (value, scale, trans) in
							scale = value.magnitude
						})
					)
					.sheet(isPresented: $_isShowingTromsoOptionUI) {
						VStack {
							TromsoOptionUI(parent:self, completion: { (customConfigString) in
								let wpsi = WallpaperServiceInfo.getInstance()
								// request to update service only when it's different from previous set
								if (wpsi.getCustomConfigString() != customConfigString) {
									self._serviceConnection?.sendMessageToService(command: MSG.CUSTOM_CONFIG, objectOption: customConfigString)
								}
								})
						}
						.onAppear() {
							self.setIdleTimerDisabled(false)
							self._serviceConnection?.sendMessageToService(command: MSG.PAUSE, intOption: 1)
						}
						.onDisappear {
							self.setIdleTimerDisabled(true)
							self._serviceConnection?.sendMessageToService(command: MSG.PAUSE, intOption: 0)
						}
					}
                GeometryReader { geometry in
                    HStack {
                        if self._isShowingThemeWidget {
                            Text(self._themeWidgetString)
                                .foregroundColor(Color.white)
                                .font(.system(size: 16.0))
                                .shadow(color: Color.black.opacity(0.8), radius: 6, x: 3, y: 3)
                        }
                    }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                    .position(x:geometry.size.width + ((PlatformInfo._deviceType == .iPad) ? -70 : -50),
                              y:((PlatformInfo._deviceType == .iPad) ? 5 : 20))
                }
                HStack {
                    if self._isShowingLabelWidget {
                        GeometryReader { geometry in
                            Text(self._labelWidgetString)
                                .foregroundColor(Color.white)
                                .background(Color.black.opacity(0.2))
                                .font(.system(size: 16.0))
                                .shadow(color: Color.black.opacity(0.8), radius: 6, x: 3, y: 3)
                                .padding(.leading, 10)
                                .padding(.bottom, 5)
                                .frame(maxWidth: geometry.size.width, maxHeight: .infinity, alignment: .bottomLeading) // Align to bottom leading
                        }
                    }
                }
                HStack {
                    if self._isShowingPauseWidget {
                        Image(uiImage: self._pauseIndicatorImage!)
                            .background(Color.white.opacity(0.7))
                            .padding(.trailing, 20)
                            .padding(.bottom, 5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing) // Align to bottom trailing
                    }
                }

            }
			.navigationBarTitle("")
            .navigationBarHidden(true)
		}.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
			let wpsi = WallpaperServiceInfo.getInstance()
            self.themeUpdateOnUI(themeString: wpsi.getTheme().label, forceShow: true)
            // file sync when app becomes foreground
            wpsi.getWallpaperService().syncServerFiles()
		}.onAppear {
			self._serviceConnection = WallpaperServiceConnection.bindService(contentView: self)
            // ios app defers to get dimension due to orientation fix
            PlatformInfo.calcScreenDimension()
			// following should be in View event instead of applicatin event
			let wpsi = WallpaperServiceInfo.getInstance()
			self.setIdleTimerDisabled(!wpsi.getPause())
			wpsi.getWallpaperService().setWallpaperServiceDelegate(self)
            self.themeUpdateOnUI(themeString: wpsi.getTheme().label, forceShow: true)
            self.playPauseUpdateOnUI(isPaused: wpsi.getPause())
		}.onDisappear {
			self.setIdleTimerDisabled(false)
			let wpsi = WallpaperServiceInfo.getInstance()
			wpsi.getWallpaperService().setWallpaperServiceDelegate(nil)
			// Comment for Now
			// self._serviceConnection?.unbindService()
			// self._serviceConnection = nil
		}
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func setWallpaperOnUI(newImage: UIImage) {
        DispatchQueue.main.async {
            self._wallpaperImage = newImage
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
				self._pauseIndicatorImage = UIImage(named: "media_pause")
				self.themeUpdateOnUI(themeString: WallpaperServiceInfo.getInstance().getTheme().label, forceShow: true)
			} else {
				self._pauseIndicatorImage = UIImage(named: "media_play")
			}
            if (isPaused != PauseClicked.isPaused) {
                withAnimation {
                    self._isShowingPauseWidget = true
                }
                PauseClicked.count += 1
                PauseClicked.isPaused = isPaused
                if (!isPaused) {
                    let old_value = PauseClicked.count
                    DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                        if (old_value == PauseClicked.count) {
                            withAnimation {
                                self._isShowingPauseWidget = false
                                PauseClicked.count = 0
                            }
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
			self._themeWidgetString = themeString
            if (themeString != ThemeChange.themeString || forceShow) {
                withAnimation {
                    self._isShowingThemeWidget = true
                }
                ThemeChange.count += 1
                ThemeChange.themeString = themeString
                let old_value = ThemeChange.count
                DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
                    if (old_value == ThemeChange.count) {
                        withAnimation {
                            self._isShowingThemeWidget = false
                            ThemeChange.count = 0
                        }
                    }
                }
            }
		}
    }
    
    func labelUpdateOnUI(labelString: String) {
        DispatchQueue.main.async {
            self._labelWidgetString = labelString
        }
    }
	
	func openSettingUI() {
		_isShowingTromsoOptionUI = true
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

