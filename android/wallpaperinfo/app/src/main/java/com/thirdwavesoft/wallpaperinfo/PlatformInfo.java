package com.thirdwavesoft.wallpaperinfo;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Point;
import android.net.Uri;
import android.os.PowerManager;
import android.provider.MediaStore;
import android.util.DisplayMetrics;
import android.os.Build;
import android.util.Log;
import android.view.Display;
import android.view.WindowManager;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.lang.reflect.InvocationTargetException;

public class PlatformInfo {

	public static boolean isScreenOn(Context context) {
		PowerManager pm = (PowerManager)context.getSystemService(Context.POWER_SERVICE);
		return pm.isScreenOn(); // til API 19
		// return pm.isInteractive(); // from API 20
	}

	public static boolean isHomeScreenTop(Context context) {
		/*
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		if (wpsi.isActivityonTop()) {
			Log.d(_TAG, "isHomeScreenTop : WallpaperInfo app is running. (allow)");
			return true;
		} else {
			Log.d(_TAG, "isHomeScreenTop : Wallpaper is blocked. (blocked)");
			return false;
		}
		*/

//		TODO figure out how to do after Lollipop - should upgrade to API level Q
		return true;

//		private static String _previousTopPackageName = "";
//
//		ActivityManager am =(ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
//		String packageName = am.getRunningTasks(1).get(0).topActivity.getPackageName();
//		Log.d(_TAG, "isHomeScreenTop : Top activity = " + packageName);
//
//		// android.os.Build.VERSION_CODES.LOLLIPOP = 21 .
//		if(android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
//			packageName = am.getAppTasks().get(0).getTaskInfo().topActivity.getPackageName();;
//		}
//
//		String[] homePackages = {
//				// "com.thirdwavesoft.wallpaperinfo", // Wallpaperinfo Activity and all others
//				"com.sec.android.app.launcher", // Galaxy Phone
//				"com.sec.android.app.desktoplauncher", // Galaxy Dex
//				"com.android.launcher",
//				"com.nttdocomo.android.paletteui",
//				"com.lge.launcher2"
//		};
//
//		for (String homePackage : homePackages) {
//			if (packageName.equals(homePackage)) {
//				_previousTopPackageName = "";
//				Log.d(_TAG, "isHomeScreenTop : Home launcher allows. ");
//				return true;
//			}
//		}
//
//		if (!_previousTopPackageName.equals(packageName)) {
//			Log.d(_TAG, "isHomeScreenTop : Other apps blocks.");
//		}
//
//		_previousTopPackageName = packageName;
//
//		return false;

	}
	public static int getSoftButtonIconHeight(Context context) {

		// ldpi (120 dpi) 36 x 36 px
		// mdpi (160 dpi) 48 x 48 px
		// hdpi (240 dpi) 72 x 72 px
		// xhdpi (320 dpi) 96 x 96 px
		// xxhdpi (480 dpi) 144 x 144 px
		// xxxhdpi (640 dpi) 192 x 192 px

		WindowManager windowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
		DisplayMetrics metrics = new DisplayMetrics();
		windowManager.getDefaultDisplay().getMetrics(metrics);
		switch(metrics.densityDpi){
			case DisplayMetrics.DENSITY_LOW:
				return 36;
			case DisplayMetrics.DENSITY_MEDIUM:
				return 48;
			case DisplayMetrics.DENSITY_HIGH:
				return 72;
			case DisplayMetrics.DENSITY_XHIGH:
				return 96;
			case DisplayMetrics.DENSITY_XXHIGH:
				return 144;
			case DisplayMetrics.DENSITY_XXXHIGH:
				return 192;
			default:
				return 192;
		}
	}

