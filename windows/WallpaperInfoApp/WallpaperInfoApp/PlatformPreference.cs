using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WallpaperInfoApp {

	class PlatformPreference {

        public static WallpaperInfoPreference getPreferences(WallpaperServiceInfo wpsi) {
            WallpaperInfoPreference wpref = new WallpaperInfoPreference();

            var root_path = Properties.Settings.Default["root_path"].ToString();
			if (root_path == "default") {
				root_path = ImageFileManager.getDefaultSourceRootPath();
				setPreference("root_path", root_path);
			}
			wpref.root_path = root_path;

			var themePref = System.Convert.ToInt32(Properties.Settings.Default["theme"]);
			if (themePref < 0 || themePref > Theme.all.intValue()) {
				themePref = 0;
				setPreference("theme", themePref.ToString());
			}
            wpref.theme = ThemeMethods.rawValue(themePref);
            wpref.custom_root = Properties.Settings.Default["custom_root"].ToString();
            wpref.custom_allow = Properties.Settings.Default["custom_allow"].ToString();
            wpref.custom_filter = Properties.Settings.Default["custom_filter"].ToString();
            wpref.pause = System.Convert.ToBoolean(Properties.Settings.Default["pause"]);
			var interval = System.Convert.ToInt32(Properties.Settings.Default["interval"]);
			if (interval < WallpaperServiceInfo._minInterval) {
				interval = WallpaperServiceInfo._defaultInterval;
				setPreference("interval", interval.ToString());
			}
            wpref.interval = interval;
            return wpref;        
		}

		public static void setPreference(String key, String value) {
            BPUtil.BPLog("Default Save : " + key + " = " + value);
			Properties.Settings.Default[key] = value;
			Properties.Settings.Default.Save();
		}
	}

    struct WallpaperInfoPreference {
        public String root_path;
        public Theme theme;
        public String custom_root;
        public String custom_allow;
        public String custom_filter;
        public bool pause;
        public int interval;
    }
}


