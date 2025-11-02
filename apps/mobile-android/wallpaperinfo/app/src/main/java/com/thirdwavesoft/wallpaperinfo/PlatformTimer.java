package com.thirdwavesoft.wallpaperinfo;

import android.util.Log;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;


public class PlatformTimer {
	
	public PlatformTimer(WallpaperService service) {
		_wallpaperService = service;
	}

    synchronized private void scheduleSwitchWallpaper(int seconds) {
   		if (_switchHandler != null) {
   			cancelSwitchWallpaper();
   		}
   		final Runnable wallpaperSwitcher = new Runnable() {
   			public void run() {
			// Log.d(_TAG, "wallpaperSwitcher()");
			synchronized(this) {
				try {
					if (!_pause) {
						_wallpaperService.wallpaperSwitchCallback();
					}
				} catch (Exception e) {
					e.printStackTrace();
					Log.e(_TAG, e.getMessage());
				}
			}
   			}
   		};
   		_pause = false;
   		_switchHandler = _scheduler.scheduleWithFixedDelay(wallpaperSwitcher, seconds, seconds, TimeUnit.SECONDS);
   	}
   	
    synchronized public void cancelSwitchWallpaper() {
    	if (_switchHandler != null) {
	   		_switchHandler.cancel(true);
	   		_switchHandler = null;
    	}
   		_pause = true;
   	}
    
   	synchronized public void resetTimer() {
   		if (!_pause) {
   			resume();
   		}
   	}
   	
   	synchronized public void pause() {
		cancelSwitchWallpaper();
   	}
   	
   	synchronized public void resume() {
   		scheduleSwitchWallpaper(_interval);
   	}
   	
   	synchronized public void setInterval(int interval) {
   		_interval = interval;
   		if (!_pause) {
   			resume();
   		}
   	}
   	
   	private WallpaperService _wallpaperService;
	private ScheduledFuture<?> _switchHandler = null;
	private int _interval = 5;
	private boolean _pause = false;
	private final ScheduledExecutorService _scheduler =	Executors.newScheduledThreadPool(1);

	private static final String _TAG = "PlatformTimer";

}
