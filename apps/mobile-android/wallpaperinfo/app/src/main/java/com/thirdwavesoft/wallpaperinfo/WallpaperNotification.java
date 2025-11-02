package com.thirdwavesoft.wallpaperinfo;

import android.app.Notification;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import androidx.core.app.NotificationCompat;
import android.app.NotificationManager;
import android.app.NotificationChannel;

public class WallpaperNotification {

	static NotificationChannel _channel = null;

	public static Notification buildNotification(Context context, WPath imagePath, Bitmap imageThumbnail) {
		Intent settingIntent = context.getPackageManager().getLaunchIntentForPackage("com.thirdwavesoft.wallpaperinfo");
		PendingIntent settingPendingIntent = PendingIntent.getActivity(context, 0, settingIntent, PendingIntent.FLAG_UPDATE_CURRENT);
		PendingIntent contentPendingIntent;
		String contentText, contentTitle;
		if (imageThumbnail == null) {
			imageThumbnail = BitmapFactory.decodeResource(context.getResources(), R.drawable.thirdwave);
		}
		if (imagePath == null) {
			contentPendingIntent = settingPendingIntent;
			contentTitle = "Wallpaper : " + context.getString(R.string.scanning);
			contentText = context.getString(R.string.waiting);
		} else {
			Intent contentIntent = new Intent(context, TromsoUI.class);
			contentIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
			contentPendingIntent = PendingIntent.getActivity(context, 0, contentIntent, PendingIntent.FLAG_UPDATE_CURRENT);
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			contentTitle = "Theme: " + wpsi.getTheme().label();
			contentText = imagePath.label();
		}
		// android.os.Build.VERSION_CODES.O = 26 (Oreo) => channel ID is added.
		if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
			NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
			if (_channel == null) {
				_channel = new NotificationChannel("BPWallpaper_ID",
						"BPWallpaper Channel", NotificationManager.IMPORTANCE_LOW);
				_channel.setDescription("BP Wallpaper Channel");
				_channel.setShowBadge(false);
				notificationManager.createNotificationChannel(_channel);
			}
			return new NotificationCompat.Builder(context, "BPWallpaper_ID")
					.setSmallIcon(R.drawable.thirdwave_tranparent)
					.setContentTitle(contentTitle)
					.setContentText(contentText)
					.setLargeIcon(imageThumbnail)
					.setStyle(new NotificationCompat.BigPictureStyle()
							.bigPicture(imageThumbnail)
							.bigLargeIcon(imageThumbnail))
					.setContentIntent(contentPendingIntent)
					.addAction(R.drawable.thirdwave_tranparent, "Click to open settings", settingPendingIntent)
					.build();
		} else {
			//older version prior to Oreo
			return new Notification.Builder(context)
					.setContentIntent(contentPendingIntent)
					.setContentTitle(contentTitle)
					.setTicker("Wallpaper Info Started!")
					.setContentText(contentText)
					.setWhen(System.currentTimeMillis())
					.setSmallIcon(R.drawable.thirdwave)
					.setLargeIcon(imageThumbnail)
					.addAction(R.drawable.thirdwave, "Click to open settings", settingPendingIntent)
					.build();
		}
	}

	// TODO implement openImageInOtherApp
	public void openImageInOtherApp () {
		/* open in dscloud
		Intent contentIntent = getPackageManager().getLaunchIntentForPackage("com.synology.dscloud");
		contentIntent.setData(Uri.parse("home/CloudStation/BP Wallpaper/People"));
		contentPendingIntent = PendingIntent.getActivity(this, 0, contentIntent,
				PendingIntent.FLAG_UPDATE_CURRENT);
       	 */

		/* share to dscloud
		Intent contentIntent = new Intent();
		File imageFileToShare = new File(imagePath);
		Uri uri = Uri.fromFile(imageFileToShare);
		contentIntent.setAction(Intent.ACTION_SEND);
		contentIntent.putExtra(Intent.EXTRA_STREAM, uri);
		contentIntent.setType("image/*");
		contentPendingIntent = PendingIntent.getActivity(this, 0, Intent.createChooser(contentIntent, "share..."),
				PendingIntent.FLAG_UPDATE_CURRENT);*/
	}
}
