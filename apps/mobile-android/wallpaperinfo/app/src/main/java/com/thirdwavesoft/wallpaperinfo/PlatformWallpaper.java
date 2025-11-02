package com.thirdwavesoft.wallpaperinfo;

import java.io.IOException;

import android.app.WallpaperManager;
import android.content.Context;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.Bitmap.Config;
import android.graphics.Paint;
import android.graphics.Point;
import android.graphics.Rect;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.BitmapDrawable;
import android.view.Display;
import android.view.WindowManager;
import android.media.ExifInterface;
import android.util.Log;

// TODO Screen Cast implementation
public class PlatformWallpaper {
	
	public PlatformWallpaper(Context context) {
		_context = context;
		_orientation = _context.getResources().getConfiguration().orientation;
		_wallpaperManager = WallpaperManager.getInstance(_context.getApplicationContext());
		// get device width and height
		WindowManager wm = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
		Display display = wm.getDefaultDisplay();
		Point size = new Point();
		display.getSize(size);
		_deviceWidth = Math.min(size.y, size.x);
		_deviceHeight = Math.max(size.y, size.x);
		// "navigation_bar_height" is for old way to get navigation bar height but following function is better solution
		_navigationBarHeight = PlatformInfo.getNavigationBarHeight(context);
		_softButtonIconHeight = PlatformInfo.getSoftButtonIconHeight(context);
		// _statusBarHeight is not used for now
		//int resourceId = _context.getResources().getIdentifier("status_bar_height", "dimen", "android");
		//if (resourceId > 0) {
		//	_statusBarHeight = _context.getResources().getDimensionPixelSize(resourceId);
		//}

		if (_orientation == Configuration.ORIENTATION_PORTRAIT) {
			_deviceHeight += _navigationBarHeight;
		} else {
			_deviceWidth += _navigationBarHeight;
		}
	}
	
	synchronized public boolean setWallpaper(WPath wpath) {
		if (!BPUtil.fileExists(wpath.path)) {
			Log.e(_TAG, "Wallpaper " + wpath.path + " doesn't exist.");
			return false;
		}
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		if (wpsi.getMode() == ServiceMode.slideshow) {
			wpsi.setThumbnail(null); // check if it's needed
			return true; // must return true to update current WPath
		} else if (wpsi.getMode() == ServiceMode.cast) {
			// TODO implement
			return true;
		}
		// ServiceMode.wallpaper
		return (applyWallpaperFromFile(wpath));
	}
	
	public void orientationUpdate(int orientation) {
		if (_orientation != orientation) {
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			WPath currentWPath = wpsi.getcurrentWPath();
			if (currentWPath != null) {
				_orientation = orientation;
				setWallpaper(currentWPath);
			}			
		}
	}

	public void makeThumbnailFromScreenWallpaper() {
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		Drawable wallpaperDrawable = _wallpaperManager.getDrawable();
		if (wallpaperDrawable instanceof BitmapDrawable) {
			Bitmap wallpaperBitmap = ((BitmapDrawable) wallpaperDrawable).getBitmap();
			if(wallpaperBitmap != null) {
				wpsi.setThumbnail(makeThumbnail(wallpaperBitmap));
				wpsi.setcurrentWPath(null);
				wallpaperBitmap.recycle();
			}
		}
	}

