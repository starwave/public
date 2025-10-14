package com.thirdwavesoft.wallpaperinfo;

import static com.thirdwavesoft.wallpaperinfo.AppUtil.*;

import android.graphics.Bitmap;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.os.RemoteException;
import android.util.Log;
import android.graphics.Bitmap.CompressFormat;
import java.io.ByteArrayOutputStream;

public class WallpaperServiceHandler {

	public WallpaperServiceHandler(WallpaperService service) {
		_service = service;
	}

	private boolean replyToClient(Messenger replyTo, int what, int intOption, Bundle bundle) {
		Message reply_msg = Message.obtain(null, what, intOption, 0, null);
		if (bundle != null && replyTo != null) {
			try {
				reply_msg.setData(bundle);
				replyTo.send(reply_msg);
				Log.d(_TAG, "Reply sent at WallpaperService : " + MSG_NAME[reply_msg.what]);
				return true;
			} catch (RemoteException e) {
				Log.e(_TAG, "WallpaperService reply failure. - " + MSG_NAME[reply_msg.what]);
				e.printStackTrace();
			}
		}
		return false;
	}

	class IncomingHandler extends Handler {
		@Override
		public void handleMessage(Message msg) {
			if (!WallpaperServiceHandler.this.handleMessage(msg)) {
				super.handleMessage(msg);
			}
		}
	}

