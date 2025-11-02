package com.thirdwavesoft.wallpaperinfo;

import static android.content.Intent.ACTION_CONFIGURATION_CHANGED;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.res.Configuration;
import android.os.IBinder;
import android.util.Log;

import androidx.annotation.Nullable;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;

public class WallpaperService extends Service {

    @Override
    public void onCreate() {
    	Log.d(_TAG, "onCreate()");
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		wpsi.setAppContext(this);
		BPUtil.BPLog("%s", "Model : " + android.os.Build.MODEL);
        IntentFilter filter = new IntentFilter();
        filter.addAction(ACTION_CONFIGURATION_CHANGED);
        filter.addAction("ACTION_SERVICE_REQUEST_INFO");
        filter.addAction("ACTION_SERVICE_IMAGE_PAUSE_RESUME");
        filter.addAction("ACTION_SERVICE_IMAGE_NEXT");
        filter.addAction("ACTION_SERVICE_IMAGE_PREVIOUS");
        registerReceiver(_broadcastReceiver, filter);
		_wallpaperServiceHandler = new WallpaperServiceHandler(this);
    }

	@Override
	public void onDestroy() {
		_imageFileManager.stopWatching();
    	// stop timer when service is destroyed to prevent service is rerunning
		_platformTimer.pause();
		// update widget for default view
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		wpsi.setcurrentWPath(null);
		wpsi.setThumbnail(null);
		broadcastServiceUpdate();
		// unregister broadcast
		unregisterReceiver(_broadcastReceiver);
		_started = false;
		super.onDestroy();
	}