	private boolean applyWallpaperFromFile(WPath wpath) {
		if (_previousWPath != null && _previousWPath.path.equals(wpath.path)) {
			BPUtil.BPLog("%s", "applyWallpaperFromFile skipped due to same path image.");
		}
		_previousWPath = wpath;
		Matrix matrix = null;
		try {
			ExifInterface exifInterface = new ExifInterface(wpath.path);
			int orientation = Integer.parseInt(exifInterface.getAttribute(ExifInterface.TAG_ORIENTATION));
			switch (orientation) {
				case ExifInterface.ORIENTATION_UNDEFINED:	// 0
				case ExifInterface.ORIENTATION_NORMAL:		// 1
					break;
				case ExifInterface.ORIENTATION_ROTATE_180:	// 3
					matrix = new Matrix();
					matrix.setRotate(180);
					Log.d(_TAG,  "EXIF Image Orientation = 180");
					break;
				case ExifInterface.ORIENTATION_ROTATE_90:	// 6
					matrix = new Matrix();
					matrix.setRotate(90);
					Log.d(_TAG,  "EXIF Image Orientation = 90");
					break;
				case ExifInterface.ORIENTATION_ROTATE_270:	// 8
					matrix = new Matrix();
					matrix.setRotate(-90);
					Log.d(_TAG,  "EXIF Image Orientation = 270");
					break;
				/*
				case ExifInterface.ORIENTATION_TRANSPOSE:
					matrix.setRotate(90);
					matrix.postScale(-1, 1);
					break;
				case ExifInterface.ORIENTATION_FLIP_HORIZONTAL:
					matrix.setScale(-1, 1);
					break;
				case ExifInterface.ORIENTATION_FLIP_VERTICAL:
					matrix.setRotate(180);
					matrix.postScale(-1, 1);
					break;
				case ExifInterface.ORIENTATION_TRANSVERSE:
					matrix.setRotate(-90);
					matrix.postScale(-1, 1);
					break;
				 */
				default:
					break;
			}

		} catch (IOException e) {
			e.printStackTrace();
		}
		// collect minimum size the first
		int desiredWidth = _wallpaperManager.getDesiredMinimumWidth();
		int desiredHeight = _wallpaperManager.getDesiredMinimumHeight();
		// in case, device is bigger than desired size
		if (desiredWidth < _deviceWidth) desiredWidth = _deviceWidth;
		if (desiredHeight < _deviceHeight) desiredHeight = _deviceHeight;
		Bitmap overlay = Bitmap.createBitmap(desiredWidth, desiredHeight, Config.ARGB_8888);
	    Bitmap wallpaperImage;
	    // rotate image if needed by exif information
	    if (matrix != null) {
			Bitmap tempBMP = BitmapFactory.decodeFile(wpath.path);
			wallpaperImage = Bitmap.createBitmap(tempBMP, 0, 0, tempBMP.getWidth(), tempBMP.getHeight(), matrix, true);
			tempBMP.recycle();
		} else {
			wallpaperImage = BitmapFactory.decodeFile(wpath.path);
		}
		Log.d(_TAG, "wallpaper :" + Integer.toString(wallpaperImage.getWidth()) + "," + Integer.toString(wallpaperImage.getHeight()));
		try {
        	overlay = overlayIntoCentre(overlay, wallpaperImage);
			String wallpaperText= wpath.label();
			overlay = drawTextOnBitmap(overlay, wallpaperText, true);
			Bitmap thumbnailBMP = makeThumbnail(wallpaperImage);
			wallpaperImage.recycle();
			if (thumbnailBMP != null) {
				WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
				wpsi.setThumbnail(thumbnailBMP);
			}
			_wallpaperManager.setBitmap(overlay);
			overlay.recycle();
	    } catch (IOException e) {
	        e.printStackTrace();
	        return false;
	    }
	    return true;
	}

	private boolean isPointDark(Bitmap bitmap, int x, int y) {
		int testScore = 0;
		for (int xx = x-1; xx <= x+1; xx++) {
			for (int yy = y-1; yy <= y+1; yy++) {
				int pixel = bitmap.getPixel(x,y);
				int redValue = Color.red(pixel);
				int blueValue = Color.blue(pixel);
				int greenValue = Color.green(pixel);
				if ((redValue + blueValue + greenValue)/3 < 210 )
					testScore++;
				else
					testScore--;
			}
		}
		return (testScore > 0);
	}

