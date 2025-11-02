package com.thirdwavesoft.wallpaperinfo;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.IntentFilter;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.BaseAdapter;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.SeekBar;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.ImageView;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.Toast;
import android.view.View.OnClickListener;
import android.content.BroadcastReceiver;

import java.util.ArrayList;
import java.util.concurrent.Future;

import static com.thirdwavesoft.wallpaperinfo.AppUtil.*;

import androidx.localbroadcastmanager.content.LocalBroadcastManager;

interface WallpaperInfoDelegate {
	public void wallpaperInfoUpdated(boolean isFullUpdate);
}

public class WallpaperInfoUI extends Activity implements WallpaperInfoDelegate {
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.wallpaperinfo_ui_layout);
		addListenerOnDirButton();
		addListenerOnGalleryCopyButton();
		addListenerOnSyncButton();
		addListenerOnThemeSpinner();
		addListenerOnSaverCheckBox();
		addListenerOnIntervalSeekBar();
		addListenerOnButtons();
		addListenerOnStartStopButton();
		addListenerOnCustomConfigString();
		addListenerOnImageView();
		setListAdepterLastUsedPaths();
		_sdcardExtDir = PlatformInfo.getSDCardExtDirectory(WallpaperInfoUI.this);
		_bonjourDiscovery = new BPBonjourClient(this);
		_bonjourDiscovery.discoverServices(this);
	}

	private boolean getServiceRunning() {
		boolean oldServiceRunning = _serviceRunning;
		if (AppUtil.isMyServiceRunning()) {
			_serviceRunning = true;
			if (!oldServiceRunning) {
				_serviceConnection.sendMessageToService(MSG_REQUEST_INFO, 0, null);
			}
		} else {
			_serviceRunning = false;
		}
		return _serviceRunning;
	}

	@Override
	protected void onStart() {
		super.onStart();
		Log.d(_TAG, "onStart()");
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
		Log.d(_TAG, "onResume()");
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		wpsi.setActivityonTop(true);
		// if service is running update UI flow will be done by _serviceRunning value update
		// it doesn't need to send MSG_ACTIVITY_REPORT (option 1) message since it makes race condition. Instead, handle in MSG_REQUEST_INFO
		boolean oldServiceRunning = _serviceRunning;
		if (!getServiceRunning()) {
			updateLayoutWithServiceInfo();
		} else {
			// opposite case will be covered by getServiceRunning()
			if (oldServiceRunning) {
				_serviceConnection.sendMessageToService(MSG_REQUEST_INFO, 0, null);
			}
		}
		if (!_broadcastreceiverRegistered) {
			synchronized (this) {
				_broadcastreceiverRegistered = true;
				IntentFilter filter = new IntentFilter();
				filter.addAction("ACTION_GET_INFO_INTERNAL");
				LocalBroadcastManager.getInstance(this).registerReceiver(_broadcastReceiver, filter);
			}
		}
		_customConfigEditing = false;
	}

	@Override
	protected void onPause() {
		super.onPause();
		Log.d(_TAG, "onPause()");
		synchronized (this) {
			// to avoid crash. unregister receiver on onPause
			if (_broadcastreceiverRegistered) {
				_broadcastreceiverRegistered = false;
				LocalBroadcastManager.getInstance(this).unregisterReceiver(_broadcastReceiver);
			}
		}
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		wpsi.setActivityonTop(false);
	}

	@Override
	protected void onStop() {
		super.onStop();
		Log.d(_TAG, "onStop()");
		synchronized (this) {
			if (_serviceConnected && _serviceRunning) {
				_serviceConnection.unbindService();
			}
			_serviceConnected = false;
		}
	}

	@Override
	protected void onDestroy() {
		super.onDestroy();
		_bonjourDiscovery.stopDiscovery();
		Log.d(_TAG, "onDestroy()");
	}

	// Menu methods
	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		getMenuInflater().inflate(R.menu.wallpaperinfo, menu);
		return true;
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		int id = item.getItemId();
		if (id == R.id.action_settings) {
			return true;
		}
		return super.onOptionsItemSelected(item);
	}

	// Initializing UI and Listeners
	private void addListenerOnDirButton() {
		_dirButton = (Button) findViewById(R.id.chooseDirButton);
		_dirButton.setOnClickListener(new OnClickListener() {

			@Override
			public void onClick(View v) {
				final WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
				// Create DirectoryChooserDialog and register a callback
				DirectoryChooserDialog directoryChooserDialog =
						new DirectoryChooserDialog(WallpaperInfoUI.this,
								new DirectoryChooserDialog.ChosenDirectoryListener() {
									@Override
									public void onChosenDir(String chosenDir) {
										wpsi.setSourceRootPath(chosenDir);
										Bundle bundle = new Bundle();
										bundle.putString("root_path", chosenDir);
										_serviceConnection.sendMessageToService(MSG_SET_ROOT, 0, bundle);
										// adding delay
										new Handler().postDelayed(new Runnable() {
											@Override
											public void run() {
												_serviceConnection.sendMessageToService(MSG_REQUEST_INFO, 0, null);
											}
										}, 150);

										Toast.makeText(
												WallpaperInfoUI.this, chosenDir + " is selected.", Toast.LENGTH_LONG).show();
									}
								});
				directoryChooserDialog.setNewFolderEnabled(false);
				directoryChooserDialog.chooseDirectory(wpsi.getSourceRootPath());
			}
		});
	}
	private void addListenerOnGalleryCopyButton() {
		_galleryCopyButton = (Button) findViewById(R.id.galleryCopy);
		_galleryCopyButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				_bonjourDiscovery.showServiceSelectionDialog(WallpaperInfoUI.this);
			}
		});
	}

	private void addListenerOnSyncButton() {
		_syncButton = (Button) findViewById(R.id.syncButton);
		_syncButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				String url = "http://192.168.1.111:8080/masai";
				AsynchronousHttpRequest http = new AsynchronousHttpRequest();
				Future<String> future = http.sendAsyncGetRequest(url);
				try {
					String response = future.get();
					Toast.makeText(
							WallpaperInfoUI.this, response, Toast.LENGTH_SHORT).show();
				} catch (Exception e) {
					Toast.makeText(
							WallpaperInfoUI.this, "request error", Toast.LENGTH_SHORT).show();
				}
 			}
		});
	}

	private void addListenerOnThemeSpinner() {
		final WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		_themeSpinner = findViewById(R.id.theme);
		_themeSpinner.setOnItemSelectedListener(new SpinnerOnItemSelectedListener());
		ArrayList<String> themes = ThemeInfo.getLabels();
		ArrayAdapter<String> dataAdapter = new ArrayAdapter<String>(this,
				android.R.layout.simple_spinner_item, themes);
		dataAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		_themeSpinner.setAdapter(dataAdapter);
	}

	class SpinnerOnItemSelectedListener implements AdapterView.OnItemSelectedListener {
		public void onItemSelected(AdapterView<?> parent, View view, int pos, long id) {
			if (_serviceRunning && _infoUpdatedFully) {
				WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
				ThemeInfo wpti = ThemeInfo.getThemeInfo(Theme.rawValue(pos));
				// request to update service only when it's different from previous set
				if (!wpti.equals(wpsi.getThemeInfo())) {
					BPUtil.BPLog("Spinner Theme Changed from %s to to %s", wpsi.getTheme().stringValue(), wpti._theme.stringValue());
					wpsi.setThemeInfo(wpti);
					_serviceConnection.sendMessageToService(MSG_SET_THEME, wpsi.getTheme().intValue(), null);
					// service will issue MSG_SERVICE_INFO as followup to update its information to activity automatically
				}
			}
		}
		@Override
		public void onNothingSelected(AdapterView<?> arg0) {
		}
	}

	private void addListenerOnSaverCheckBox() {
		final WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		_saverCheckBox = (CheckBox) findViewById(R.id.saverCheckBox);
		_saverCheckBox.setChecked(wpsi.getSaver());
		_saverCheckBox.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				wpsi.setSaver(_saverCheckBox.isChecked());
				_serviceConnection.sendMessageToService(MSG_SET_SAVER, _saverCheckBox.isChecked() ? 1:0,  null);
			}
		});
	}

	private void addListenerOnIntervalSeekBar() {
		final WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		_intervalSeekBar = findViewById(R.id.interval);
		_intervalSeekBar.setMax(WallpaperServiceInfo._maxInterval - WallpaperServiceInfo._minInterval);
		_intervalSeekbarThumb = LayoutInflater.from(WallpaperInfoUI.this).inflate(R.layout.interval_seekbar_thumb_layout, null, false);
		_intervalSeekBar.setProgress(wpsi.getInterval() - WallpaperServiceInfo._minInterval);
		((TextView) findViewById(R.id.interval_min_label)).setText(WallpaperServiceInfo._minInterval + "s");
		((TextView) findViewById(R.id.interval_max_label)).setText(WallpaperServiceInfo._maxInterval + "s");
		_intervalSeekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
			@Override
			public void onStopTrackingTouch(SeekBar seekBar) {
				int newInterval = _intervalSeekBar.getProgress() + WallpaperServiceInfo._minInterval;
				wpsi.setInterval(newInterval);
				Toast.makeText(
						WallpaperInfoUI.this, newInterval + " second is set.", Toast.LENGTH_SHORT).show();
				_serviceConnection.sendMessageToService(MSG_SET_INTERVAL, wpsi.getInterval(), null);
			}
			@Override
			public void onStartTrackingTouch(SeekBar seekBar) {
			}
			@Override
			public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
				seekBar.setThumb(updateIntervalSeekbarThumb(progress, _serviceRunning));
			}
		});
	}

	private Drawable updateIntervalSeekbarThumb(int progress, boolean enabled) {
		TextView tv = _intervalSeekbarThumb.findViewById(R.id.tv_progress);
		tv.setText((progress +  + WallpaperServiceInfo._minInterval) + "s" );
		if (enabled) {
			tv.setTextColor(Color.BLACK);
		} else {
			tv.setTextColor(Color.LTGRAY);
		}
		_intervalSeekbarThumb.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED);
		Bitmap bitmap = Bitmap.createBitmap(_intervalSeekbarThumb.getMeasuredWidth(), _intervalSeekbarThumb.getMeasuredHeight(), Bitmap.Config.ARGB_8888);
		Canvas canvas = new Canvas(bitmap);
		_intervalSeekbarThumb.layout(0, 0, _intervalSeekbarThumb.getMeasuredWidth(), _intervalSeekbarThumb.getMeasuredHeight());
		_intervalSeekbarThumb.draw(canvas);
		return new BitmapDrawable(getResources(), bitmap);
	}

	private void addListenerOnButtons() {
		_pauseButton = (Button) findViewById(R.id.pauseButton);
		_pauseButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
				_serviceConnection.sendMessageToService(MSG_PAUSE, (!wpsi.getPause()) ? 1:0, null);
				wpsi.setPause(!wpsi.getPause());
				updateLayoutWithServiceInfo();
			}
		});
		_nextButton = (Button) findViewById(R.id.nextButton);
		_nextButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				_serviceConnection.sendMessageToService(MSG_NEXT, 0, null);
				WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			}
		});
		_previousButton = (Button) findViewById(R.id.previousButton);
		_previousButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				_serviceConnection.sendMessageToService(MSG_PREVIOUS, 0, null);
				WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			}
		});
	}

	private void addListenerOnImageView() {
		_rootPathTextView = (TextView) findViewById(R.id.root_path);
		_thumbnailView  = (ImageView) findViewById(R.id.thumbnail);
		_thumbnailView.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				Intent intent = new Intent(WallpaperInfoUI.this, TromsoUI.class);
				startActivity(intent);
			}
		});
		_shareImageView = (ImageView)findViewById(R.id.shareImage);
		_shareImageView.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				// TODO use FileProvider
				// If your targetSdkVersion >= 24, then we have to use FileProvider class to give access to the particular file or folder to make them accessible for other apps.
				WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
				WPath currentWPath = wpsi.getcurrentWPath();
				if (currentWPath != null) {
					PlatformInfo.shareImageVia(WallpaperInfoUI.this, currentWPath.path);
				}
			}
		});
		_castImageView = (ImageView)findViewById(R.id.castImage);
		_castImageView.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				// TODO Implement
				PlatformInfo.refreshGallery(v.getContext(), null);
			}
		});
	}

	private void addListenerOnStartStopButton() {
		_startStopButton = (Button) findViewById(R.id.startStopButton);
		_startStopButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				BPUtil.BPLog("Toggle Start/Stop Request from Activity");
				if (getServiceRunning()) {
					if (_serviceConnected) {
						_serviceConnected = false;
						_serviceConnection.unbindService();
					}
					stopService(new Intent(WallpaperInfoUI.this, WallpaperService.class));
					_infoUpdatedFully = false;
				} else {
					startService(new Intent(WallpaperInfoUI.this, WallpaperService.class));
					_serviceConnection.bindService();
					_serviceConnected = true;
				}
				new Handler().postDelayed(new Runnable() {
					@Override
					public void run() {
						updateLayoutWithServiceInfo();
					}
				}, 400);
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

	@SuppressLint("ClickableViewAccessibility")
	private void addListenerOnCustomConfigString() {
		_customConfigStringEditText = (EditText) findViewById(R.id.custom_config_string);
		_customConfigStringEditText.setOnFocusChangeListener(new View.OnFocusChangeListener() {
			public void onFocusChange(View v, boolean gainFocus) {
				if (gainFocus) {
					v.setBackgroundColor(_customConfigStringEditingColor);
					_customConfigEditing = true;
				}
				else {
					v.setBackgroundResource(android.R.color.transparent);
					InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
					imm.hideSoftInputFromWindow(v.getWindowToken(), 0);
					updateCustomConfigString(_customConfigStringEditText.getText().toString());
					_customConfigEditing = false;
				}
			}
		});
		_customConfigStringEditText.setOnEditorActionListener(new TextView.OnEditorActionListener() {
			@Override
			public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
				if (actionId == EditorInfo.IME_ACTION_DONE) {
					_customConfigStringEditText.clearFocus();
				}
				return false;
			}
		});
		_customConfigStringSetButton = (Button) findViewById(R.id.custom_config_set);
		_customConfigStringSetButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				// remove focus if any
				InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
				imm.hideSoftInputFromWindow(v.getWindowToken(), 0);
				_customConfigStringEditText.clearFocus();

				// open filter config dialog box
				final WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
				new CustomConfigDialog(WallpaperInfoUI.this,
						new CustomConfigDialog.ConfirmCustomConfigStringListner() {
							@Override
							public void onConfirmCustomConfigString(String newCustomConfigString) {
								_customConfigStringEditText.setText(newCustomConfigString);
								updateCustomConfigString(newCustomConfigString);
							}});
			}
		});
	}

	private void setListAdepterLastUsedPaths() {
		_lastUsedPathsListView = findViewById(R.id.last_used_paths_list);
		_lastUsedPathsList = new WLinkedHashMap<String, String>();
        _wallpaperAdapter = new WallpaperAdapter();
        _lastUsedPathsListView.setAdapter(_wallpaperAdapter);
		_lastUsedPathsListView.setChoiceMode(ListView.CHOICE_MODE_SINGLE);
		_lastUsedPathsListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
			@Override
			public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
				_lastUsedPathsListView.setSelection(position);
				_wallpaperAdapter.setSelectedRow(position);
				_wallpaperAdapter.notifyDataSetChanged();
				Bundle keyValues = new Bundle();
				keyValues.putSerializable("image_path", _lastUsedPathsList.getWPath(position));
				_serviceConnection.sendMessageToService(MSG_SET_WALLPAPER, 0, keyValues);
			}
		});
	}

	// UI rendering methods
	public void wallpaperInfoUpdated(boolean isFullUpdate) {
		Log.d(_TAG, "wallpaperInfoUpdated - " + new Boolean(isFullUpdate).toString());
		if (isFullUpdate) {
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			makeListViewItem(wpsi.getLastUsedPaths());
			_infoUpdatedFully = true;
		}
		runOnUiThread(new Runnable() {
			@Override
			public void run() {
				updateLayoutWithServiceInfo();
			}
		});
	}

	private void refreshThumbnail() {
		if (_serviceRunning && _infoUpdatedFully) {
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			if (wpsi.getThumbnail() != null) {
				_thumbnailView.setImageBitmap(wpsi.getThumbnail());
				_thumbnailView.invalidate();
				return;
			}
		}
		_thumbnailView.setImageResource(R.drawable.thirdwave);
		_thumbnailView.invalidate();
	}

	private void refreshLastUsedPathsListViewWithCurrentPath() {
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		WPath path = wpsi.getcurrentWPath();
		if (path != null) {
			int index = _lastUsedPathsList.firstIndexOf(path.path);
			if (index < 0) {
				if (_lastUsedPathsList.size() + 1 > WallpaperService._maxLastUsedPaths) {
					_lastUsedPathsList.removeAt(_lastUsedPathsList.size() - 1);
				}
				_lastUsedPathsList.addFirst(path.path, path.exif);
				index =  0;
			}
			_wallpaperAdapter.setSelectedRow(index);
			//_lastUsedPathsListView.smoothScrollToPosition(index);
		}
		_wallpaperAdapter.notifyDataSetChanged();
	}

    class WallpaperAdapter extends BaseAdapter {
        private LayoutInflater _inflater;
		private int _selectedRow = -1;
		public void setSelectedRow(int selectedRow) {
			_selectedRow = selectedRow;
		}
        public WallpaperAdapter() {
            _inflater = (LayoutInflater) WallpaperInfoUI.this.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        }
        @Override
        public int getCount() {
            return _lastUsedPathsList.size();
        }
        @Override
        public Object getItem(int position) {
            return _lastUsedPathsList.getWPath(position);
        }
        @Override
        public long getItemId(int position) {
            return position;
        }
        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            ViewHolder viewHolder;
            if (convertView == null) {
            	viewHolder = new ViewHolder();
                convertView = _inflater.inflate(R.layout.wallpaperinfo_ui_last_paths_row_layout, parent,false);
				viewHolder.tv1 = (TextView)convertView.findViewById(R.id.lv_item_folder_text);
				viewHolder.tv2 = (TextView)convertView.findViewById(R.id.lv_item_image_text);
				convertView.setTag(viewHolder);
			}
            else {
            	viewHolder = (ViewHolder) convertView.getTag();
            }
			WPath imagePath = (WPath)getItem(position);
			String prettyImagePath = imagePath.label();
			prettyImagePath = prettyImagePath.substring(prettyImagePath.indexOf("/")+2);
			viewHolder.tv1.setText(BPUtil.getFolderName(imagePath.path));
			viewHolder.tv2.setText(prettyImagePath);
			if (position == _selectedRow) {
				convertView.setBackgroundColor(_selectedRowColor);
			} else {
				convertView.setBackgroundResource(android.R.color.transparent);
			}
            return convertView;
        }
        class ViewHolder {
            TextView tv1, tv2;
        }
    }

	synchronized private void updateLayoutWithServiceInfo() {
		View [] controls = { _dirButton, _themeSpinner, _saverCheckBox, _intervalSeekBar,
				_thumbnailView,	_customConfigStringEditText, _customConfigStringSetButton,
				_previousButton, _pauseButton, _nextButton };
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		if (getServiceRunning()) {
			for (View control: controls) {
				control.setEnabled(true);
			}
			_startStopButton.setText(R.string.stop);
		} else {
			for (View control: controls) {
				control.setEnabled(false);
			}
			_startStopButton.setText(R.string.start);
			_customConfigStringEditText.setText(_defaultCustomConfigString);
			// clear list and update
			_lastUsedPathsList.clear();
			_wallpaperAdapter.notifyDataSetChanged();
		}
		if (_serviceRunning) {
			if (_infoUpdatedFully) {
				String rootPath = wpsi.getSourceRootPath();
				String pretty_root_path = rootPath.replace(BPUtil.getHomeDirectory(), "~");
				// make sure it's not empty when there is no sdcard inserted
				if (!_sdcardExtDir.equals("")) {
					pretty_root_path = pretty_root_path.replace(_sdcardExtDir, "/SDCard");
				}
				_rootPathTextView.setText(pretty_root_path);
				_saverCheckBox.setChecked(wpsi.getSaver());
				_intervalSeekBar.setProgress(wpsi.getInterval() - wpsi._minInterval);
				if (!_customConfigEditing) { // prevent updating during editing
					if (wpsi.getCustomConfigString() != null) {
						_customConfigStringEditText.setText(wpsi.getCustomConfigString());
					} else {
						_customConfigStringEditText.setText(_defaultCustomConfigString);
					}
				}
			}
			_themeSpinner.setSelection(wpsi.getTheme().intValue());
			if (wpsi.getPause()) {
				_pauseButton.setText(R.string.resume);
			} else {
				_pauseButton.setText(R.string.pause);
			}
		}
		_intervalSeekBar.setThumb(updateIntervalSeekbarThumb(_intervalSeekBar.getProgress(), _serviceRunning));
		refreshThumbnail();
	}

	// Property update util method
	synchronized private void makeListViewItem(WLinkedHashMap<String,String> lastUsedPathsList) {
		_lastUsedPathsList = new WLinkedHashMap<String, String>();
		for (int i = 0; i < lastUsedPathsList.size(); i++) {
			// service is returning only theme list, addFirst makes it reverse order
			WPath wpath = lastUsedPathsList.getWPath(i);
			_lastUsedPathsList.addFirst(wpath.path, wpath.exif);
		}
		refreshLastUsedPathsListViewWithCurrentPath();
	}

	// connections and status property
	BroadcastReceiver _broadcastReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			String action = intent.getAction();
			Log.d(_TAG, "Broadcast Received in Activity : " + action);
			if (action.equals("ACTION_GET_INFO_INTERNAL")) {
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
				refreshLastUsedPathsListViewWithCurrentPath();
				WallpaperInfoUI.this.wallpaperInfoUpdated(false);
			}
		}
	};
	private boolean _broadcastreceiverRegistered = false;
	private WallpaperServiceConnection _serviceConnection;
	private boolean _serviceConnected = false;
	private boolean _serviceRunning = false;
	private boolean _customConfigEditing = false;
	private boolean _infoUpdatedFully = false;
	// activity UI property
	private TextView _rootPathTextView;
	private Spinner _themeSpinner;
	private CheckBox _saverCheckBox;
	private SeekBar _intervalSeekBar; private View _intervalSeekbarThumb;
	private Button _dirButton, _galleryCopyButton, _syncButton, _pauseButton, _startStopButton, _previousButton, _nextButton, _customConfigStringSetButton;
	private ImageView _thumbnailView, _shareImageView, _castImageView;
	private EditText _customConfigStringEditText;
	private final static int _customConfigStringEditingColor = Color.parseColor("#FFFCDC");

	private ListView _lastUsedPathsListView;
	private WallpaperAdapter _wallpaperAdapter;
	private WLinkedHashMap<String, String> _lastUsedPathsList;
	private final static int _selectedRowColor = Color.parseColor("#FFFC99");
	private BPBonjourClient _bonjourDiscovery;
	private String _sdcardExtDir = "";

	// Const value property
	public final static String _defaultCustomConfigString =
					ThemeInfo._default_custom_root + ";" +
					ThemeInfo._default_custom_allow + ";" +
					ThemeInfo._default_custom_filter;
	private static final String _TAG = "WallpaperInfoUI";
}