	public BroadcastReceiver _broadcastReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent myIntent) {
        	String action = myIntent.getAction();
			Log.i(_TAG, "Broadcast Received in Service : " + action);
			switch(action) {
				case ACTION_CONFIGURATION_CHANGED:
					orientationUpdate();
					break;
				case "ACTION_SERVICE_REQUEST_INFO":
					broadcastServiceUpdate();
					break;
				case "ACTION_SERVICE_IMAGE_PREVIOUS":
					BPUtil.BPLog("%s", "MSG_PREVIOUS: ACTION_SERVICE_IMAGE_PREVIOUS");
					restartTimer();
					naviageWallpaper(-1);
					break;
				case "ACTION_SERVICE_IMAGE_NEXT":
					BPUtil.BPLog("%s", "MSG_NEXT: ACTION_SERVICE_IMAGE_NEXT");
					restartTimer();
					naviageWallpaper(1);
					break;
				case "ACTION_SERVICE_IMAGE_PAUSE_RESUME":
					BPUtil.BPLog("%s", "MSG_TOGGLE_PAUSE: ACTION_SERVICE_IMAGE_PAUSE_RESUME");
					togglePause();
					break;
				default:
					return;
			}
			resetSaverTimer();
        }
    };

	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		super.onStartCommand(intent, flags, startId);
		if (!_started) {
			BPUtil.BPLog("%s", "Wallpaper Info Service Started.");
			Notification notification = WallpaperNotification.buildNotification(this, null, null);
			startForeground(_notificationId, notification);
			_platformWallpaper = new PlatformWallpaper(this);
			_imageFileManager = new ImageFileManager();
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			setNewSourceRootPath(wpsi.getSourceRootPath());
			_started = true;
			_platformTimer = new PlatformTimer(this);
			setInterval(wpsi.getInterval());
			pause_resume_service();
		} else {
			orientationUpdate();
		}
		resetSaverTimer();
		return START_STICKY;
    }

    synchronized public void resetSaverTimer() {
		Log.i(_TAG, "resetSaverTimer - reset saver timer.");
		if (_saverTimer != null) {
			_saverTimer.cancel(true);
		}
		final Runnable saverTimerFired = new Runnable() {
			public void run() {
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			Log.i(_TAG, "resetSaverTimer - suspend service after " + wpsi.getSaverTime() +" minutes of idle time.");
			_saverTimer.cancel(true);
			_saverTimer = null;
			wpsi.setPause(true);
			pause_resume_service();
			broadcastServiceUpdate();
			}
		};
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		if (wpsi.getSaver() && wpsi.getMode() != ServiceMode.wallpaper && !wpsi.getPause()) {
			_saverTimer =  _scheduler.scheduleWithFixedDelay(saverTimerFired, wpsi.getSaverTime() * 60, wpsi.getSaverTime() * 60, TimeUnit.SECONDS);
		} else {
			_saverTimer = null;
		}
	}
	
	synchronized public void wallpaperSwitchCallback() {
		if (PlatformInfo.isScreenOn(this)) {
			_changedAsOffLastTime = false;
			if (PlatformInfo.isHomeScreenTop(this)) {
				_changedAsHiddenLastTime = false;
			} else if (!_changedAsHiddenLastTime) {
				_changedAsHiddenLastTime = true;
			} else {
				return;
			}
		} else {
			_changedAsHiddenLastTime = false;
			if (_changedAsOffLastTime) {
				return;
			}
			_changedAsOffLastTime = true;
		}
		naviageWallpaper(1);
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

	synchronized public void setNewSourceRootPath(String newSourceRootPath) {
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		wpsi.setcurrentWPath(null);
		wpsi.setThumbnail(null);
		wpsi.setSourceRootPath(newSourceRootPath);
		_imageFileManager.setSourceRootPath(newSourceRootPath);
	}

	synchronized public void naviageWallpaper(int offset) {
		// wait for theme preparation is done for forward navigation
		if (!_imageFileManager.isThemeReady() && offset == 1) {
			BPUtil.BPLog("%s", "skip new image during theme preparation");
			return;
		}
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		WPath currentWPath = wpsi.getcurrentWPath();
		if (currentWPath != null) {
			WPath imagePath = _imageFileManager.retrievePathFromSource(currentWPath, offset);
			if (imagePath == null) { // there is no image in source
				_platformWallpaper.makeThumbnailFromScreenWallpaper();
				broadcastServiceUpdate();
				BPUtil.BPLog("%", "naviageWallpaper skipped by no image.");
				return;
			}
			// Check when previous image is filtered one while option is on
			while (offset == -1 && !wpsi.getThemeInfo().isThemeImage(imagePath.coden())) {
				WPath PreviousImagePath = _imageFileManager.retrievePathFromSource(imagePath, -1);
				// must avoid infinite loop by checking previous image stays same
				if (PreviousImagePath.path.equals(imagePath.path)) {
					BPUtil.BPLog("%s", "naviageWallpaper skipped by no previous unfiltered image.");
					return;
				}
				imagePath = PreviousImagePath;
			}
			// same path check removed here and move to where setting actual wallpaper due to mode introduction
			changeWallpaper(imagePath);
		} else {
			// Change with the first Wallpaper
			if (offset == 1) {
				changeWallpaper(null);
			} else {
				BPUtil.BPLog("%s", "naviageWallpaper skipped by no previous image.");
			}
		}
	}

	synchronized public void setWallpaperFromLastUsedPaths(WPath imagePath) {
		restartTimer();
		changeWallpaper(imagePath);
	}

	synchronized public void restartTimer() {
		_platformTimer.resetTimer();
	}

	synchronized private void changeWallpaper(WPath currentWPath) {
		// Only true for the first image
		if (currentWPath == null || !BPUtil.fileExists(currentWPath.path)) {
			currentWPath = _imageFileManager.retrievePathFromSource(null, 1);
			if (currentWPath == null) { // there is no image in source
				_platformWallpaper.makeThumbnailFromScreenWallpaper();
				broadcastServiceUpdate();
				BPUtil.BPLog("%s", "changeWallpaper skipped by no image.");
				return;
			}
		}
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		int count = 0, total = _imageFileManager.getTotalImageCount();
		while (!wpsi.getThemeInfo().isThemeImage(currentWPath.coden())) {
			currentWPath = _imageFileManager.retrievePathFromSource(currentWPath, 1);
			// must avoid infinite loop in case all files are filtered
			// reach end of source due to all filtered files
			if (count++ >= total) {
				BPUtil.BPLog("%s", "changeWallpaper skipped by theme image.");
				// pause service otherwise service is hanging
				wpsi.setPause(true);
				pause_resume_service();
				wpsi.getLastUsedPaths().clear();
				broadcastServiceUpdate();
				return;
			}
		}
		if (_platformWallpaper.setWallpaper(currentWPath)) {
			wpsi.setcurrentWPath(currentWPath);
			BPUtil.BPLog("%s", "{WP} " + currentWPath.label() + " [" + _imageFileManager.getImageStat(currentWPath.path) + "]");
			broadcastServiceUpdate();
		} else {
			// code sync with windows
			wpsi.setcurrentWPath(null);
			BPUtil.BPLog("%s", "{WP} " + currentWPath.label() + " is failed. [" + _imageFileManager.getImageStat(currentWPath.path) + "]");
		}
	}
	
	void updateServiceTheme(Theme theme) {
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		wpsi.setThemeInfo(ThemeInfo.getThemeInfo(theme));
		_imageFileManager.prepareSourceForTheme();
		broadcastServiceUpdate();
	}

	void updateServiceThemeWithNext() {
		updateServiceTheme(WallpaperServiceInfo.getInstance().getThemeInfo().getNextThemeInfo()._theme);
	}

	void updateServiceThemeWithPrevious() {
		updateServiceTheme(WallpaperServiceInfo.getInstance().getThemeInfo().getPrevousThemeInfo()._theme);
	}

    void updateServiceCustomConfig(String customConfigString) {
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		wpsi.setCustomThemeInfo(ThemeInfo.setCustomConfig(customConfigString));
		// reassign custom theme to invoke prepareTheme() with updated custom config string
		// then prepare source again with it
		if (wpsi.getTheme() == Theme.custom) {
			wpsi.setThemeInfo(ThemeInfo.getThemeInfo(Theme.custom));
			_imageFileManager.prepareSourceForTheme();
		}
	}

	void orientationUpdate() {
		if(getResources().getConfiguration().orientation == Configuration.ORIENTATION_LANDSCAPE) {
			BPUtil.BPLog("%s", "LANDSCAPE");
			_platformWallpaper.orientationUpdate(Configuration.ORIENTATION_LANDSCAPE);
		} else {
			BPUtil.BPLog("%s", "PORTRAIT");
			_platformWallpaper.orientationUpdate(Configuration.ORIENTATION_PORTRAIT);
		}
	}

	synchronized private void broadcastServiceUpdate() {
		Log.d(_TAG, "WallpaperService.broadcastServiceUpdate()");
		// Notification
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		Notification notification = WallpaperNotification.buildNotification(this, wpsi.getcurrentWPath(), wpsi.getThumbnail());
		NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
		notificationManager.notify(_notificationId, notification);
		// WallpaperInfoApp -> ACTION_GET_INFO_INTERNAL by LocalBroadcastManager
		Intent intent = new Intent("ACTION_GET_INFO_FROM_SERVICE");
		intent.putExtra("INTENT_EXTRA_THUMBNAIL", wpsi.getThumbnail());
		intent.putExtra("INTENT_EXTRA_THEME", wpsi.getTheme().intValue());
		WPath wpath = wpsi.getcurrentWPath();
		if (wpath != null) {
			intent.putExtra("INTENT_EXTRA_IMAGE_PATH", wpath.path);
			intent.putExtra("INTENT_EXTRA_IMAGE_EXIF", wpath.exif);
		} else {
			intent.putExtra("INTENT_EXTRA_IMAGE_PATH", (String)null);
			intent.putExtra("INTENT_EXTRA_IMAGE_EXIF", "");
		}
		intent.putExtra("INTENT_EXTRA_PAUSE", WallpaperServiceInfo.getInstance().getPause());
		sendBroadcast(intent);
		// Widget
		WallpaperWidgetProvider.updateWidget(this);
	}

	@Nullable
	@Override
	public IBinder onBind(Intent intent) {
		Log.d(_TAG, "onBind()");
		return _wallpaperServiceHandler.getBinder();
	}

	private ImageFileManager _imageFileManager = null;
	private PlatformTimer _platformTimer = null;
	private ScheduledFuture<?> _saverTimer = null;
	private boolean _started = false;
	private PlatformWallpaper _platformWallpaper;
	private WallpaperServiceHandler _wallpaperServiceHandler;


	// service const values
	public final static int _maxLastUsedPaths = 50;

	// only for Android
	private boolean _changedAsHiddenLastTime = false;
	private boolean _changedAsOffLastTime = false;
	private final int _notificationId = 13;
	private final ScheduledExecutorService _scheduler =	Executors.newScheduledThreadPool(1);
	private static final String _TAG = "WallpaperService";
}
