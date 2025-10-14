package com.thirdwavesoft.wallpaperinfo;

import android.app.Application;
import android.appwidget.AppWidgetManager;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Bitmap;
import android.os.Build;
import android.os.FileObserver;
import android.util.Log;
import android.widget.RemoteViews;
import android.widget.Toast;
import android.os.FileObserver;

import androidx.localbroadcastmanager.content.LocalBroadcastManager;

import java.util.ArrayList;
import java.util.List;

public class WallpaperInfoApp extends Application {

    @Override
    public void onCreate() {
        super.onCreate();
        PlatformInfo.refreshGallery(WallpaperInfoApp.this, null);
        // PlatformInfo.launchGooglePhoto(WallpaperInfoApp.this);
        WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
        // initialize wallpaperinfo app property from preference db
        wpsi.setAppContext(this);
        IntentFilter filter = new IntentFilter();
        filter.addAction("ACTION_GET_INFO_FROM_SERVICE");
        registerReceiver(_broadcastReceiver, filter);
        monitorGalleryFiles();
    }

    public void monitorGalleryFiles() {
        // SM-S928N: S24 Ultra
        // Pixel 5: Pixel 5
        String deviceModel = Build.MODEL;
        Log.d(_TAG, "Device Model: " + deviceModel);
        if (deviceModel.equals("Pixel 5")) {
            _gelleryWatcher = new ArrayList<WallpaperInfoApp.SingleFileObserver>();
            _gelleryWatcher.add(new WallpaperInfoApp.SingleFileObserver(BPUtil.getHomeDirectory() + "/DCIM", FileObserver.ALL_EVENTS));
            for (int i = 0; i < _gelleryWatcher.size(); i++) {
                _gelleryWatcher.get(i).startWatching();
            }
        }
    }

    @Override
    public void onTerminate () {
        super.onTerminate();
        Log.d(_TAG, "onTerminate()");
        unregisterReceiver(_broadcastReceiver);
        if (_gelleryWatcher == null) return;
        for (int i = 0; i < _gelleryWatcher.size(); ++i) {
            _gelleryWatcher.get(i).stopWatching();
        }
        _gelleryWatcher.clear();
        _gelleryWatcher = null;
    }

    // connections and status property
    BroadcastReceiver _broadcastReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            Log.d(_TAG, "Broadcast Received in App : " + action);
            if (action.equals("ACTION_GET_INFO_FROM_SERVICE")) {
                WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
                wpsi.setThumbnail((Bitmap)intent.getExtras().get("INTENT_EXTRA_THUMBNAIL"));
                String path = intent.getExtras().getString("INTENT_EXTRA_IMAGE_PATH");
                String exif = intent.getExtras().getString("INTENT_EXTRA_IMAGE_EXIF");
                if (path != null) {
                    wpsi.setcurrentWPath(new WPath(path, exif));
                } else {
                    wpsi.setcurrentWPath(null);
                }
                wpsi.setPause(intent.getExtras().getBoolean("INTENT_EXTRA_PAUSE"));
                wpsi.setThemeInfo(ThemeInfo.getThemeInfo(Theme.rawValue(intent.getExtras().getInt("INTENT_EXTRA_THEME"))));
                // broadcast internal_intent to activity and widget
                Intent internal_intent = new Intent("ACTION_GET_INFO_INTERNAL");
                internal_intent.putExtra("INTENT_EXTRA_THUMBNAIL", wpsi.getThumbnail());
                internal_intent.putExtra("INTENT_EXTRA_THEME", wpsi.getTheme().intValue());
                WPath wpath = wpsi.getcurrentWPath();
                if (wpath != null) {
                    internal_intent.putExtra("INTENT_EXTRA_IMAGE_PATH", wpath.path);
                    internal_intent.putExtra("INTENT_EXTRA_IMAGE_EXIF", wpath.exif);
                } else {
                    internal_intent.putExtra("INTENT_EXTRA_IMAGE_PATH", (String)null);
                    internal_intent.putExtra("INTENT_EXTRA_IMAGE_EXIF", "");
                }
                internal_intent.putExtra("INTENT_EXTRA_PAUSE", WallpaperServiceInfo.getInstance().getPause());
                LocalBroadcastManager.getInstance(wpsi.getAppContext()).sendBroadcast(internal_intent);
            }
        }
    };

    private static final String _TAG = "WallpaperInfoApp";
    private List<WallpaperInfoApp.SingleFileObserver> _gelleryWatcher = null;

    private class SingleFileObserver extends FileObserver {
        private String _path;
        public SingleFileObserver(String path, int mask) {
            super(path, mask);
            _path = path;
        }
        // TODO must handle when new sub folder is created or sub folder is deleted.
        @Override
        public void onEvent(int event, String path) {
            switch (event) {
                case FileObserver.CREATE:
                    PlatformInfo.refreshGallery(WallpaperInfoApp.this, null);
            }
        }
    }
}
