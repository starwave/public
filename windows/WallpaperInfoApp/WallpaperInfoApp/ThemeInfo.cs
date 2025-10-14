using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WallpaperInfoApp {

	public enum Theme {
		default1 = 0,
		default2 = 1,
		custom = 2,
		photo = 3,
		recent = 4,
		wallpaper = 5,
		landscape = 6,
		movie1 = 7,
		movie2 = 8,
		special1 = 9,
		special2 = 10,
		all = 11
	}

	static class ThemeMethods {
		public static Theme rawValue(this Theme t) {
			return Theme.default1;
		}
		public static Theme rawValue(int index) {
			if (index >= 0 && index < _themeEnumValues.Length) {
				return _themeEnumValues[index];
			}
			return Theme.default1;
		}
		public static int intValue(this Theme t) {
			return (int)t;
		}
		public static String stringValue(this Theme t) {
			return _stringValues[t.intValue()];
		}
		public static String label(this Theme t) {
			return _labels[t.intValue()];
		}
		private static Theme[] _themeEnumValues = (Theme[])Enum.GetValues(typeof(Theme));
		private static String[] _stringValues = {
				"default1",
				"default2",
				"custom",
				"photo",
				"recent",
				"wallpaper",
				"landscape",
				"movie1",
				"movie2",
				"special1",
				"special2",
				"all"
		};
		private static String[] _labels = {
				"Default",
				"Default+",
				"Custom",
				"Photo",
				"Recent",
				"Wallpaper",
				"Landscape",
				"Movie",
				"* Movie+ *",
				"* Special *",
				"* Special+ *",
				"* All *"
		};
	}

	class ThemeInfo {

		public ThemeInfo(Theme Theme, String Root, String Allow, String Filter) {
			_theme = Theme;
			_root = Root;
			_allow = Allow;
			_filter = Filter;
			prepareTheme();
		}

		public bool isThemeImage(String coden) {
			if (coden == null) {
				return false;
			}
			// It must begins with root
			bool underRoot = false;
			for (int i = 0; i < _rootsArray.Count; i++) {
				String root = _rootsArray[i];
				if (coden.StartsWith(root)) {
					underRoot = true;
					break;
				}
			}
			if (!underRoot) {
				return false;
			}
			// for case insensitive match
			String imagePath = coden.ToLower();
			// It must contains any of allow words unless allow is empty
			if (!_allow.Equals("")) {
				bool allowed = false;
				for (int i = 0; i < _allowWords.Count; i++) {
					String word = _allowWords[i];
					if (imagePath.Contains(word)) {
						allowed = true;
						break;
					}
				}
				if (!allowed) {
					return false;
				}
			}
			// It must not contain any of filter words
			for (int i = 0; i < _filterWords.Count; i++) {
				String word =  _filterWords[i];
				if (imagePath.Contains(word)) {
					return false;
				}
			}
			return true;
		}

		public void classifyPathsByTheme(WLinkedHashMap<String, String> source,
								  ref WLinkedHashMap<String, String> theme,
								  ref WLinkedHashMap<String, String> untheme) {
			LinkedList<Tuple<String, String>> items = source.Items();
			foreach (var item in items) {
				String path = item.Item2;
				String exif = item.Item1;
				WPath wpath = new WPath(path, exif);
				if (isThemeImage(wpath.coden())) {
					theme.Put(path, exif);
				} else {
					untheme.Put(path, exif);
				}
			}
		}

		public String getOption() {
			String option = "";
			if (_theme == Theme.custom ) {
                option = " -r '" + _root + "' -a '" + _allow + "' -f '" + _filter + "'";
			}
			return option;
		}

		public bool equals(ThemeInfo themeInfo) {
			if (themeInfo._theme == _theme) {
				if (_theme == Theme.custom) {
					if (themeInfo.getOption() == getOption()) {
						return true;
					} else {
						return false;
					}
				} else {
					return true;
				}
			}
			return false;
		}

		private void prepareTheme() {
			// important - replace slash to backslash here to handle all windows style path correctly
			_rootsArray = AppUtil.getWordsArray(_root.Replace('/', '\\'));
			_allowWords = AppUtil.getWordsArray(_allow.Replace('/', '\\').ToLower());
			_filterWords = AppUtil.getWordsArray(_filter.Replace('/', '\\').ToLower());
		}

		public ThemeInfo getNextThemeInfo() {
			if (_theme == _themes[_themes.Length - 1]._theme) {
				return ThemeInfo._themes[ThemeInfo._themes[0]._theme.intValue()];
			}
			return ThemeInfo._themes[_theme.intValue() + 1];
		}

		public ThemeInfo getPrevousThemeInfo() {
			if (_theme == _themes[0]._theme) {
				return ThemeInfo._themes[ThemeInfo._themes[_themes.Length - 1]._theme.intValue()];
			}
			return ThemeInfo._themes[_theme.intValue() - 1];
		}

		public static ThemeInfo getThemeInfo(Theme theme) {
			return _themes[theme.intValue()];
		}

		public static List<String> getLabels() {
			List<String> labels = new List<String>();
			for (int i = 0; i <  _themes.Length; i++) {
				ThemeInfo themeInfo = _themes[i];
				labels.Add(themeInfo._theme.label());
			}
			return labels;
		}

		public static ThemeInfo setCustomConfig(String root, String allow, String filter) {
			_themes[Theme.custom.intValue()]._root = root;
			_themes[Theme.custom.intValue()]._allow = allow;
			_themes[Theme.custom.intValue()]._filter = filter;
			_themes[Theme.custom.intValue()].prepareTheme();
			return _themes[Theme.custom.intValue()];
		}

		static ThemeInfo parseCustomConfig(String customConfigString) {
			List<String> configWords = new List<String>(customConfigString.Split(';'));
			String root = (configWords.Count > 0 && !customConfigString.Equals("") ) ? configWords[0] : ThemeInfo._default_custom_root;
			String allow = (configWords.Count > 1) ? configWords[1] : ThemeInfo._default_custom_allow;
			String filter = (configWords.Count > 2) ? configWords[2] : ThemeInfo._default_custom_filter;
			return new ThemeInfo(Theme.custom, root, allow, filter);
		}

		public static ThemeInfo setCustomConfig(String customConfigString) {
			ThemeInfo wpti = parseCustomConfig(customConfigString);
			return setCustomConfig(wpti._root, wpti._allow, wpti._filter);
		}

        private static string getRecentYears() {
            int year = DateTime.Now.Year;
            String recentyears = string.Format("/BP Photo/{0}/|/BP Photo/{1}/|/BP Photo/{2}/|/BP Photo/{3}/|/BP Photo/{4}/", year - 4, year - 3, year - 2, year - 1, year);
            return recentyears;
        }

        public static String _default_custom_root = "/";
        public static String _default_custom_allow = "";
        public static String _default_custom_filter = "#nd#|#sn#";

		private static ThemeInfo[] _themes = {
				new ThemeInfo(Theme.default1,
						"/", "", "#nd#|#sn#|/People/"),
				new ThemeInfo(Theme.default2,
						"/", "", "#nd#|#sn#" ),
				// do not refer static variable's value to initialize static variable since it causes null and crash (looks like dot net bug)
				new ThemeInfo(Theme.custom,
						"/", "", "#nd#|#sn#" ),
				new ThemeInfo(Theme.photo,
						"/BP Photo/", "", "#nd#|#sn#" ),
				new ThemeInfo(Theme.recent,
						getRecentYears(), "", "#nd#|#sn#" ),
				new ThemeInfo(Theme.wallpaper,
						"/BP Wallpaper/", "", "#nd#|#sn#" ),
				new ThemeInfo(Theme.landscape,
						"/BP Wallpaper/", "/Landscapes/|/Nature/|/USA/|/Architecture/|/Korea/", "#nd#|#sn#" ),
				new ThemeInfo(Theme.movie1,
						"/BP Wallpaper/", "/Animations/|/Movies/|/TVShow/", "#nd#|#sn#" ),
				new ThemeInfo(Theme.movie2,
						"/BP Wallpaper/", "/Animations/|/Movies/|/TVShow/|/Performance/", "" ),
				new ThemeInfo(Theme.special1,
						"/BP Wallpaper/", "#nd#|#sn#", "/Anime/" ),
				new ThemeInfo(Theme.special2,
						"/", "/People/|#nd#|#sn#", "" ),
				new ThemeInfo(Theme.all,
						"/", "", "" )
		};

		public Theme _theme = Theme.default1;
		public String _root;
		public String _allow;
		public String _filter;

		private List<String> _rootsArray = new List<String>();
		private List<String> _allowWords = new List<String>();
		private List<String> _filterWords = new List<String>();
	}
}
