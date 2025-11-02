package com.thirdwavesoft.wallpaperinfo;

import android.graphics.Bitmap;
import android.content.Context;

import android.util.Log;

public class WallpaperServiceInfo {
	
    private static class SingletonHolder {
        public static final WallpaperServiceInfo instance = new WallpaperServiceInfo();
    }

    public static WallpaperServiceInfo getInstance() {
        return SingletonHolder.instance;
    }

    synchronized private void initPropertiesFromPreference() {
        _minInterval = _appContext.getResources().getInteger(R.integer.min_interval);
        _maxInterval = _appContext.getResources().getInteger(R.integer.max_interval);
        _defaultInterval = _appContext.getResources().getInteger(R.integer.default_interval);

        WallpaperInfoPreference wpref = PlatformPreference.getPreferences(_appContext);
        _sourceRootPath = wpref.root_path;
        _customThemeInfo._root = wpref.custom_root;
        _customThemeInfo._allow = wpref.custom_allow;
        _customThemeInfo._filter = wpref.custom_filter;
        // must update custom info before it updates themeinfo
        ThemeInfo.setCustomConfig(_customThemeInfo._root, _customThemeInfo._allow, _customThemeInfo._filter);
        _themeInfo = ThemeInfo.getThemeInfo(wpref.theme);
        _pause = wpref.pause;
        _interval = wpref.interval;
        _saverTime = wpref.saverTime;
        if (_interval < _minInterval || _interval > _maxInterval) {
            _interval = _defaultInterval;
        }
        if (_sourceRootPath == null || !BPUtil.fileExists(_sourceRootPath)) {
            _sourceRootPath = ImageFileManager.getDefaultSourceRootPath();
        }
    }

    // persistent property setter/getter
    synchronized public String getSourceRootPath() {
        return _sourceRootPath;
    }
    synchronized public void setSourceRootPath(String path) {
        _sourceRootPath = path;
        PlatformPreference.setPreference(_appContext, "root_path", path);
	}

    synchronized public Theme getTheme() { return _themeInfo._theme; }
    synchronized public ThemeInfo getThemeInfo() { return _themeInfo; }
    synchronized public void setThemeInfo(ThemeInfo themeInfo) {
        _themeInfo = themeInfo;
        PlatformPreference.setPreference(_appContext, "theme", (new Integer(themeInfo._theme.intValue())).toString());
    }
    synchronized public void setCustomThemeInfo(ThemeInfo customThemeInfo) {
        _customThemeInfo = customThemeInfo;
        PlatformPreference.setPreference(_appContext, "custom_root", customThemeInfo._root);
        PlatformPreference.setPreference(_appContext, "custom_allow", customThemeInfo._allow);
        PlatformPreference.setPreference(_appContext, "custom_filter", customThemeInfo._filter);
    }
    synchronized public String getCustomConfigString() {
        return _customThemeInfo._root + ";" + _customThemeInfo._allow + ";" + _customThemeInfo._filter;
    }

    synchronized public boolean getPause() {
        return _pause;
    }
    synchronized public void setPause(boolean pause) {
    	_pause = pause;
        PlatformPreference.setPreference(_appContext, "pause", (new Boolean(pause)).toString());
    }

    synchronized public int getInterval() {
	    return _interval;
	}
    synchronized public void setInterval(int interval) {
	    _interval = interval;
        PlatformPreference.setPreference(_appContext,"interval", (new Integer(interval)).toString());
	}

    // runtime property setter/getter
    synchronized public Context getAppContext() {
        return _appContext;
    }
    synchronized public void setAppContext(Context context) {

        if (_appContext == null) {
            _appContext = context.getApplicationContext();
            if (_appContext != null) {
                initPropertiesFromPreference();
                BPUtil.BPLog("%s (%s)", "WallpaperServiceInfo Preference ", _appContext.getApplicationInfo().toString());
            } else {
                Log.e(_TAG, "WallpaperServiceInfo reading preference failed due to no conext.");
            }
        } else if (_appContext != context.getApplicationContext()) {
            Log.e(_TAG, "WallpaperServiceInfo context is changed.");
        }
    }

    synchronized public WPath getcurrentWPath() {
        return _currentWPath;
    }
    synchronized public void setcurrentWPath(WPath path) {
        _currentWPath = path;
    }

    synchronized public Bitmap getThumbnail() {
        return _thumbnail;
    }
    synchronized public void setThumbnail(Bitmap thumbnail) {
        if (thumbnail == null && _thumbnail != null) {
            _thumbnail.recycle();
        }
        _thumbnail = thumbnail;
    }

    synchronized public WLinkedHashMap<String, String> getLastUsedPaths() {
        return _lastUsedPaths;
    }
    synchronized public void setLastUsedPaths(WLinkedHashMap<String, String> lastUsedPaths) {
        _lastUsedPaths = lastUsedPaths;
    }

    synchronized public ServiceMode getMode() {
        return _mode;
    }
    synchronized public void setMode(ServiceMode mode) {
        _mode = mode;
    }

    synchronized public boolean getSaver() {
        return _saver;
    }
    synchronized public void setSaver(boolean saver) {
        _saver = saver;
    }

    synchronized public int getSaverTime() {
        return _saverTime;
    }
    synchronized public void setSaverTime(int saverTime) {
        _saverTime = saverTime;
        //PlatformPreference.setPreference(_appContext,"saver_time", (new Integer(_saverTime)).toString());
    }


    synchronized public boolean isActivityonTop() {
        return _activityonTop;
    }
    synchronized public void setActivityonTop(boolean activityonTop) {
        _activityonTop = activityonTop;
    }

    // persistent property
    private String _sourceRootPath = ImageFileManager.getDefaultSourceRootPath();
    private ThemeInfo _themeInfo = ThemeInfo.getThemeInfo(Theme.default1);
    private ThemeInfo _customThemeInfo = new ThemeInfo(Theme.custom,
            ThemeInfo._default_custom_root,
            ThemeInfo._default_custom_allow,
            ThemeInfo._default_custom_filter);
	private boolean _pause = false;
    private int _interval = _defaultInterval; // in seconds

    // runtime property
    private WPath _currentWPath = null;
    private Bitmap _thumbnail = null;
    private WLinkedHashMap<String, String> _lastUsedPaths = new WLinkedHashMap<String, String>();
    private ServiceMode _mode = ServiceMode.wallpaper;
    private boolean _saver = false;
    private int _saverTime = _defaultSaverTime;

    // Platform Specifc runtime property
    private Context _appContext = null;
    private boolean _activityonTop = false;

    //public value from resource
    public static int _defaultInterval = 15; // 15 will not be used. just placeholder.
    public static int _defaultSaverTime = 5; // 5 will not be used. just placeholder.
    public static int _minInterval = 5; // 5 will not be used. just placeholder.
    public static int _maxInterval = 30; // 30 will not be used. just placeholder.

    // default values
    private final static String _TAG = "WallpaperServiceInfo";

}

enum ServiceMode {
    wallpaper, slideshow, cast;
    static ServiceMode rawValue(int index) {
        if (index >=0 && index < _serviceModeValues.length) {
            return _serviceModeValues[index];
        }
        return wallpaper;
    }
    private static ServiceMode[] _serviceModeValues = values();
    int intValue() {
        return ordinal();
    }
};

