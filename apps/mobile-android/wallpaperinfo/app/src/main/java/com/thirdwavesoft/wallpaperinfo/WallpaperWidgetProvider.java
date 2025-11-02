package com.thirdwavesoft.wallpaperinfo;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.util.Log;
import android.widget.RemoteViews;

public class WallpaperWidgetProvider extends AppWidgetProvider {
	
	@Override
	public void onUpdate(Context context, AppWidgetManager appWidgetManager,int[] appWidgetIds) {
		Log.d(_TAG, "onUpdate : " + this);
		setPendingIntent(context);
		requestGetInfoFromService(context);
		super.onUpdate(context, appWidgetManager, appWidgetIds); // comment as it doesn't anything for now
	}

	@Override
	public void onReceive(Context context, Intent intent) {
		super.onReceive(context, intent);
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		String action = intent.getAction();
		Log.d(_TAG, "Broadcast Received in Widget : " + action);
		// You must update pending intent every time when you made visual widget update
		// Otherwise it won't work after device rotation
		if (action.equals("ACTION_GET_INFO_INTERNAL")) {
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
        } else if (action.equals("ACTION_WIDGET_OPEN_IMAGE")) {
        	WPath currentWPath = wpsi.getcurrentWPath();
        	if (currentWPath != null) {
				Intent tromsoIntent = new Intent(context, TromsoUI.class);
				tromsoIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
				context.startActivity(tromsoIntent);
        	}
        } else if (action.equals("ACTION_WIDGET_APP_SETTING")) {
			Intent wallpaperInfoIntent = new Intent(context, WallpaperInfoUI.class);
			wallpaperInfoIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
			// ensure only one activity is running
			wallpaperInfoIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
			context.startActivity(wallpaperInfoIntent);
		} else if (action.equals("ACTION_WIDGET_PAUSE_RESUME")) {
			if (AppUtil.isMyServiceRunning()) {
				wpsi.setPause(!wpsi.getPause());
				Intent serviceIntent = new Intent("com.thirdwavesoft.wallpaperinfo.WallpaperService");
				serviceIntent.setAction("ACTION_SERVICE_IMAGE_PAUSE_RESUME");
				context.sendBroadcast(serviceIntent);
			} else { // start service if service is not running
				context.startService(new Intent(context, WallpaperService.class));
			}
        }
    	setPendingIntent(context);
	}
	
	synchronized private void setPendingIntent(Context context) {
		WallpaperWidgetProvider.updateWidget(context);
	}
	
	synchronized private void requestGetInfoFromService(Context context) {
		Intent serviceIntent = new Intent("com.thirdwavesoft.wallpaperinfo.WallpaperService");
		serviceIntent.setAction("ACTION_SERVICE_REQUEST_INFO");
    	context.sendBroadcast(serviceIntent);
	}

	 public static void updateWidget(Context context) {
		RemoteViews remoteViews = new RemoteViews(context.getPackageName(), R.layout.wallpaperinfo_widget_layout_4_1);
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		WPath currentWPath = wpsi.getcurrentWPath();
		if (currentWPath != null) {
			remoteViews.setTextViewText(R.id.folder_text, wpsi.getTheme().label());
			remoteViews.setTextViewText(R.id.image_text, currentWPath.label());
		} else {
			remoteViews.setTextViewText(R.id.folder_text, context.getString(R.string.scanning));
			remoteViews.setTextViewText(R.id.image_text, context.getString(R.string.waiting));
		}
		Bitmap thumbnail = wpsi.getThumbnail();
		if (thumbnail != null) {
			remoteViews.setImageViewBitmap(R.id.image_thumbnail, thumbnail);
		} else {
			remoteViews.setImageViewResource(R.id.image_thumbnail, R.drawable.thirdwave);
		}
		setPauseButton(remoteViews, wpsi.getPause());
		// Open Image View Click
		Intent intent1 = new Intent(context, WallpaperWidgetProvider.class);
		intent1.setAction("ACTION_WIDGET_OPEN_IMAGE");
		PendingIntent actionPendingIntent1 = PendingIntent.getBroadcast(context, 0, intent1, PendingIntent.FLAG_UPDATE_CURRENT);
		remoteViews.setOnClickPendingIntent(R.id.image_thumbnail, actionPendingIntent1);
		// App Setting / App Button
		Intent intent2 = new Intent(context, WallpaperWidgetProvider.class);
		intent2.setAction("ACTION_WIDGET_APP_SETTING");
		PendingIntent actionPendingIntent2 = PendingIntent.getBroadcast(context, 0, intent2, PendingIntent.FLAG_UPDATE_CURRENT);
		remoteViews.setOnClickPendingIntent(R.id.setting_button, actionPendingIntent2);
		// Pause / Resume Button
		Intent intent3 = new Intent(context, WallpaperWidgetProvider.class);
		intent3.setAction("ACTION_WIDGET_PAUSE_RESUME");
		PendingIntent actionPendingIntent3 = PendingIntent.getBroadcast(context, 0, intent3, PendingIntent.FLAG_UPDATE_CURRENT);
		remoteViews.setOnClickPendingIntent(R.id.pause_button, actionPendingIntent3);
		// Next Button
		Intent intent4 = new Intent("com.thirdwavesoft.wallpaperinfo.WallpaperService");
		intent4.setAction("ACTION_SERVICE_IMAGE_NEXT");
		PendingIntent actionPendingIntent4 = PendingIntent.getBroadcast(context, 0, intent4, PendingIntent.FLAG_UPDATE_CURRENT);
		remoteViews.setOnClickPendingIntent(R.id.forward_button, actionPendingIntent4);
		// Back Button
		Intent intent5 = new Intent("com.thirdwavesoft.wallpaperinfo.WallpaperService");
		intent5.setAction("ACTION_SERVICE_IMAGE_PREVIOUS");
		PendingIntent actionPendingIntent5 = PendingIntent.getBroadcast(context, 0, intent5, PendingIntent.FLAG_UPDATE_CURRENT);
		remoteViews.setOnClickPendingIntent(R.id.back_button, actionPendingIntent5);
		// update app widget
		ComponentName thisWidget = new ComponentName(context, WallpaperWidgetProvider.class);
		AppWidgetManager manager = AppWidgetManager.getInstance(context);
		manager.updateAppWidget(thisWidget, remoteViews);
		// improve thumbnail image refresh
		manager.notifyAppWidgetViewDataChanged(R.layout.wallpaperinfo_widget_layout_4_1, R.id.image_thumbnail);
	}

	private static void setPauseButton(RemoteViews remoteViews, boolean pause) {
		if (pause || !AppUtil.isMyServiceRunning()) {
			remoteViews.setInt(R.id.pause_button, "setImageResource", R.drawable.gtk_media_play_ltr);
		} else {
			remoteViews.setInt(R.id.pause_button, "setImageResource", R.drawable.gtk_media_pause);
		}
	}

	private final static String _TAG = "WallpaperWidgetProvider";
}
