package com.thirdwavesoft.wallpaperinfo;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

public class PlatformPreference {

    synchronized static WallpaperInfoPreference getPreferences(Context context) {
        WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
        WallpaperInfoPreference wpref = new WallpaperInfoPreference();
        SharedPreferences pref = context.getSharedPreferences(wallpaperInfoPref, Context.MODE_PRIVATE); // 8
        wpref.root_path = pref.getString("root_path", null);
        wpref.theme = Theme.rawValue(Integer.valueOf(pref.getString("theme", (new Integer(Theme.default1.intValue()).toString()))));
        wpref.custom_root = pref.getString("custom_root", ThemeInfo._default_custom_root);
        wpref.custom_allow = pref.getString("custom_allow", ThemeInfo._default_custom_allow);
        wpref.custom_filter = pref.getString("custom_filter", ThemeInfo._default_custom_filter);
        wpref.pause = new Boolean(pref.getString("pause", (new Boolean(false)).toString()));
        wpref.interval = Integer.valueOf(pref.getString("interval", (new Integer(wpsi._defaultInterval).toString())));
        wpref.saverTime = Integer.valueOf(pref.getString("saver_time", (new Integer(wpsi._defaultSaverTime).toString())));
        return wpref;
    }

    synchronized static void setPreference(Context context, String key, String value) {
        if (context != null) {
            SharedPreferences pref = context.getSharedPreferences(wallpaperInfoPref, Context.MODE_PRIVATE); // 0
            SharedPreferences.Editor editor = pref.edit();
            editor.putString(key, value);
            editor.commit();
        } else {
            Log.e(_TAG, "setWallpaperInfoProperty failed due to no conext.");
        }
    }

    // default values
    private final static String _TAG = "PlatformPreference";
    private final static String wallpaperInfoPref = "prefWallpaperInfoPref";

}

class WallpaperInfoPreference {
    public String root_path;
    public Theme theme;
    public String custom_root;
    public String  custom_allow;
    public String custom_filter;
    public boolean pause;
    public int interval;
    public int saverTime;
}