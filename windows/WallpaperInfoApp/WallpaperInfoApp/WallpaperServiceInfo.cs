using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WallpaperInfoApp {

	class WallpaperServiceInfo {

		private WallpaperServiceInfo() {
			var wpref = PlatformPreference.getPreferences(this);
            _sourceRootPath = wpref.root_path;
            _customThemeInfo._root = wpref.custom_root;
            _customThemeInfo._allow = wpref.custom_allow;
            _customThemeInfo._filter = wpref.custom_filter;
            // must update custom info before it updates themeinfo
            ThemeInfo.setCustomConfig(_customThemeInfo._root, _customThemeInfo._allow, _customThemeInfo._filter);
            _themeInfo = ThemeInfo.getThemeInfo(wpref.theme); 
            _pause = wpref.pause;
            _interval = wpref.interval;
			if (_interval < _minInterval || _interval > _maxInterval) {
				_interval = _defaultInterval;
			}
			if (_sourceRootPath == null || !BPUtil.fileExists(_sourceRootPath)) {
				_sourceRootPath = ImageFileManager.getDefaultSourceRootPath();
			}
		}

		private static WallpaperServiceInfo _sharedWallpaperServiceInfo;
		public static WallpaperServiceInfo getInstance() {
			if (_sharedWallpaperServiceInfo == null) {
				_sharedWallpaperServiceInfo = new WallpaperServiceInfo();
            }
			return _sharedWallpaperServiceInfo;
        }

		// persistent property setter/getter
		 public String getSourceRootPath() {
			return _sourceRootPath;
		}
		public void setSourceRootPath(String path) {
			_sourceRootPath = path;
			PlatformPreference.setPreference("root_path", path);
		}
		public Theme getTheme() { return _themeInfo._theme; }
		public ThemeInfo getThemeInfo() { return _themeInfo; }
		public void setThemeInfo(ThemeInfo themeInfo) {
			_themeInfo = themeInfo;
			PlatformPreference.setPreference("theme", themeInfo._theme.intValue().ToString());
		}
		public void setCustomThemeInfo(ThemeInfo customThemeInfo) {
			_customThemeInfo = customThemeInfo;
			PlatformPreference.setPreference("custom_root", customThemeInfo._root);
			PlatformPreference.setPreference("custom_allow", customThemeInfo._allow);
			PlatformPreference.setPreference("custom_filter", customThemeInfo._filter);
		}
		public String getCustomConfigString() {
			return _customThemeInfo._root + ";" + _customThemeInfo._allow + ";" + _customThemeInfo._filter;
		}
		public bool getPause() {
			return _pause;
		}
		public void setPause(bool pause) {
    		_pause = pause;
			PlatformPreference.setPreference("pause", pause.ToString());
		}
		public int getInterval() {
			return _interval;
		}
		public void setInterval(int interval) {
			_interval = interval;
			PlatformPreference.setPreference("interval", interval.ToString());
		}

		// runtime property setter/getter
		public WPath getcurrentWPath() {
			return _currentWPath;
		}
		public void setcurrentWPath(WPath wpath) {
			_currentWPath = wpath;
		}

		public Bitmap getThumbnail() {
			return _thumbnail;
		}
		public void setThumbnail(Bitmap thumbnail) {
		if (thumbnail == null && _thumbnail != null) {
			_thumbnail.Dispose();
		}
			_thumbnail = thumbnail;
		}

		public WLinkedHashMap<String, String> getLastUsedPaths() {
			return _lastUsedPaths;
		}
		public void setLastUsedPaths(WLinkedHashMap<String, String> lastUsedPaths) {
			_lastUsedPaths = lastUsedPaths;
		}

		public WallpaperService getWallpaperService() { return _wallpaperService; }

		// persistent property
		private String _sourceRootPath; // ImageFileManager.getDefaultRootPath()
		private ThemeInfo _themeInfo = ThemeInfo.getThemeInfo(Theme.default1);
		private ThemeInfo _customThemeInfo = new ThemeInfo(Theme.custom,
				ThemeInfo._default_custom_root,
				ThemeInfo._default_custom_allow,
				ThemeInfo._default_custom_filter);
		private bool _pause; // false
		private int _interval; // _defaultInterval // in seconds

		// runtime property
		private WPath _currentWPath = null;
		private Bitmap _thumbnail = null;
		private WLinkedHashMap<String, String> _lastUsedPaths = new WLinkedHashMap<String, String>();

		// Platform Specifc runtime property
		private WallpaperService _wallpaperService = new WallpaperService();

		//public value from resource
		public static int _defaultInterval = 5; // 15 will not be used. just placeholder.
		public static int _minInterval = 5; // 5 will not be used. just placeholder.
		public static int _maxInterval = 30; // 30 will not be used. just placeholder.
	}
}
