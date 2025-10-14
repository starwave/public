using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Runtime.InteropServices;

namespace WallpaperInfoApp {

	public partial class WallpaperNotification : Form {
		public WallpaperNotification() {
			InitializeComponent();
			_isOpen = true;
			preparePathsInMenu();
			RegisterHotKeys();
			var themeLabels = ThemeInfo.getLabels();
			int index = 0;
			foreach (var label in themeLabels) {
				var menuItem = new ToolStripMenuItem();
				menuItem.Checked = false;
				menuItem.Tag = index;
				menuItem.Enabled = true;
				menuItem.Text = label;
				menuItem.Click += themeMenuItemSelected;
				_themeMenu.DropDownItems.Add(menuItem);
				index++;
			}
			updateThemeSelectionInMenu(Theme.default1);
            refreshDummyForm();
		}

		void RegisterHotKeys() {
			_platformHotKey = new PlatformHotKey(this);
			_platformHotKey.RegisterHotKey(Keys.F7, KeyModifiers.None);					// Previous (for AppleKeyboard)
			_platformHotKey.RegisterHotKey(Keys.MediaPreviousTrack, KeyModifiers.None);	// Volume Down
			_platformHotKey.RegisterHotKey(Keys.F8, KeyModifiers.None);					// Play/Pause (for AppleKeyboard)
			_platformHotKey.RegisterHotKey(Keys.MediaPlayPause, KeyModifiers.None);		// Play/Pause
			_platformHotKey.RegisterHotKey(Keys.F9, KeyModifiers.None);					// Next (for AppleKeyboard)
			_platformHotKey.RegisterHotKey(Keys.MediaNextTrack, KeyModifiers.None);		// Next
			_platformHotKey.RegisterHotKey(Keys.F11, KeyModifiers.None);				// Volume Down (for AppleKeyboard)
			_platformHotKey.RegisterHotKey(Keys.F10, KeyModifiers.None);				// Volume Mute (for AppleKeyboard)

			// For some reasons, F12, VolumnUP, VolumeMute cannot be hooked.
			//_platformHotKey.RegisterHotKey(Keys.VolumeDown, KeyModifiers.None);		// Volume Down
			//_platformHotKey.RegisterHotKey(Keys.VolumeMute, KeyModifiers.None);		// Volume Mute
			//_platformHotKey.RegisterHotKey(Keys.VolumeUp, KeyModifiers.None);			// Volume Up
			//_platformHotKey.RegisterHotKey(Keys.F12, KeyModifiers.None);				// Volume Up (for AppleKeyboard)

			_platformHotKey.HotKeyPressed += new EventHandler<HotKeyEventArgs>(HotKeyPressed);
		}

		void HotKeyPressed(object sender, HotKeyEventArgs e) {
			BPUtil.BPLog("Hot Key Pressed = " + e.Key.ToString());
			switch (e.Key) {
				case Keys.F8:
				case Keys.MediaPlayPause:
					WallpaperServiceConnection.broadcastToService(MSG.TOGGLE_PAUSE);
					break;

				case Keys.F9:
				case Keys.MediaNextTrack:
					WallpaperServiceConnection.broadcastToService(MSG.NEXT);
					break;

				case Keys.F7:
				case Keys.MediaPreviousTrack:
					WallpaperServiceConnection.broadcastToService(MSG.PREVIOUS);
					break;

				case Keys.F10:
					WallpaperServiceConnection.broadcastToService(MSG.PREVIOUS_THEME);
					break;

				case Keys.F11:
					WallpaperServiceConnection.broadcastToService(MSG.NEXT_THEME);
					break;

				default:
					break;
			}
		}

		public void buildNotification(WPath wpath, Bitmap thumbnail, Theme theme) {
            lock (_self) {
                //BPUtil.BPLog("WallpaperNotification.buildNotification()");
                if (!_isOpen) {
                    return;
                }
                _previousThumbnail = thumbnail;
                MethodInvoker method = delegate {
                    updatePathsInMenu(wpath);
                    setResumeOrPauseOnMenuItem();
                    setThumbnail(wpath, thumbnail);
					updateThemeSelectionInMenu(theme);
                };

                //  choose right thread to call method.
                if (_trayMenuStrip.InvokeRequired) {
                    BeginInvoke(method);
                } else {
                    method.Invoke();
                }
            }
		}

