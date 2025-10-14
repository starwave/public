using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace WallpaperInfoApp {

	class MSG {
		public const int REQUEST_INFO = 1;
		public const int PAUSE = 2;
		public const int PREVIOUS = 3;
		public const int NEXT = 4;
		public const int SET_ROOT = 5;
		public const int ACTIVITY_REPORT = 6;
		public const int SET_WALLPAPER = 7;
		public const int SET_INTERVAL = 8;
		public const int SERVICE_INFO = 9;
		public const int SET_THEME = 10;
		public const int CUSTOM_CONFIG = 11;
		public const int PREVIOUS_THEME = 12;
		public const int NEXT_THEME = 13;
		public const int TOGGLE_PAUSE = 14;
	    public const int SET_MODE = 15;
	    public const int SET_SAVER = 16;
	    public const int SET_SAVERTIME = 17;
	    public const int OPEN_SETTING_UI = 18;
	}

	class AppUtil {

		public static List<String> getWordsArray(String wordString) {
			if (wordString.Equals("")) {
				return new List<String>();
			} else {
				return new List<String>(wordString.Split('|'));
			}
		}

	    public static bool isMyServiceRunning()  {
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			return wpsi.getWallpaperService().isStarted();
		}

		private static List<String> _allowedFilters = new List<String>();
	}
}
