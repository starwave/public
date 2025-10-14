using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Windows.Forms.Integration;
using System.Globalization;
using System.Text.RegularExpressions;
using WpfCustomControlLib;

namespace WallpaperInfoApp {

    public partial class WallpaperInfoUI : Form {

        public WallpaperInfoUI() {
            InitializeComponent();
			// Note : Label doesn't support DPI awareness well so use TextBox with readonly option instead. ("Theme", "Custom")
        }

		private void windowLoad(object sender, EventArgs e) {
			if (AppUtil.isMyServiceRunning()) {
				_serviceRunning = true;
				_serviceConnection = WallpaperServiceConnection.bindService(this);
			} else {
				_serviceRunning = false;
			}
			_themeComboBox.Items.AddRange(ThemeInfo.getLabels().ToArray());
			updateLayoutWithServiceInfo();
		}

		private void chooseDirButtonClicked(object sender, EventArgs e) {
            BPUtil.BPLog("WallpaperInfoUI.chooseDirButtonClicked");
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			var path = DirectoryChooserDialog.directoryChooserDialog(this, wpsi.getSourceRootPath());
			if (path != null) {
				_serviceConnection.sendMessageToService(command: MSG.SET_ROOT, objectOption: path);
				updateLayoutWithServiceInfo();
			}
		}

		private void themeComboBoxChanged(object sender, EventArgs e) {
            BPUtil.BPLog("WallpaperInfoUI.themeComboBoxChanged");
			if (_doneLoading) {
				var index = _themeComboBox.SelectedIndex;
				if (_serviceConnection != null) {
					_serviceConnection.sendMessageToService(command: MSG.SET_THEME, intOption: index);
				}			
			}
		}

		private bool _trackbarMouseDown = false;
		private bool _trackbarScrolling = false;

		private void intervalTrackBar_MouseDown(object sender, MouseEventArgs e) {
			_trackbarMouseDown = true;
		}

		private void intervalTrackBar_MouseUp(object sender, MouseEventArgs e) {
			if (_trackbarMouseDown == true && _trackbarScrolling == true) {
				if (_serviceRunning) {
					_serviceConnection.sendMessageToService(command: MSG.SET_INTERVAL, intOption: _intervalTrackBar.Value);
				}
			}
			_trackbarMouseDown = false;
			_trackbarScrolling = false;
		}

		private void intervalTrackBar_MouseMove(object sender, MouseEventArgs e) {
			_trackbarScrolling = true;
		}

		private void startStopButtonClicked(object sender, EventArgs e) {
            BPUtil.BPLog("WallpaperInfoUI.startStopButtonClicked");
			if (AppUtil.isMyServiceRunning()) {
				_serviceRunning = true;
			} else {
				_serviceRunning = false;
			}
        
			if (_serviceRunning) {
				WallpaperServiceConnection.stopService();
				_serviceConnection.unbindService();
				_serviceConnection = null;
			} else {
				_serviceConnection = WallpaperServiceConnection.bindService(wallpaperInfoUI: this);
				WallpaperServiceConnection.startService();
			}

			_serviceRunning = !_serviceRunning;
			updateLayoutWithServiceInfo();
		}

		private void previousButtonClicked(object sender, EventArgs e) {
            BPUtil.BPLog("WallpaperInfoUI.previousButtonClicked");
			_serviceConnection.sendMessageToService(command: MSG.PREVIOUS);
		}

		private void pauseButtonClicked(object sender, EventArgs e) {
            BPUtil.BPLog("WallpaperInfoUI.pauseButtonClicked");
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			_serviceConnection.sendMessageToService(command: MSG.PAUSE, intOption: (!wpsi.getPause()) ? 1 : 0);
			updateLayoutWithServiceInfo();
		}

		private void nextButtonClicked(object sender, EventArgs e) {
            BPUtil.BPLog("WallpaperInfoUI.nextButtonClicked");
			_serviceConnection.sendMessageToService(command: MSG.NEXT);
		}

		private void updateCustomConfigString(String customConfigString) {
			var wpsi = WallpaperServiceInfo.getInstance();
			// request to update service only when it's different from previous set
			if (wpsi.getCustomConfigString() != customConfigString) {
				_serviceConnection.sendMessageToService(MSG.CUSTOM_CONFIG, 0, customConfigString);
			}
		}

		private void customConfigStringChanged(object sender, EventArgs e) {
            BPUtil.BPLog("WallpaperInfoUI.customConfigStringChanged");
			String newCustomConfigString = _customConfigStringTextBox.Text;
			// lose focus to be updated
			// self.window?.makeFirstResponder(_themeComboBox);
			updateCustomConfigString(newCustomConfigString);
			_themeComboBox.Focus();
		}

        private void customConfigStringSetButtonClicked(object sender, EventArgs e) {
            BPUtil.BPLog("WallpaperInfoUI.customConfigStringSetButtonClicked");
			WpfCustomControlLib.CustomConfigDialog.openCustomConfigDialog(WallpaperServiceInfo.getInstance().getCustomConfigString(),
				customConfigString => {
				if (customConfigString != null && customConfigString != "") {
					updateCustomConfigString(customConfigString);
					_customConfigStringTextBox.Text = customConfigString;
				}
			});
		}