		// Try to avoid the crash in image on strip menu
		private void setThumbnail(WPath wpath, Bitmap thumbnail) {
            try {
                if (thumbnail != null) {
                    if (_menuThumbnail != null) {
                        _menuThumbnail.Dispose();
                    }
                    _menuThumbnail = new Bitmap(thumbnail);
                    _thumbnailMenuItem.BackgroundImage = _menuThumbnail;
                } else {
                    _thumbnailMenuItem.BackgroundImage = global::WallpaperInfoApp.Properties.Resources.thirdwave;
                }
                this._thumbnailMenuItem.Tag = wpath;
                if (wpath != null) {
                    _thumbnailMenuItem.Enabled = true;
                } else {
                    _thumbnailMenuItem.Enabled = false;
                }

            } catch (Exception e) {
                BPUtil.BPLog(e.ToString());
            }
		}

		private void setResumeOrPauseOnMenuItem() {
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			if (wpsi.getPause()) {
				_pauseMenuItem.Text = "Resume";
			} else {
				_pauseMenuItem.Text = "Pause";
			}
		}

		private void preparePathsInMenu() {
            // TODO Popup menu broken in multi monitor due to different DPI 
            // "Per-Monitor Awareness support" needed after Visual Studio 2019
            // autoscale for menu if exists, should be false but not available
			_wallpaperMenu.DropDownItems.Clear();
			for (int index = _maxImageList - 1; index > 0; index--) {
				var menuItem = new ToolStripMenuItem();
				menuItem.Checked = false;
				if (index < _pathsInMenu.Count) {
					menuItem.Text = _pathsInMenu.getWPath(index).label();
					menuItem.Tag = _pathsInMenu.getWPath(index);
					menuItem.Enabled = true;
					menuItem.Click += imageMenuItemClicked;
					if (_pathsInMenu.getWPath(index).path == _previousPath.path) {
						menuItem.Checked = true;
					}
				} else {
					menuItem.Text = "(Empty)";
					menuItem.Tag = null;
					menuItem.Enabled = false;
				}
				_wallpaperMenu.DropDownItems.Add(menuItem);
			}
		}

		private void updatePathsInMenu(WPath wpath) {
			if (wpath == null) {
				// BPUtil.BPLog("WallpaperNotification.updatePathsInMenu() - Error with nil");
				return;
			}
			int previous_index = _pathsInMenu.FirstIndexOf(_previousPath.path);
			if (previous_index >= 0) {
				// there is no other easy way but iterating whole set
				foreach (ToolStripMenuItem menuItem in _wallpaperMenu.DropDownItems) {
					if (previous_index-- == 0) {
						menuItem.Checked = false;
						break;
					}
				}
			}
			_previousPath = wpath;
			String wpathLabel = wpath.label();
			_notifyIcon.Text = wpathLabel;
			int index = _pathsInMenu.FirstIndexOf(wpath.path);
			if (index >= 0) {
				// there is no other easy way but iterating whole set
				foreach (ToolStripMenuItem menuItem in _wallpaperMenu.DropDownItems) {
					if (index-- == 0) {
						menuItem.Checked = true;
						break;
					}
				}
			} else {
				_pathsInMenu.AddFirst(wpath.path, wpath.exif);
				if (_pathsInMenu.Count > _maxImageList) {
					_pathsInMenu.RemoveAt(_maxImageList);
				}
				var menuItem = new ToolStripMenuItem();
				menuItem.Checked = true;
				menuItem.Text = wpathLabel;
				menuItem.Tag = wpath;
				menuItem.Enabled = true;
				menuItem.Click += imageMenuItemClicked;
				_wallpaperMenu.DropDownItems.Insert(0, menuItem);
				if (_wallpaperMenu.DropDownItems.Count > _maxImageList) {
					_wallpaperMenu.DropDownItems.RemoveAt(_maxImageList);
				}
			}			
		}

		private void imageMenuItemClicked(object sender, EventArgs e) {
			if (sender.GetType() == typeof(ToolStripMenuItem)) {
				ToolStripMenuItem menuItem = (ToolStripMenuItem)sender;
				WPath wpath = (WPath)menuItem.Tag;
				if (wpath != null && BPUtil.fileExists(wpath.path)) {
					if (BPUtil.shiftKeyPressed()) {
						BPUtil.showImageFile(wpath.path);
					} else {
						BPUtil.showImagePreview(wpath.path);
					}
				}
			}
		}

		private void updateThemeSelectionInMenu(Theme theme) {
			if (theme != _previousTheme) {
				int index = 0;
				foreach (ToolStripMenuItem menuItem in _themeMenu.DropDownItems) {
					if (theme.intValue() == index) {
						menuItem.Checked = true;
					} else {
						menuItem.Checked = false;
					}
					index++;
				}
				_previousTheme = theme;
			}
		}
	