	private Bitmap overlayIntoCentre(Bitmap bmp1, Bitmap bmp2) {
		Canvas canvas = new Canvas(bmp1);
		canvas.drawColor(Color.BLACK);
		canvas.drawBitmap(bmp1, new Matrix(), null);
		// scale bitmap to fit within device height size of view instead of entire desired height
		float scaleHeight;
		if (_orientation == Configuration.ORIENTATION_PORTRAIT) {
			scaleHeight = ((float) _deviceHeight) / bmp2.getHeight();
		} else {
			scaleHeight = ((float) _deviceWidth) / bmp2.getHeight();
		}
		// Log.i(_TAG, "scale, bmheight :" + new Float(scaleHeight).toString() + "," + new Integer(bmp2.getHeight()).toString());
	    Matrix matrix = new Matrix();
	    matrix.postScale(scaleHeight, scaleHeight);
	    Bitmap resized = Bitmap.createBitmap(bmp2, 0, 0, bmp2.getWidth(), bmp2.getHeight(), matrix, false);
	    canvas.drawBitmap(resized,
				(bmp1.getWidth() - resized.getWidth()) / 2,
				(bmp1.getHeight() - resized.getHeight()) / 2,
				null);
	    resized.recycle();
	    return bmp1;
	}
	
	private Bitmap makeThumbnail(Bitmap source) {
		if (source.isRecycled()) return null;  // crash without it
		final Resources res = _context.getResources();
		float widgetHeight = (float)res.getDimensionPixelSize(R.dimen.widget_image_height);
		float notificationWidth =  (float)res.getDimensionPixelSize(android.R.dimen.notification_large_icon_width);
		float notificationHeight =  (float)res.getDimensionPixelSize(android.R.dimen.notification_large_icon_height);
		float finalWidth = Math.max(widgetHeight, notificationWidth);
		float finalHeight = Math.max(widgetHeight, notificationHeight);
	    float scaleWidth = finalWidth/source.getWidth();
	    float scaleHeight = finalHeight/source.getHeight();
	    float scale = Math.min(scaleHeight, scaleWidth);
	    Matrix matrix = new Matrix();
	    matrix.postScale(scale, scale);
		Bitmap thumbnailBMP = Bitmap.createBitmap(source, 0, 0, source.getWidth(), source.getHeight(), matrix, false);;
		return thumbnailBMP;
	}

	private Bitmap drawTextOnBitmap(Bitmap bitmap, String text, boolean isCenter) {
		Canvas canvas = new Canvas(bitmap);
		Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
		float scaledSizeInPixels = _context.getResources().getDisplayMetrics().scaledDensity * 12;
		paint.setTextSize(scaledSizeInPixels);
		Rect bounds = new Rect();
		paint.getTextBounds(text, 0, text.length(), bounds);
		int x, y;
		// _navigationBarHeight, _softButtonIconHeight per android devices
		// S10 : 307, 192
		// Note9 : 126, 192
		// Tab A : 72, 72
		// FireHD10 : 72, 72
		// Tab S3 : 0, 96
		// S9 : 168, 192
		int vertical_offset = Math.min(_softButtonIconHeight, _navigationBarHeight);
		if (_orientation == Configuration.ORIENTATION_PORTRAIT) {
			x = (isCenter) ? (bitmap.getWidth() - bounds.width()) / 2 : 30;
			y = (bitmap.getHeight()/2 + _deviceHeight/2 - vertical_offset) - 4;
		} else {
			x = (isCenter) ? (bitmap.getWidth() - bounds.width()) / 2 : 30;
			y = (bitmap.getHeight()/2 + _deviceWidth/2 - vertical_offset) - 4;
		}
		// y should be less than bitmap height
		if (isPointDark(bitmap, x + bounds.width()/2, y)) {
			paint.setColor(Color.WHITE);
			paint.setShadowLayer(6f, 3f, 3f, Color.BLACK);
		} else {
			paint.setColor(Color.BLACK);
			paint.setShadowLayer(6f, 3f, 3f, Color.WHITE);
		}
		canvas.drawText(text, x, y, paint);
		return bitmap;
	}

	private final Context _context;
	private final int _navigationBarHeight, _softButtonIconHeight;
	private final WallpaperManager _wallpaperManager;
	private WPath _previousWPath = null;
	private int _deviceWidth, _deviceHeight;
	private int _orientation; // default in configuration = Configuration.ORIENTATION_PORTRAIT;
    private final static String _TAG = "PlatformWallpaper";
}