	public static int getNavigationBarHeight(Context context) {
		WindowManager windowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
			DisplayMetrics metrics = new DisplayMetrics();
			windowManager.getDefaultDisplay().getMetrics(metrics);
			int usableHeight = metrics.heightPixels;
			windowManager.getDefaultDisplay().getRealMetrics(metrics);
			int realHeight = metrics.heightPixels;
			if (realHeight > usableHeight)
				return realHeight - usableHeight;
			else
				return 0;
		}
		return 0;
	}

	public static Point getNavigationBarSize(Context context) {
		Point appUsableSize = getAppUsableScreenSize(context);
		Point realScreenSize = getRealScreenSize(context);
		// navigation bar on the side
		if (appUsableSize.x < realScreenSize.x) {
			return new Point(realScreenSize.x - appUsableSize.x, appUsableSize.y);
		}
		// navigation bar at the bottom
		if (appUsableSize.y < realScreenSize.y) {
			return new Point(appUsableSize.x, realScreenSize.y - appUsableSize.y);
		}
		// navigation bar is not present
		return new Point();
	}

	public static Point getAppUsableScreenSize(Context context) {
		WindowManager windowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
		Display display = windowManager.getDefaultDisplay();
		Point size = new Point();
		display.getSize(size);
		return size;
	}

	public static Point getRealScreenSize(Context context) {
		WindowManager windowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
		Display display = windowManager.getDefaultDisplay();
		Point size = new Point();
		if (Build.VERSION.SDK_INT >= 17) {
			display.getRealSize(size);
		} else if (Build.VERSION.SDK_INT >= 14) {
			try {
				size.x = (Integer) Display.class.getMethod("getRawWidth").invoke(display);
				size.y = (Integer) Display.class.getMethod("getRawHeight").invoke(display);
			} catch (IllegalAccessException e) {} catch (InvocationTargetException e) {} catch (NoSuchMethodException e) {}
		}
		return size;
	}

	// append "/" at the end
	public static String getDocumentsDir() {
		String documentsPath = BPUtil.getHomeDirectory() + File.separatorChar + "Documents" + File.separatorChar;
		return documentsPath;
	}

	public static String getLogDir() {
		String logPath = getDocumentsDir() + "logs";
		if (!BPUtil.fileExists(logPath)) {
			File logDir = new File(logPath);
			if (!logDir.mkdirs()) {
				Log.e("BPUtil", "error while making log directory.");
			}
		}
		return logPath;
	}

	public static String convertStreamToString(InputStream is) {
		// http://www.java2s.com/Code/Java/File-Input-Output/ConvertInputStreamtoString.htm
		StringBuilder sb = new StringBuilder();
		try {
			BufferedReader reader = new BufferedReader(new InputStreamReader(is));
			String line = null;
			Boolean firstLine = true;
			while ((line = reader.readLine()) != null) {
				if (firstLine) {
					sb.append(line);
					firstLine = false;
				} else {
					sb.append("\n").append(line);
				}
			}
			reader.close();
		} catch (IOException e) {
			return "";
		}
		return sb.toString();
	}

	public static String getSDCardExtDirectory(Context context) {
		String sdcardExtDirectory = "";
		for (File dir:context.getExternalFilesDirs(null)) {
			String deviceDirectory = dir.getAbsolutePath();
			int index = deviceDirectory.indexOf("/Android/data/com.thirdwavesoft.wallpaperinfo/files");
			if (index >= 0) {
				String sdcardExtPathCandidate = deviceDirectory.substring(0, index);
				if (!sdcardExtPathCandidate.equals("/storage/emulated/0")) {
					BPUtil.BPLog("External SD Card path is %s", sdcardExtPathCandidate);
					sdcardExtDirectory = sdcardExtPathCandidate;
					break;
				}
			}
		}
		return sdcardExtDirectory;
	}

	public static void shareImageVia(Context context, String path) {
		String imageName = BPUtil.getOnlyFileName(path);
		Bitmap bitmap = BitmapFactory.decodeFile(path);
		String mediaPath = MediaStore.Images.Media.insertImage(context.getContentResolver(), bitmap, imageName, null);
		Intent sendIntent = new Intent(Intent.ACTION_SEND);
		sendIntent.setType("image/*");
		sendIntent.putExtra(Intent.EXTRA_STREAM, Uri.parse(mediaPath));
		context.startActivity(Intent.createChooser(sendIntent, imageName));
	}

	public static void refreshGallery(Context mContext, File file) {
		Log.d(_TAG, "refreshGallery");
		if (file == null) {
			file = new File(BPUtil.getHomeDirectory() + "/DCIM");
		}
		Intent mediaScanIntent = new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE);
		Uri contentUri = Uri.fromFile(file);
		mediaScanIntent.setData(contentUri);
		mContext.sendBroadcast(mediaScanIntent);
	}

	public static void launchGooglePhoto(Context mContext) {
		Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse("content://media/internal/images/media"));
		intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		mContext.startActivity(intent);
	}

	private static final String _TAG = "PlatformInfo";
}
