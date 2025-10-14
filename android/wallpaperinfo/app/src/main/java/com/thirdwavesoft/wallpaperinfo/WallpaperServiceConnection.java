package com.thirdwavesoft.wallpaperinfo;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.os.RemoteException;
import android.util.Log;
import android.graphics.BitmapFactory;
import android.widget.Toast;

import java.util.HashMap;

import static com.thirdwavesoft.wallpaperinfo.AppUtil.*;

/**
 * Created by starwave on 9/30/15.
 */
public class WallpaperServiceConnection {

    public WallpaperServiceConnection(Context context, WallpaperInfoDelegate delegate) {
        Log.d(_TAG, "WallpaperServiceConnection()");
        _context = context;
        _delegate = delegate;
    }

    private ServiceConnection _connection = new ServiceConnection() {
        public void onServiceConnected(ComponentName className, IBinder service) {
            Log.d(_TAG, "onServiceConnected()");
            _service = new Messenger(service);
            _bound = true;
            WallpaperServiceConnection.this.signal();
        }

        public void onServiceDisconnected(ComponentName className) {
            Log.d(_TAG, "onServiceDisconnected()");
            _service = null;
            _bound = false;
        }
    };

    public boolean sendMessageToService(final int what, final int intOption, final Bundle objectOption) {
        Thread t = new Thread(new Runnable() {
            public void run() {
                if (!_bound) {
                    bindService();
                    Log.d(_TAG, "sendMessageToService() - wait for bound");
                    await();
                    Log.d(_TAG, "sendMessageToService() - wait for bound is done");
                } else {
                    Log.d(_TAG, "sendMessageToService() - bound is null");
                }

                if (_service != null) {
                    Message msg = Message.obtain(null, what, intOption, 0, null);;
                    try {
                        if (objectOption != null) {
                            msg.setData(objectOption);
                            Log.i(_TAG, "Send message to WallpaperService : " + MSG_NAME[msg.what] + " " + msg);
                        }
                        msg.replyTo = _incomingMessenger;
                        _service.send(msg);
                    }
                    catch (RemoteException e) {
                        Log.e(_TAG, "Send message to WallpaperService failure. - " + MSG_NAME[msg.what] + " " + msg);
                        e.printStackTrace();
                    }
                } else {
                    Log.e(_TAG, "sendMessageToService() - service is null");
                }
            }
        });

        t.start();
        return true;
    }

    class IncomingHandler extends Handler {
        @Override
        public void handleMessage(Message msg) {
            Log.d(_TAG, "IncomingHandler.handleMessage()");
            if (!WallpaperServiceConnection.this.handleMessage(msg)) {
                super.handleMessage(msg);
            }
        }
    }

    private boolean handleMessage(Message msg) {
        Log.i(_TAG, "handleMessage : " + MSG_NAME[msg.what]);
        WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
        Bundle keyValues = msg.getData();
        switch (msg.what) {
            case MSG_SERVICE_INFO:
                // persistent property
                wpsi.setSourceRootPath(keyValues.getString("root_path"));
                String customConfigString = keyValues.getString("custom_config");
                wpsi.setCustomThemeInfo(ThemeInfo.setCustomConfig(customConfigString));
                wpsi.setThemeInfo(ThemeInfo.getThemeInfo(Theme.rawValue(keyValues.getInt("theme"))));
                wpsi.setPause(keyValues.getBoolean("pause"));
                wpsi.setSaver(keyValues.getBoolean("saver"));
                wpsi.setInterval(keyValues.getInt("interval"));
                // runtime property
                wpsi.setcurrentWPath((WPath)keyValues.getSerializable("current_path"));
                byte[] bitmapdata = keyValues.getByteArray("thumbnail");
                if (bitmapdata != null) {
                    Bitmap thumbnail_bmp = BitmapFactory.decodeByteArray(bitmapdata , 0, bitmapdata.length);
                    wpsi.setThumbnail(thumbnail_bmp);
                } else {
                    wpsi.setThumbnail(null);
                }
                WLinkedHashMap<String,String> lastUsedPaths = ((WLinkedHashMapWrapper<WLinkedHashMap<String,String>>) keyValues.getSerializable("used_paths")).get();
                wpsi.setLastUsedPaths(lastUsedPaths);
                wpsi.setMode(ServiceMode.rawValue(keyValues.getInt("mode")));
                if (_delegate != null) {
                    _delegate.wallpaperInfoUpdated(true);
                }
                break;
            case MSG_SHOW_TOAST:
                String message = keyValues.getString("message");
                Log.i(_TAG, "handleMessage in MSG_SHOW_TOAST: " + message);
                Context context = wpsi.getAppContext();
                Toast.makeText(context, message, Toast.LENGTH_SHORT).show();
                break;

            default:
                return false;
        }
        return true;
    }


    public void bindService() {
        Log.d(_TAG, "bindService()");
        Intent intent = AppUtil.getWallpaperServiceIntent();
        _context.bindService(intent, _connection, _context.BIND_AUTO_CREATE);
    }

    public void unbindService() {
        Log.d(_TAG, "unbindService()");
        if (_bound) {
            _context.unbindService(_connection);
            _bound = false;
        }
    }

    private void signal() {
        synchronized (_lock) {
            _lock.notify();
        }
    }

    private void await() {
        try {
            synchronized (_lock) {
                _lock.wait();
            }
        } catch (InterruptedException e) {
            Log.d(_TAG, "InterruptedException");
        }
    }

    final Messenger _incomingMessenger = new Messenger(new IncomingHandler());

    private Context _context;
    private WallpaperInfoDelegate _delegate;
    private Messenger _service = null;
    private boolean _bound =  false;
    private final Handler _handler = new Handler();
    private final Object _lock = new Object();
    private static final String _TAG = "WPServiceConnection";

}
