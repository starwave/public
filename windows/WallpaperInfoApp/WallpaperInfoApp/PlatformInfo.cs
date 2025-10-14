using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace WallpaperInfoApp {

	class PlatformInfo {

		public enum TaskBarLocation { TOP, BOTTOM, LEFT, RIGHT }

		public static TaskBarLocation getTaskBarLocation(Screen screen = null) {
			if (screen == null) {
				screen = Screen.PrimaryScreen;
			}
			TaskBarLocation taskBarLocation = TaskBarLocation.BOTTOM;
			bool taskBarOnTopOrBottom = (screen.WorkingArea.Width == screen.Bounds.Width);
			if (taskBarOnTopOrBottom) {
				if (Screen.PrimaryScreen.WorkingArea.Top > 0) {
					taskBarLocation = TaskBarLocation.TOP;
				} else {
					taskBarLocation = TaskBarLocation.BOTTOM;
				}
			}
			else {
				if (Screen.PrimaryScreen.WorkingArea.Left > 0) {
					taskBarLocation = TaskBarLocation.LEFT;
				}
				else {
					taskBarLocation = TaskBarLocation.RIGHT;
				}
			}
			return taskBarLocation;
		}
	}
}