	private boolean handleMessage(Message msg) {
		int ret;
		Log.i(_TAG, "handleMessage : " + MSG_NAME[msg.what] + "," + new Integer(msg.arg1).toString());
		Bundle bundle = msg.getData();
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		Bundle keyValues = new Bundle();
		switch (msg.what) {
			case MSG_CUSTOM_CONFIG:
				if (bundle != null && msg.what == MSG_CUSTOM_CONFIG) {
					String customConfigString = bundle.getString("custom_config_string");
					Log.i(_TAG, "handleMessage.MSG_CUSTOM_CONFIG : " + customConfigString);
					_service.restartTimer();
					_service.updateServiceCustomConfig(customConfigString);
				}
				// no break here since once filter updated, falls to the MSG_REQUEST_INFO to send updated LstUsedPaths
			case MSG_SET_THEME:
				if (msg.what == MSG_SET_THEME) {
					Theme theme = Theme.rawValue(msg.arg1);
					_service.restartTimer();
					_service.updateServiceTheme(theme);
				}
				// no break here since once filter updated, falls to the MSG_REQUEST_INFO to send updated LstUsedPaths
			case MSG_REQUEST_INFO:
				// persistent property
				keyValues.putString("root_path", wpsi.getSourceRootPath());
				keyValues.putInt("theme", wpsi.getThemeInfo()._theme.intValue());
				keyValues.putString("custom_config", wpsi.getCustomConfigString());
				keyValues.putBoolean("pause", wpsi.getPause());
				keyValues.putBoolean("saver", wpsi.getSaver());
				keyValues.putInt("interval", wpsi.getInterval());
				// runtime property
				keyValues.putSerializable("current_path", wpsi.getcurrentWPath());
				Bitmap bmpThumbnail = wpsi.getThumbnail();
				if (bmpThumbnail != null) {
					ByteArrayOutputStream bos = new ByteArrayOutputStream();
					bmpThumbnail.compress(CompressFormat.PNG, 0, bos);
					byte[] bitmapdata = bos.toByteArray();
					keyValues.putByteArray("thumbnail", bitmapdata);
				} else {
					keyValues.putByteArray("thumbnail", null);
				}
				// send only used paths in current theme
				WLinkedHashMap<String, String> lastUsedPaths = new WLinkedHashMap<String, String>();
				for (int i=0; i < wpsi.getLastUsedPaths().size(); i++) {
					WPath wpath = wpsi.getLastUsedPaths().getWPath(i);
					if (wpsi.getThemeInfo().isThemeImage(wpath.coden())) {
						lastUsedPaths.put(wpath.path, wpath.exif);
					}
				}
				keyValues.putSerializable("used_paths", new WLinkedHashMapWrapper<>(lastUsedPaths));
				// set activity is on since msg was from activity
				wpsi.setActivityonTop(true);
				keyValues.putInt("mode", wpsi.getMode().intValue());
				replyToClient(msg.replyTo, MSG_SERVICE_INFO, 0, keyValues);
				break;
			case MSG_PAUSE:
				BPUtil.BPLog("Toggle Pause Request from Activity");
				wpsi.setPause(msg.arg1 == 1);
				_service.pause_resume_service();
				break;
			case MSG_PREVIOUS:
				BPUtil.BPLog("Previous Image Request from Activity");
				_service.restartTimer();
				_service.naviageWallpaper(-1);
				break;
			case MSG_NEXT:
				BPUtil.BPLog("Next Image Request from Activity");
				_service.restartTimer();
				_service.naviageWallpaper(1);
				break;
			case MSG_SET_INTERVAL:
				if (msg.arg1 > 0) {
					BPUtil.BPLog("Set New Interval : " + msg.arg1);
					wpsi.setInterval(msg.arg1);
					_service.setInterval(wpsi.getInterval());
					_service.restartTimer();
				}
				break;
			case MSG_PREVIOUS_THEME:
				_service.updateServiceThemeWithPrevious();
				break;
			case MSG_NEXT_THEME:
				_service.updateServiceThemeWithNext();
				break;
			case MSG_SET_MODE:
				ServiceMode newMode = ServiceMode.rawValue(msg.arg1);
				if (newMode != wpsi.getMode()) {
					wpsi.setMode(newMode);
					// when mode s changed, start the first page immediately for wallpaper mode
					if (wpsi.getPause()) {
						wpsi.setPause(false);
						_service.pause_resume_service();
					} else if (newMode == ServiceMode.wallpaper) {
						_service.naviageWallpaper(0);
					}
				}
				break;
			case MSG_SET_SAVER:
				WallpaperServiceInfo.getInstance().setSaver(msg.arg1 == 1);
				break;
			case MSG_TOGGLE_PAUSE:
				wpsi.setPause(!wpsi.getPause());
				_service.pause_resume_service();
				break;
			case MSG_SET_ROOT:
				if (bundle != null) {
					String newRootPath = bundle.getString("root_path");
					_service.setNewSourceRootPath(newRootPath);
				}
				break;
			case MSG_ACTIVITY_REPORT:
				if (msg.arg1 == 0) {
					wpsi.setActivityonTop(false);
				}
				break;
			case MSG_SET_WALLPAPER:
				if (bundle != null) {
					WPath imagePath = (WPath)bundle.getSerializable("image_path");
					_service.setWallpaperFromLastUsedPaths(imagePath);
				}
				break;
			case MSG_GALLERY_COPY:
				if (bundle != null) {
					String host = (String)bundle.getSerializable("host");
					String albumName = (String)bundle.getSerializable("album_name");
					BPFileSender sender = new BPFileSender();
					_replayTo = msg.replyTo;
					sender.copyGalleryAlbum(host, albumName, new WallpaperServiceHandler.GalleryCopyCallback() {
						@Override
						public void callback(String message) {
							Bundle keyValues = new Bundle();
							keyValues.putString("message", message);

							Log.i(_TAG, "MSG_SHOW_TOAST will be sent with " + message);
							replyToClient(_replayTo, MSG_SHOW_TOAST, 0, keyValues);
						}
					});
				}
				break;
			default:
				return false;
		}
		// should be called at last to reflect pause information is updated
		_service.resetSaverTimer();
		return true;
	}

	public interface GalleryCopyCallback {
		void callback(String message);
	}

	public IBinder getBinder() {
		return _incomingMessenger.getBinder();
	}
	final Messenger _incomingMessenger = new Messenger(new IncomingHandler());

	private WallpaperService _service = null;
	Messenger _replayTo = null;
	private static final String _TAG = "WallpaperServiceHandler";

}