		private void updateLayoutWithServiceInfo() {
			if (AppUtil.isMyServiceRunning()) {
				_serviceRunning = true;
			} else {
				_serviceRunning = false;
			}

			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();

            var rootPath = wpsi.getSourceRootPath().Replace(BPUtil.getHomeDirectory(), "~/").Replace("\\", "/");
            var pretty_root_path = Regex.Replace(rootPath, @"(.):/", "/$1/", RegexOptions.IgnoreCase);
			_rootPathTextBox.Text = pretty_root_path;
		
			_intervalTrackBar.Value = wpsi.getInterval();
		
			if (!_serviceRunning) {
				_pauseButton.Image = global::WallpaperInfoApp.Properties.Resources.media_play_pause;
			} else if (wpsi.getPause()) {
				_pauseButton.Image = global::WallpaperInfoApp.Properties.Resources.media_play;
			} else {
				_pauseButton.Image = global::WallpaperInfoApp.Properties.Resources.media_pause;
			}
			_doneLoading = false;
			if (_serviceRunning) {
				_dirButton.Enabled = true;
				_themeComboBox.Enabled = true;
				_themeComboBox.SelectedIndex = wpsi.getTheme().intValue();
				_intervalTrackBar.Enabled = true;
				// update only when it's not being edited
				if (!_customConfigStringTextBox.Focused) {
					_customConfigStringTextBox.Text = wpsi.getCustomConfigString();
				}
				_customConfigStringTextBox.Enabled = true;
				_customConfigStringSetButton.Enabled = true;
				_previousButton.Enabled = true;
				_pauseButton.Enabled = true;
				_nextButton.Enabled = true;
				_startStopButton.Image = global::WallpaperInfoApp.Properties.Resources.media_stop;
			} else {
				_dirButton.Enabled = false;
				_themeComboBox.Enabled = false;
				_intervalTrackBar.Enabled = false;
				_customConfigStringTextBox.Text = "";
				_customConfigStringTextBox.Enabled = false;
				_customConfigStringSetButton.Enabled = false;
				_previousButton.Enabled = false;
				_pauseButton.Enabled = false;
				_nextButton.Enabled = false;
				_startStopButton.Image = global::WallpaperInfoApp.Properties.Resources.power_on;

				// clear list and update
				_lastUsedPathsList.Clear();
				//_lastUsedPathsList.notifyDataSetChanged();
			}
			refreshThumbnail();
			_doneLoading = true;
		}

		// UI rendering callback
		private void wallpaperInfoUpdated(bool isFullUpdate) {
			if (isFullUpdate) {
			// WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			// makeListViewItem(wpsi.getLastUsedPaths());
			}
			this.Invoke((MethodInvoker)delegate {
				this.updateLayoutWithServiceInfo();
			});
		}

		private void refreshThumbnail() {
			if (_serviceRunning) {
				WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
				if (wpsi.getThumbnail() != null) {
					_thumbnailView.Image = wpsi.getThumbnail();
					return;
				}
			}
			_thumbnailView.Image = global::WallpaperInfoApp.Properties.Resources.thirdwave;
		}

		private void refreshlastUsedPathsListView() {
		}

		public void broadcastReceiver(Bitmap thumbnail, WPath currentWPath, bool pause) {
			//Console.WriteLine("WallpaperInfoUI.broadcastReceiver()");
			if (WallpaperInfoUI._singleUI != null) {
				wallpaperInfoUpdated(false);
			} else {
				// Console.WriteLine("Broadcast is ignored due to no UI.");
			}
		}

		private WallpaperServiceConnection _serviceConnection = null;
	    private bool _serviceRunning = false;
		private bool _doneLoading = false;

		// private static var _filterStringEditingColor:NSColor = NSColor.red // Color.parseColor("#FFFCDC");
		private List<String> _lastUsedPathsList = new List<String>();
		// private static var _selectedRowColor:NSColor = NSColor.black // = Color.parseColor("#FFFC99");

		// Const value property
		public const int _lastUsedPathsRemovalCounnt = 5;

		public static void showOptionWindow(bool isToggle = false) {
			if (_singleUI == null) {
				_singleUI = new WallpaperInfoUI();
				var screen = Screen.PrimaryScreen;
                _singleUI.Location = new Point(screen.WorkingArea.Right - _singleUI.Width - 5,
                                                    screen.WorkingArea.Bottom - _singleUI.Height - 1);
				_singleUI.Show();
			} else if (isToggle) {
				_singleUI.Close();
				_singleUI = null;
				return;
			}
			// trick to bring app to the front most
			_singleUI.TopMost = true;
			_singleUI.Focus();
			_singleUI.TopMost = false;
			_singleUI.BringToFront();
		}

		private void thumbnailViewClicked(object sender, EventArgs e) {
            BPUtil.BPLog("WallpaperInfoUI.thumbnailViewClicked");
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			WPath wpath = wpsi.getcurrentWPath();
			if (BPUtil.shiftKeyPressed()) {
				BPUtil.showImageFile(wpath.path);
			} else {
				BPUtil.showImagePreview(wpath.path);
			}
		}

		private void wallpapaerInfoUIClosed(object sender, FormClosedEventArgs e) {
			_singleUI = null;
		}

		private static WallpaperInfoUI _singleUI = null;
    }
}
