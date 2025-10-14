package com.thirdwavesoft.wallpaperinfo;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.GestureDetector;
import android.view.MotionEvent;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import java.io.File;

import static com.thirdwavesoft.wallpaperinfo.AppUtil.*;

import androidx.localbroadcastmanager.content.LocalBroadcastManager;

public class TromsoUI extends Activity implements WallpaperInfoDelegate  {

    private class GestureListener extends GestureDetector.SimpleOnGestureListener {
        @Override
        public boolean onSingleTapConfirmed(MotionEvent e) {
            _serviceConnection.sendMessageToService(MSG_TOGGLE_PAUSE, 0, null);
            return false;
        }

        @Override
        public boolean onDoubleTap(MotionEvent e) {
            setIdleTimerDisabled(false);
            final WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
            new CustomConfigDialog(TromsoUI.this,
                    new CustomConfigDialog.ConfirmCustomConfigStringListner() {
                        @Override
                        public void onConfirmCustomConfigString(String newCustomConfigString) {
                            updateCustomConfigString(newCustomConfigString);
                            setIdleTimerDisabled(true);
                        }});
            return false;
        }

        @Override
        public boolean onFling(MotionEvent e1, MotionEvent e2, float velocityX, float velocityY) {
            if (e1.getX() - e2.getX() > MIN_SWIPPING_DISTANCE && Math.abs(velocityX) > THRESHOLD_VELOCITY) {
                //Log.i(_TAG, "Swipe Left");
                _serviceConnection.sendMessageToService(MSG_NEXT, 0, null);
                return false;
            }
            else if (e2.getX() - e1.getX() > MIN_SWIPPING_DISTANCE && Math.abs(velocityX) > THRESHOLD_VELOCITY) {
                //Log.i(_TAG, "Swipe Right");
                _serviceConnection.sendMessageToService(MSG_PREVIOUS, 0, null);
                return false;
            }
            else if (e1.getY() - e2.getY() > MIN_SWIPPING_DISTANCE && Math.abs(velocityY) > THRESHOLD_VELOCITY) {
                //Log.i(_TAG, "Swipe Up");
                _serviceConnection.sendMessageToService(MSG_PREVIOUS_THEME, 0, null);
                return false;
            }
            else if (e2.getY() - e1.getY() > MIN_SWIPPING_DISTANCE && Math.abs(velocityY) > THRESHOLD_VELOCITY) {
                //Log.i(_TAG, "Swipe Down");
                _serviceConnection.sendMessageToService(MSG_NEXT_THEME, 0, null);
                return false;
            }
            return false;
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.tromso_ui_layout);
        _wallpaperImageView = (ImageView) findViewById(R.id.wallpaperImage);
        _imageLabelTextView = (TextView) findViewById(R.id.imageLabel);
        _themeLabelTextView = (TextView) findViewById(R.id.themeLabel);
        _pauseLabelTextView = (TextView) findViewById(R.id.pauseLabel);
        _gestureDetector = new GestureDetector(this, new GestureListener());
        _wallpaperImageView.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(final View view, final MotionEvent event) {
                _gestureDetector.onTouchEvent(event);
                return true;
            }
        });
        addListenerOnImageView();
    }

    @Override
    protected void onStart() {
        super.onStart();
        synchronized (this) {
            if (!_serviceConnected) {
                _serviceConnected = true;
                _serviceConnection = new WallpaperServiceConnection(this, this);
            }
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        setIdleTimerDisabled(true);
        _serviceConnection.sendMessageToService(MSG_SET_MODE, ServiceMode.slideshow.intValue(), null);
        WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
        setWallpaperOnUI(wpsi.getcurrentWPath());
        updatePauseOnUI(wpsi.getPause());
        updateThemeOnUI(wpsi.getTheme(), true);
        _previouspause = wpsi.getPause();
        synchronized (this) {
            // to avoid hanging
            if (!_broadcastreceiverRegistered) {
                _broadcastreceiverRegistered = true;
                IntentFilter filter = new IntentFilter();
                filter.addAction("ACTION_GET_INFO_INTERNAL");
                LocalBroadcastManager.getInstance(this).registerReceiver(_broadcastReceiver, filter);
            }
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        setIdleTimerDisabled(false);
        _serviceConnection.sendMessageToService(MSG_SET_MODE, ServiceMode.wallpaper.intValue(), null);
        synchronized (this) {
            // to avoid crash. unregister receiver on onPause
            if (_broadcastreceiverRegistered) {
                _broadcastreceiverRegistered = false;
                LocalBroadcastManager.getInstance(this).unregisterReceiver(_broadcastReceiver);
            }
        }
    }

    @Override
    protected void onStop() {
        super.onStop();
        synchronized (this) {
            if (_serviceConnected) {
                _serviceConnection.unbindService();
            }
            _serviceConnected = false;
        }
        synchronized (this) {
            Intent intent = new Intent();
            setResult(RESULT_OK, intent);
            finish();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
    }

    private void addListenerOnImageView() {
        _shareImageView = (ImageView)findViewById(R.id.shareImage);
        _shareImageView.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                // TODO use FileProvider
                // If your targetSdkVersion >= 24, then we have to use FileProvider class to give access to the particular file or folder to make them accessible for other apps.
                WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
                WPath currentWPath = wpsi.getcurrentWPath();
                if (currentWPath != null) {
                    PlatformInfo.shareImageVia(TromsoUI.this, currentWPath.path);
                }
            }
        });
        _castImageView = (ImageView)findViewById(R.id.castImage);
        _castImageView.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                // TODO Implement
            }
        });
    }

    private void updateCustomConfigString(String customConfigString) {
        WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
        // request to update service only when it's different from previous set
        if (!wpsi.getCustomConfigString().equals(customConfigString)) {
            Bundle keyValues = new Bundle();
            keyValues.putString("custom_config_string", customConfigString);
            _serviceConnection.sendMessageToService(MSG_CUSTOM_CONFIG, 0, keyValues);
            wpsi.setCustomThemeInfo(ThemeInfo.setCustomConfig(customConfigString));
            // service will issue MSG_SERVICE_INFO as followup to update its information to activity automatically
        }
    }

    // dummy protocol for WallpaperInfoDelegate interface
    public void wallpaperInfoUpdated(boolean isFullUpdate) {
    }

    synchronized void setWallpaperOnUI(WPath wpath) {
        if (wpath != null && wpath.path != null) {
            Bitmap myBitmap = BitmapFactory.decodeFile(wpath.path);
            _wallpaperImageView.setImageBitmap(myBitmap);
            _imageLabelTextView.setText(wpath.label());
        } else {
            _wallpaperImageView.setImageResource(R.drawable.thirdwave);
            _imageLabelTextView.setText("");
        }
    }

    synchronized void setIdleTimerDisabled(boolean set) {
        //must use local _pause over wspi.getPause() due to timing issue around WallpaperInfoUI's boradcast receipt.
        if (set && !_pause) {
            getWindow().setFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                    android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        } else {
            getWindow().clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        }
    }

    synchronized void updatePauseOnUI(boolean pause) {
        if (pause) {
            _pauseLabelTextView.setText(R.string.pause);
        } else {
            _pauseLabelTextView.setText("");
        }
    }

    synchronized void updateThemeOnUI(Theme theme, boolean forceShow) {
        String themeLabel = theme.label();
        if (!_themeLabelTextView.getText().equals(themeLabel) || forceShow) {
            _themeLabelTextView.setVisibility(View.VISIBLE);
            _themeLabelTextView.setText(themeLabel);
            _themeChangeCount += 1;
        }
        if (_themeLabelTextView.getVisibility() == View.VISIBLE && !forceShow) {
            final int old_value = _themeChangeCount;
            final Handler handler = new Handler(Looper.getMainLooper());
            handler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    if (old_value == TromsoUI.this._themeChangeCount) {
                        _themeLabelTextView.setVisibility(View.INVISIBLE);
                    }
                }
            }, 7000);
        }
    }

    // connections and status property
    BroadcastReceiver _broadcastReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            Log.d(_TAG, "Broadcast Received in Activity : " + action);
            if (action.equals("ACTION_GET_INFO_INTERNAL")) {
                WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
                String path = intent.getExtras().getString("INTENT_EXTRA_IMAGE_PATH");
                String exif = intent.getExtras().getString("INTENT_EXTRA_IMAGE_EXIF");
                WPath wpath;
                if (path != null) {
                    wpath = new WPath(path, exif);
                } else {
                    wpath = null;
                }
                TromsoUI.this.setWallpaperOnUI(wpath);
                _pause = intent.getExtras().getBoolean("INTENT_EXTRA_PAUSE");
                TromsoUI.this.updatePauseOnUI(_pause);
                TromsoUI.this.updateThemeOnUI((Theme.rawValue(intent.getExtras().getInt("INTENT_EXTRA_THEME"))), _pause);
                if (_previouspause != _pause) {
                    // _pause will be checked within the function
                    setIdleTimerDisabled(true);
                }
                _previouspause = _pause;
            }
        }
    };
    private boolean _broadcastreceiverRegistered = false;
    private WallpaperServiceConnection _serviceConnection;
    private boolean _serviceConnected = false;
    private boolean _pause = false;
    private boolean _previouspause = false;
    // activity UI property
    private ImageView _wallpaperImageView, _shareImageView, _castImageView;
    private TextView _imageLabelTextView;
    private TextView _pauseLabelTextView;
    private TextView _themeLabelTextView;
    private GestureDetector _gestureDetector;

    private int _themeChangeCount = 0;
    private static final int MIN_SWIPPING_DISTANCE = 70;
    private static final int THRESHOLD_VELOCITY = 50;
    private static final String _TAG = "TromsoUI";
}