		private void themeMenuItemSelected(object sender, EventArgs e) {
			if (sender.GetType() == typeof(ToolStripMenuItem)) {
				ToolStripMenuItem menuItem = (ToolStripMenuItem)sender;
				Theme theme = ThemeMethods.rawValue((int)menuItem.Tag);
				WallpaperServiceConnection.broadcastToService(MSG.SET_THEME, theme.intValue());
			}
		}

		private void showWallpaperInfoOptionWindow(object sender, EventArgs e) {
			WallpaperInfoUI.showOptionWindow();
		}

		private void actionPreviousImage(object sender, EventArgs e) {
			WallpaperServiceConnection.broadcastToService(MSG.PREVIOUS);
		}

		private void actionNextImage(object sender, EventArgs e) {
			WallpaperServiceConnection.broadcastToService(MSG.NEXT);
		}

		private void actionPauseResume(object sender, EventArgs e) {
			WallpaperServiceConnection.broadcastToService(MSG.TOGGLE_PAUSE);
		}

		private void notifyIconDoubleClicked(object sender, MouseEventArgs e) {
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			WPath wpath = wpsi.getcurrentWPath();
			if (BPUtil.shiftKeyPressed()) {
				BPUtil.showImageFile(wpath.path);
			} else {
				BPUtil.showImagePreview(wpath.path);
			}
		}

		private void notifyIconClicked(object sender, MouseEventArgs e) {
            // avoid freeze when click and notify happens at the same time
            lock (_self) {
                MouseEventArgs me = (MouseEventArgs)e;
                if (me.Button == System.Windows.Forms.MouseButtons.Left) {
                    WallpaperInfoUI.showOptionWindow(true);
                } else if (me.Button == System.Windows.Forms.MouseButtons.Right) {
                    _notifyIcon.ContextMenuStrip.Show();
                }
            }
		}

		private void trayMenu_Quit(object sender, EventArgs e) {
			_notifyIcon.Visible = false;
			_notifyIcon.Icon = null;
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			if (wpsi.getWallpaperService().isStarted()) {
				wpsi.getWallpaperService().stopService();
			}
			Application.Exit();
		}

        // It looks WIndows uses DPI for pupup menu from the screeen where the last form is opened.
        // So this function helps popup menu to use right DPI by opening dummy form in screen where tray icon is whenever screen is chnaged.
        public static void refreshDummyForm() {
            if (_dummyForm != null) {
                _dummyForm.Close();
            }
            // dummy form helps to avoid broken popup menu in dual screen
            _dummyForm = new Form();
            _dummyForm.ShowInTaskbar = false;
            _dummyForm.ClientSize = new Size(1, 1);
            System.Drawing.Point screenPoint = new System.Drawing.Point(0, 0);
            _dummyForm.Location = _dummyForm.PointToClient(screenPoint);
            _dummyForm.SendToBack();
            _dummyForm.Show();
        }

		// Just to be safe
		private void WallpaperNotificationClosed(object sender, FormClosedEventArgs e) {
			_isOpen = false;
		}

		private bool _isOpen = false;
        private object _self = new object();

		private WLinkedHashMap<String, String> _pathsInMenu = new WLinkedHashMap<String, String>();
		private WPath _previousPath = new WPath("", "");
		private Bitmap _previousThumbnail = null;

		private const int _maxImageList = 20;

		protected override void WndProc(ref Message m) {
            if (PlatformHotKey.HookWndProc(m)) {
                return;
            }
            // for easy deployment
            if (m.Msg == NativeMethods.WM_QUIT_REQUEST) {
                Application.Exit();
                return;
            } else if (m.Msg == NativeMethods.WM_EXTRA_EXECUTED) {
                WallpaperWidgetProvider.updateLabelWidget("App is already running!");
                WallpaperInfoUI.showOptionWindow();
                return;
            // When tablet mode or window mode is changed.
            } else if (m.Msg == NativeMethods.WM_WININICHANGE) {
                if (Marshal.PtrToStringUni(m.LParam) == "UserInteractionMode") {
                    WallpaperWidgetProvider.refreshWidgets();
                }
            }
			base.WndProc(ref m);
		}

		private Theme _previousTheme = Theme.default2;
		private PlatformHotKey _platformHotKey = null;
		private Bitmap _menuThumbnail = null;
        private static Form _dummyForm = null;
    }
}
