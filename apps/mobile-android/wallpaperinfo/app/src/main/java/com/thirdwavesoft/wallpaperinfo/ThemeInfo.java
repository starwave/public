package com.thirdwavesoft.wallpaperinfo;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Map;

enum Theme {
    default1,
    default2,
    custom,
    photo,
    recent,
    wallpaper,
    landscape,
    movie1,
    movie2,
    special1,
    special2,
    all;

    static Theme rawValue(int index) {
        if (index >=0 && index < _themeEnumValues.length) {
            return _themeEnumValues[index];
        }
        return default1;
    }

    int intValue() {
        return ordinal();
    }

    String stringValue() {
        return _stringValues[ordinal()];
    }

    String label() {
        return _labels[ordinal()];
    }

    private static Theme[] _themeEnumValues = values();

    private String[] _stringValues = {
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

    private String[] _labels = {
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

    ThemeInfo(Theme Theme, String Root, String Allow, String Filter) {
        _theme = Theme;
        _root = Root;
        _allow = Allow;
        _filter = Filter;
        prepareTheme();
    }

    boolean isThemeImage(String coden) {
        if (coden == null) {
            return false;
        }
        // It must begins with root
        boolean underRoot = false;
        for (int i = 0; i < _rootsArray.size(); i++) {
            String root = _rootsArray.get(i);
            if (coden.startsWith(root)) {
                underRoot = true;
                break;
            }
        }
        if (!underRoot) {
            return false;
        }
        // for case insensitive match
        String codenLowercase = coden.toLowerCase();
        // It must contains any of allow words unless allow is empty
        if (!_allow.isEmpty()) {
            boolean allowed = false;
            for (int i = 0; i < _allowWords.size(); i++) {
                String word = _allowWords.get(i);
                if (codenLowercase.contains(word)) {
                    allowed = true;
                    break;
                }
            }
            if (!allowed) {
                return false;
            }
        }
        // It must not contain any of filter words
        for (int i = 0; i < _filterWords.size(); i++) {
            String word =  _filterWords.get(i);
            if (codenLowercase.contains(word)) {
                return false;
            }
        }
      return true;
    }

    void classifyPathsByTheme(WLinkedHashMap<String, String> source,
                              WLinkedHashMap<String, String> theme,
                              WLinkedHashMap<String, String> untheme) {
        for (Map.Entry<String, String> path_entry : source.entrySet()) {
            String path = path_entry.getKey();
            String exif = path_entry.getValue();
            WPath wpath = new WPath(path, exif);
            if (isThemeImage(wpath.coden())) {
                theme.put(path, exif);
            } else {
                untheme.put(path, exif);
            }
        }
    }

    String getOption() {
        String option = "";
        if (_theme == Theme.custom ) {
            option = " -r '" + _root + "' -a '" + _allow + "' -f '" + _filter + "'";
        }
        return option;
    }

    boolean equals(ThemeInfo themeInfo) {
        if (themeInfo._theme == _theme) {
            if (_theme == Theme.custom) {
                if (themeInfo.getOption().equals(getOption())) {
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
        _rootsArray = AppUtil.getWordsArray(_root);
        _allowWords = AppUtil.getWordsArray(_allow.toLowerCase());
        _filterWords = AppUtil.getWordsArray(_filter.toLowerCase());
    }

    ThemeInfo getNextThemeInfo() {
        if (_theme == _themes[_themes.length - 1]._theme) {
            return ThemeInfo._themes[ThemeInfo._themes[0]._theme.intValue()];
        }
        return ThemeInfo._themes[_theme.intValue() + 1];
    }

    ThemeInfo getPrevousThemeInfo() {
        if (_theme == _themes[0]._theme) {
            return ThemeInfo._themes[ThemeInfo._themes[_themes.length - 1]._theme.intValue()];
        }
        return ThemeInfo._themes[_theme.intValue() - 1];
    }

    static ThemeInfo getThemeInfo(Theme theme) {
        return _themes[theme.intValue()];
    }

    static ArrayList<String> getLabels() {
        ArrayList<String> labels = new ArrayList<String>();
        for (int i = 0; i <  _themes.length; i++) {
            ThemeInfo themeInfo = _themes[i];
            labels.add(themeInfo._theme.label());
        }
        return labels;
    }

    static ThemeInfo setCustomConfig(String root, String allow, String filter) {
        _themes[Theme.custom.intValue()]._root = root;
        _themes[Theme.custom.intValue()]._allow = allow;
        _themes[Theme.custom.intValue()]._filter = filter;
        _themes[Theme.custom.intValue()].prepareTheme();
        return _themes[Theme.custom.intValue()];
    }

    static ThemeInfo parseCustomConfig(String customConfigString) {
        //  Java doens't add trailing empty strings as array elemenet, so adding safe_guard to support empty string
        int n = 0;
        for (int i = 0; i < customConfigString.length(); i++) {
            if (customConfigString.charAt(i) == ';') {
                n++;
            }
        }
        if (n == 2 && customConfigString.charAt(customConfigString.length() -1) == ';') {
            customConfigString += ";safe_guard";
        }
        ArrayList<String> configWords = new ArrayList<String>(Arrays.asList(customConfigString.split(";")));
        // don't allow empty string for root which may come from emptry string for whole config string
        String root = (configWords.size() > 0 && !customConfigString.isEmpty()) ? configWords.get(0) : ThemeInfo._default_custom_root;
        String allow = (configWords.size() > 1) ? configWords.get(1) : ThemeInfo._default_custom_allow;
        String filter = (configWords.size() > 2) ? configWords.get(2) : ThemeInfo._default_custom_filter;
        return new ThemeInfo(Theme.custom, root, allow, filter);
    }

    static ThemeInfo setCustomConfig(String customConfigString) {
        ThemeInfo wpti = parseCustomConfig(customConfigString);
        return setCustomConfig(wpti._root, wpti._allow, wpti._filter);
    }

    private static String getRecentYears() {
        int year = Calendar.getInstance().get(Calendar.YEAR);
        String recentyears = String.format("/BP Photo/%d/|/BP Photo/%d/|/BP Photo/%d/|/BP Photo/%d/|/BP Photo/%d/",
                year - 4, year - 3, year - 2, year - 1, year);
        return recentyears;
    }

    public final static String _default_custom_root = "/";
    public final static String _default_custom_allow = "";
    public final static String _default_custom_filter = "#nd#|#sn#";

    private static ThemeInfo _themes[] = {
            new ThemeInfo(Theme.default1,
                    "/", "", "#nd#|#sn#|/People/"),
            new ThemeInfo(Theme.default2,
                    "/", "", "#nd#|#sn#" ),
            new ThemeInfo(Theme.custom,
                    ThemeInfo._default_custom_root, ThemeInfo._default_custom_allow, ThemeInfo._default_custom_filter ),
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
                    "/BP Wallpaper/", "#nd#|#sn#", "/Animations|Anime/" ),
            new ThemeInfo(Theme.special2,
                    "/", "/People/|#nd#|#sn#", "" ),
            new ThemeInfo(Theme.all,
                    "/", "", "" )
    };

    public Theme _theme = Theme.default1;
    public String _root;
    public String _allow;
    public String _filter;

    private ArrayList<String> _rootsArray = new ArrayList<String>();
    private ArrayList<String> _allowWords = new ArrayList<String>();
    private ArrayList<String> _filterWords = new ArrayList<String>();

    private final static String _TAG = "WallpaperThemeInfo";
}
