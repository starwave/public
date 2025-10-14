using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WallpaperInfoApp {

	class WallpaperService {

		public WallpaperService() {
			// workaround for lazy binding since threre is no easy thing in c# comparing to swift
			_wallpaperServiceHandler = new WallpaperServiceHandler(this);
		}

		~WallpaperService() {
	        if (_started) {
				onDestroy();
			}
		}

		public void startService() {
			onStartCommand();
		}

		public void stopService() {
            _imageFileManager.stopWatching(); // to interrupt exif read
			onDestroy();
		}

		public void onDestroy() {
			// stop timer when service is destroyed to prevent service is rerunning
			_platformTimer.pause();

			// update widget for default view
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			wpsi.setcurrentWPath(default(WPath));
			wpsi.setThumbnail(null);
			if (_started) {
				SystemEvents.DisplaySettingsChanged -= screenChangeCallback;
				_started = false;
			}
			broadcastServiceUpdate();
		}

		public void broadcastReceiver(int action, int extras = 0) {
            if (!_started) {
                return;
            }
			switch (action) {
                case MSG.SET_THEME:
                    BPUtil.BPLog("WallpaperServicebroadcastReceiver - MSG.SET_THEME");
                    var theme = ThemeMethods.rawValue(extras);
                    updateServiceTheme(theme);
                    broadcastServiceUpdate();
                    break;
                case MSG.PREVIOUS:
                    BPUtil.BPLog("WallpaperServicebroadcastReceiver - MSG.PREVIOUS");
                    restartTimer();
                    naviageWallpaper(offset: -1);
                    break;
                case MSG.NEXT:
                    BPUtil.BPLog("WallpaperServicebroadcastReceiver - MSG.NEXT");
				    restartTimer();
				    naviageWallpaper(offset: 1);
				    break;
                case MSG.PREVIOUS_THEME:
                    BPUtil.BPLog("WallpaperServicebroadcastReceiver - MSG.PREVIOUS_THEME");
                    updateServiceThemeWithPrevious();
                    broadcastServiceUpdate();
                    break;
                case MSG.NEXT_THEME:
                    BPUtil.BPLog("WallpaperServicebroadcastReceiver - MSG.NEXT_THEME");
                    updateServiceThemeWithNext();
                    broadcastServiceUpdate();
                    break;
                case MSG.TOGGLE_PAUSE:
                    BPUtil.BPLog("WallpaperServicebroadcastReceiver - MSG.TOGGLE_PAUSE");
				    togglePause();
				    break;
			    default:
                    BPUtil.BPLog("WallpaperServicebroadcastReceiver -Invalid Action");
				    break;
			}
		}

		private void onStartCommand() {
			if (!_started) {
                BPUtil.BPLog("Wallpaper Info Service Started.");
				_platformWallpaper = new PlatformWallpaper();
				_imageFileManager = new ImageFileManager();
				WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
                setNewRootPath(newRootPath: wpsi.getSourceRootPath());
                WallpaperWidgetProvider.refreshWidgets();
                // adding screen change event handler
                SystemEvents.DisplaySettingsChanged += new EventHandler(screenChangeCallback);

				_started = true;
				_platformTimer = new PlatformTimer(this);
				setInterval(interval: wpsi.getInterval());
				pause_resume_service();
            } else {
                WallpaperWidgetProvider.refreshWidgets();
            }
		}
        
	    private void screenChangeCallback(object source, EventArgs  e) {
            BPUtil.BPLog("WallpaperService.screenChangeCallback");
			WallpaperWidgetProvider.refreshWidgets();
            WallpaperNotification.refreshDummyForm();
		}

		public void wallpaperSwitchCallback() {
            //BPUtil.BPLog("wallpaperSwitchCallback()");
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			if (!wpsi.getPause()) {
				naviageWallpaper(offset: 1);
			}
		}

		public void setInterval(int interval) {
			_platformTimer.setInterval(interval);
		}

        private void togglePause() {
            WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
            wpsi.setPause(!wpsi.getPause());
            pause_resume_service();
        }

		public void pause_resume_service() {
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			if (wpsi.getPause()) {
				_platformTimer.pause();
			} else {
				_platformTimer.resume();
				naviageWallpaper(1);
			}
			broadcastServiceUpdate();
		}

		public void setNewRootPath(String newRootPath) {
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			wpsi.setcurrentWPath(default(WPath));
			wpsi.setThumbnail(null);
			wpsi.setSourceRootPath(newRootPath);
			_imageFileManager.setSourceRootPath(newRootPath);
		}

		public void naviageWallpaper(int offset) {
			// wait for theme preparation is done for forward navigation
			if (!_imageFileManager.isThemeReady() && offset == 1) {
                BPUtil.BPLog("skip new image during theme preparation");
				return;
			}
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			WPath currentWPath = wpsi.getcurrentWPath();
			if (currentWPath != null) {
				WPath imagePath = _imageFileManager.retrievePathFromSource(currentWPath, offset);
				if (imagePath == null) { // there is no image in source
					_platformWallpaper.makeThumbnailFromScreenWallpaper();
					broadcastServiceUpdate();
                    BPUtil.BPLog("naviageWallpaper skipped by no image.");
					return;
				}
				// Check when previous image is filtered one while option is on
				while (offset == -1 && !wpsi.getThemeInfo().isThemeImage(imagePath.coden())) {
					WPath PreviousImagePath = _imageFileManager.retrievePathFromSource(imagePath, -1);
					// must avoid infinite loop by checking previous image stays same
					if (PreviousImagePath.path == imagePath.path) {
                        BPUtil.BPLog("naviageWallpaper skipped by no previous unfiltered image.");
						return;
					}
					imagePath = PreviousImagePath;
				}
				// change Wallpaper only if there is new image
				if (imagePath.path != wpsi.getcurrentWPath().path) {
					changeWallpaper(imagePath);
				} else {
                    BPUtil.BPLog("naviageWallpaper skipped by no previous image.");
				}
			} else {
				// Change with the first Wallpaper
				if (offset == 1) {
					changeWallpaper(null);
				} else {
                    BPUtil.BPLog("naviageWallpaper skipped by no previous image.");
				}
			}
		}

		public void setWallpaperFromLastUsedPaths(WPath imagePath) {
			restartTimer();
			changeWallpaper(imagePath);
		}

		public void restartTimer() {
			_platformTimer.resetTimer();
		}

		private void changeWallpaper(WPath currentWPath) {
			// Only true for the first image
			if (currentWPath == null || !BPUtil.fileExists(currentWPath.path)) {
				currentWPath = _imageFileManager.retrievePathFromSource(null, 1);
				if (currentWPath == null) { // there is no image in source
					_platformWallpaper.makeThumbnailFromScreenWallpaper();
					broadcastServiceUpdate();
                    BPUtil.BPLog("changeWallpaper skipped by no image.");
					return;
				}
			}
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			int count = 0, total = _imageFileManager.getTotalImageCount();
            // TODO : sometimes currentWPath is null in smchat when heavy file updates happen.
            // Need to figure out why
			while (currentWPath == null || !wpsi.getThemeInfo().isThemeImage(currentWPath.coden())) {
				currentWPath = _imageFileManager.retrievePathFromSource(currentWPath, 1);
				// must avoid infinite loop in case all files are filtered
				// reach end of source due to all filtered files
				if (count++ >= total) {
                    BPUtil.BPLog("changeWallpaper skipped by no theme image.");
					// pause service otherwise service is hanging
					wpsi.setPause(true);
					pause_resume_service();
					wpsi.getLastUsedPaths().RemoveAll();
					broadcastServiceUpdate();
					return;
				}
			}

			String pretty_path = currentWPath.label();
			if (_platformWallpaper.setWallpaper(currentWPath.path)) {
				wpsi.setcurrentWPath(currentWPath);
				BPUtil.BPLog("{WP} " + pretty_path + " [" + _imageFileManager.getImageStat(currentWPath.path) + "]");
				broadcastServiceUpdate();
			} else {
                // it seems it falls on here, when there is no monitor connected. Even then, set current path and move on.
                wpsi.setcurrentWPath(null);
                BPUtil.BPLog("{WP} " + pretty_path + " is failed. [" + _imageFileManager.getImageStat(currentWPath.path) + "]");
			}
		}

		public void updateServiceTheme(Theme theme) {
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			wpsi.setThemeInfo(ThemeInfo.getThemeInfo(theme));
			_imageFileManager.prepareSourceForTheme();
			broadcastServiceUpdate();
		}

		public void updateServiceThemeWithNext() {
			updateServiceTheme(WallpaperServiceInfo.getInstance().getThemeInfo().getNextThemeInfo()._theme);
		}

		public void updateServiceThemeWithPrevious() {
			updateServiceTheme(WallpaperServiceInfo.getInstance().getThemeInfo().getPrevousThemeInfo()._theme);
		}

		public void updateServiceCustomConfig(String customConfigString) {
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			wpsi.setCustomThemeInfo(ThemeInfo.setCustomConfig(customConfigString));
			// reassign custom theme to invoke prepareTheme() with updated custom config string
			// then prepare source again with it
			if (wpsi.getTheme() == Theme.custom) {
				wpsi.setThemeInfo(ThemeInfo.getThemeInfo(Theme.custom));
				_imageFileManager.prepareSourceForTheme();
			}
		}

        private void broadcastServiceUpdate() {
            //Console.WriteLine("WallpaperService.broadcastServiceUpdate()");
            WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
            // To Notification
            _wallpaperNotification.buildNotification(wpsi.getcurrentWPath(), wpsi.getThumbnail(), wpsi.getTheme());
            // To Widget
            WallpaperWidgetProvider.updatePauseWidget(wpsi.getPause());
            WallpaperWidgetProvider.updateThemeWidget(wpsi.getTheme().label(), null, wpsi.getPause());
            var wpath = wpsi.getcurrentWPath();
            if (wpath != null) {
                String imageWithDescription = wpath.label();
                WallpaperWidgetProvider.updateLabelWidget(imageWithDescription);
            } else {
                WallpaperWidgetProvider.updateLabelWidget("");
            }
            // To UI
            _wallpaperServiceHandler.replyToClient(thumbnail: wpsi.getThumbnail(), currentWPath: wpsi.getcurrentWPath(), pause: wpsi.getPause());
        }

		private ImageFileManager _imageFileManager = null;
		private PlatformTimer _platformTimer = null;
		private bool _started = false;
		private PlatformWallpaper _platformWallpaper = new PlatformWallpaper();
		public WallpaperServiceHandler _wallpaperServiceHandler = null;

		// service const values
		public static int _maxLastUsedPaths = 50;

		// only for Mac OS X, Windows
		public WallpaperNotification _wallpaperNotification = new WallpaperNotification();
		public bool isStarted() { return _started; }
	}
}
