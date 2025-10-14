using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Forms;
using System.Windows.Forms.Integration;

namespace WallpaperInfoApp {

	class WallpaperWidgetProvider {

		public static void refreshWidgets() {
			clearWidgets(_labelWidgetsDictionary);
			clearWidgets(_themeWidgetsDictionary);
			clearWidgets(_pauseWidgetsDictionary);
			setWindowsScale();
			var screens = Screen.AllScreens;
			foreach (var screen in screens) {
				// Label Widget
				var newLabelWidget = new WpfCustomControlLib.Widget();
				newLabelWidget.Left = (screen.WorkingArea.Left + 50) / _windowsScale;
				newLabelWidget.Top = (screen.WorkingArea.Bottom - newLabelWidget.Height - 10) / _windowsScale;
				ElementHost.EnableModelessKeyboardInterop(newLabelWidget);
				newLabelWidget.Show();
				_labelWidgetsDictionary.Add(screen.GetHashCode(), newLabelWidget);
				// Theme Widget
				var newThemeWidget = new WpfCustomControlLib.Widget();
				newThemeWidget.Left = (screen.WorkingArea.Right - 120) / _windowsScale;
				newThemeWidget.Top = (screen.WorkingArea.Top + 30) / _windowsScale;
				ElementHost.EnableModelessKeyboardInterop(newThemeWidget);
				newThemeWidget.Show();
				_themeWidgetsDictionary.Add(screen.GetHashCode(), newThemeWidget);
				// Pause Widget
				var newPauseWidget = new WpfCustomControlLib.Widget();
				newPauseWidget.Left = (screen.WorkingArea.Right - 70) / _windowsScale;
				newPauseWidget.Top = (screen.WorkingArea.Bottom - newPauseWidget.Height - 10) / _windowsScale;
                newPauseWidget.Width = 60; // this is needed to stay in assigned screen. 
				ElementHost.EnableModelessKeyboardInterop(newPauseWidget);
				newPauseWidget.Show();
				_pauseWidgetsDictionary.Add(screen.GetHashCode(), newPauseWidget);
			}
		}

		public static void updateLabelWidget(String text, Screen screenParm = null) {
			var labelWidgets = prepareWidgetsArray(_labelWidgetsDictionary, screenParm);
			foreach (var labelWidget in labelWidgets) {
				labelWidget.setWidgetText(text);
			}
		}

		public static void updateThemeWidget(String themeLabel, Screen screenParm = null, bool forceShow = false) {
			var themeWidgets = prepareWidgetsArray(_themeWidgetsDictionary, screenParm);
			foreach (var themeWidget in themeWidgets) {
				if (!themeWidget.getWidgetText().Equals(themeLabel) || forceShow) {
					themeWidget.setVisible(true);
					themeWidget.setWidgetText(themeLabel);
					_themeChangeCount += 1;
				}
				if (themeWidget.getVisible() && !forceShow) {
					int old_value = _themeChangeCount;
					Task.Delay(7000).ContinueWith(_ => {
						if (old_value == _themeChangeCount) {
							themeWidget.setVisible(false);
						}
					});
				}
			}
		}

		public static void updatePauseWidget(bool pause, Screen screenParm = null) {
			var pauseWidgets = prepareWidgetsArray(_pauseWidgetsDictionary, screenParm);
			foreach (var pauseWidget in pauseWidgets) {
				pauseWidget.setWidgetText((pause) ? "\u2225" : "");
			}
		}

		private static void clearWidgets(Dictionary<int, WpfCustomControlLib.Widget> dict) {
			foreach (KeyValuePair<int, WpfCustomControlLib.Widget> entry in dict) {
				((WpfCustomControlLib.Widget)entry.Value).closeWidget();
			}
			dict.Clear();
		}

		private static List<WpfCustomControlLib.Widget> prepareWidgetsArray(Dictionary<int, WpfCustomControlLib.Widget> dict, Screen screenParm) {
			List<WpfCustomControlLib.Widget> widgets = new List<WpfCustomControlLib.Widget>();
			if (screenParm != null) {
				widgets.Add(dict[screenParm.GetHashCode()]);
			} else {
				foreach (var widget in dict) {
					widgets.Add(widget.Value);
				}
			}
			return widgets;
		}

		private static void setWindowsScale() {
			_windowsScale = (Screen.PrimaryScreen.Bounds.Width / SystemParameters.PrimaryScreenWidth);
		}

		private static double _windowsScale;
		public static int _themeChangeCount = 0;
		public static Dictionary<int, WpfCustomControlLib.Widget> _labelWidgetsDictionary = new Dictionary<int, WpfCustomControlLib.Widget>();
		public static Dictionary<int, WpfCustomControlLib.Widget> _themeWidgetsDictionary = new Dictionary<int, WpfCustomControlLib.Widget>();
		public static Dictionary<int, WpfCustomControlLib.Widget> _pauseWidgetsDictionary = new Dictionary<int, WpfCustomControlLib.Widget>();
	}
}
