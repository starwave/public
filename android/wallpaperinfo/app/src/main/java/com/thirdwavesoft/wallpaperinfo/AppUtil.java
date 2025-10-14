package com.thirdwavesoft.wallpaperinfo;

import android.app.ActivityManager;
import android.content.Context;
import android.content.Intent;

import java.util.ArrayList;
import java.util.Arrays;

public class AppUtil {

	public static final int MSG_REQUEST_INFO = 1;
	public static final int MSG_PAUSE = 2;
	public static final int MSG_PREVIOUS = 3;
	public static final int MSG_NEXT = 4;
	public static final int MSG_SET_ROOT = 5;
	public static final int MSG_ACTIVITY_REPORT = 6;
	public static final int MSG_SET_WALLPAPER = 7;
	public static final int MSG_SET_INTERVAL = 8;
	public static final int MSG_SERVICE_INFO = 9;
	public static final int MSG_SET_THEME = 10;
	public static final int MSG_CUSTOM_CONFIG = 11;
	public static final int MSG_PREVIOUS_THEME = 12;
	public static final int MSG_NEXT_THEME = 13;
	public static final int MSG_TOGGLE_PAUSE = 14;
	public static final int MSG_SET_MODE = 15;
	public static final int MSG_SET_SAVER = 16;
	public static final int MSG_SET_SAVERTIME = 17;
	public static final int MSG_OPEN_SETTING_UI = 18;
	public static final int MSG_SHOW_TOAST = 19;
	public static final int MSG_GALLERY_COPY = 20;
	public static final int MSG_SET_OFFLINE_MODE = 21;

	public static final String[] MSG_NAME = {
			"MSG_UNKNOWN",
			"MSG_REQUEST_INFO",
			"MSG_PAUSE",
			"MSG_PREVIOUS",
    		"MSG_NEXT",
			"MSG_SET_ROOT",
			"MSG_ACTIVITY_REPORT",
			"MSG_SET_WALLPAPER",
			"MSG_SET_INTERVAL",
			"MSG_SERVICE_INFO",
			"MSG_SET_THEME",
			"CUSTOM_CONFIG",
			"PREVIOUS_THEME",
			"NEXT_THEME",
			"TOGGLE_PAUSE",
			"SET_MODE",
			"SET_SAVER",
			"SET_SAVERTIME",
			"OPEN_SETTING_UI",
			"SHOW_TOAST",
			"MSG_GALLERY_COPY"
    };

	public static ArrayList<String> getWordsArray(String wordString) {
		// check if empty string to avoid split function to create one empty entry in array
		if (wordString.equals("")) {
			return new ArrayList<String>();
		} else {
			return new ArrayList<String> (Arrays.asList(wordString.split("\\|")));
		}
	}

	public static Intent getWallpaperServiceIntent() {
		Intent intent = new Intent();
		intent.setClassName("com.thirdwavesoft.wallpaperinfo", "com.thirdwavesoft.wallpaperinfo.WallpaperService");
		return intent;
	}

	public static boolean isMyServiceRunning() {
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		Context context = wpsi.getAppContext();

		ActivityManager manager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
		for (ActivityManager.RunningServiceInfo service : manager.getRunningServices(Integer.MAX_VALUE)) {
			if (WallpaperService.class.getName().equals(service.service.getClassName())) {
				return true;
			}
		}
		return false;
	}

	private static final int _maxImageDescriptionLength = 50;

};