//
//  WallpaperTheme.swift
//  tromso
//
//  Created by Brad Park on 5/20/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation

enum Theme:Int {
	case default1 = 0
	case default2
	case custom
	case photo
	case recent
	case wallpaper
	case landscape
	case movie1
	case movie2
	case special1
	case special2
	case all
	
    var intValue: Int {
        return rawValue
    }
	
	var stringValue : String {
		switch self {
		case .default1: return "default1"
		case .default2: return "default2"
		case .custom: return "custom"
		case .photo: return "photo"
		case .recent: return "recent"
		case .wallpaper: return "wallpaper"
		case .landscape: return "landscape"
		case .movie1: return "movie1"
		case .movie2: return "movie2"
		case .special1: return "special1"
		case .special2: return "special2"
		case .all: return "all"
		}
	}
	
	var label:String {
		switch self {
		case .default1: return "Default"
		case .default2: return "Default+"
		case .custom: return "Custom"
		case .photo: return "Photo"
		case .recent: return "Recent"
		case .wallpaper: return "Wallpaper"
		case .landscape: return "Landscape"
		case .movie1: return "Movie"
		case .movie2: return "* Movie+ *"
		case .special1: return "* Special *"
		case .special2: return "* Special+ *"
		case .all: return "* All *"
		}
	}
}

class ThemeInfo: NSCopying {
	
	init(theme: Theme, root: String, allow: String, filter:String) {
		_theme = theme
		_root = root
		_allow = allow
		_filter = filter
		prepareTheme()
	}
	
	func copy(with zone: NSZone? = nil) -> Any {
		let copy = ThemeInfo(theme: _theme, root: _root, allow: _allow, filter:_filter)
		return copy
	}
	
    func isThemeImage(coden: String?) -> Bool {
        let wpsi = WallpaperServiceInfo.getInstance()
		if let validCoden = coden {
            // It must begins with root
            var underRoot = false
            for root in _rootsArray {
                if (wpsi.getOfflineMode()) {
                    if (validCoden.hasPrefix(root)) {
                        underRoot = true
                        break
                    }
                } else {
                    // Image orientation must match to current orientation for iOS devices
                    // ServerPath already has orientation prefix by ngorongoro function
                    #if os(iOS) || os(watchOS) || os(tvOS)
                        let pathPrefix = WallpaperServiceInfo.getInstance().getOrientation() + root
                    #elseif os(OSX)
                        let pathPrefix = root
                    #endif
                    if (validCoden.hasPrefix(pathPrefix)) {
                        underRoot = true
                        break
                    }
                }
            }
            if (!underRoot) {
                return false
            }
			// for case insensitive match
			let codenLowercase = validCoden.lowercased()
			// It must contains any of allow words unless allow is empty
			if (_allow != "") {
				var allowed = false
				for word in _allowWords {
					if (codenLowercase.contains(word)) {
						allowed = true
						break
					}
				}
				if (!allowed) {
					return false
				}
			}
			// It must not contain any of filter words
			for word in _filterWords {
				if (codenLowercase.contains(word)) {
					return false
				}
			}
		} else {
			return false
		}
        return true
    }
	
	func classifyPathsByTheme(source: WLinkedHashMap<String, String>,
									 theme: inout WLinkedHashMap<String, String>,
									 untheme: inout WLinkedHashMap<String, String>) {
		for path_dict in source {
			let path = path_dict.0
			let exif = path_dict.1
			let wpath = WPath(path: path, exif: exif)
			if (isThemeImage(coden: wpath.coden())) {
				theme.put(value: exif, forKey: path)
			} else {
				untheme.put(value: exif, forKey: path)
			}
		}
	}
	
	func getOption() -> String {
		var option:String = ""
		if (_theme == .custom) {
            option = " -r '" + _root + "' -a '" + _allow + "' -f '" + _filter + "'"
		}
		return option
	}
	
	func equals(_ themeInfo:ThemeInfo) -> Bool {
		if (themeInfo._theme == _theme) {
			if (_theme == .custom) {
				if (themeInfo.getOption() == getOption()) {
					return true
				} else {
					return false
				}
			} else {
				return true
			}
		}
		return false
	}
	
	private func prepareTheme() {
		_rootsArray = AppUtil.getWordsArray(wordString: _root)
		_allowWords = AppUtil.getWordsArray(wordString: _allow.lowercased())
		_filterWords = AppUtil.getWordsArray(wordString: _filter.lowercased())
	}
	
	func getNextThemeInfo() -> ThemeInfo {
		if (_theme == ThemeInfo._themes.last?._theme) {
			return ThemeInfo._themes[ThemeInfo._themes.first!._theme.intValue]
		}
		return ThemeInfo._themes[_theme.intValue + 1]
	}

	func getPrevousThemeInfo() -> ThemeInfo {
		if (_theme == ThemeInfo._themes.first?._theme) {
			return ThemeInfo._themes[ThemeInfo._themes.last!._theme.intValue]
		}
		return ThemeInfo._themes[_theme.intValue - 1]
	}

	class func getThemeInfo(theme:Theme) -> ThemeInfo {
		return _themes[theme.intValue]
	}
	
    class func getLabels() -> Array<String> {
        var labels = Array<String>()
		for themeInfo in _themes {
			labels.append(themeInfo._theme.label)
        }
        return labels
    }

	class func setCustomConfig(root: String, allow:String, filter:String) -> ThemeInfo {
		_themes[Theme.custom.intValue]._root = root
		_themes[Theme.custom.intValue]._allow = allow
		_themes[Theme.custom.intValue]._filter = filter
		_themes[Theme.custom.intValue].prepareTheme()
		return _themes[Theme.custom.intValue]
    }
	
	class func parseCustomConfig(_ customConfigString:String) -> ThemeInfo {
		let configWords = customConfigString.components(separatedBy: ";")
		let root = (configWords.count > 0) ? configWords[0] : ThemeInfo._default_custom_root
		let allow = (configWords.count > 1) ? configWords[1] : ThemeInfo._default_custom_allow
		let filter = (configWords.count > 2) ? configWords[2] : ThemeInfo._default_custom_filter
		return ThemeInfo(theme: Theme.custom, root: root, allow: allow, filter: filter)
	}
	
	class func setCustomConfig(customConfigString:String) -> ThemeInfo {
		let wpti = parseCustomConfig(customConfigString)
		return setCustomConfig(root: wpti._root, allow:wpti._allow, filter:wpti._filter)
	}
    
    private static func getRecentYears() -> String {
        let year = Calendar.current.component(.year, from: Date())
        let recentyears = String(format: "/BP Photo/%d/|/BP Photo/%d/|/BP Photo/%d/|/BP Photo/%d/|/BP Photo/%d/",
                                 year - 4, year - 3, year - 2, year - 1, year)
        return recentyears
    }

    public static let _default_custom_root = "/"
    public static let _default_custom_allow = ""
    public static let _default_custom_filter = "#nd#|#sn#"

	private static var _themes = [
		ThemeInfo(theme: .default1,
						  root: "/", allow: "", filter: "#nd#|#sn#|/People/"),
		ThemeInfo(theme: .default2,
						  root: "/", allow: "", filter: "#nd#|#sn#" ),
		ThemeInfo(theme: .custom,
						  root: _default_custom_root, allow: _default_custom_allow, filter: _default_custom_filter ),
		ThemeInfo(theme: .photo,
						  root: "/BP Photo/", allow: "", filter: "#nd#|#sn#" ),
		ThemeInfo(theme: .recent,
                          root: getRecentYears(), allow: "", filter: "#nd#|#sn#" ),
		ThemeInfo(theme: .wallpaper,
						  root: "/BP Wallpaper/", allow: "", filter: "#nd#|#sn#" ),
		ThemeInfo(theme: .landscape,
						  root: "/BP Wallpaper/", allow: "/Landscapes/|/Nature/|/USA/|/Architecture/|/Korea/", filter: "#nd#|#sn#" ),
		ThemeInfo(theme: .movie1,
						  root: "/BP Wallpaper/", allow: "/Animations/|/Movies/|/TVShow/", filter: "#nd#|#sn#" ),
		ThemeInfo(theme: .movie2,
						  root: "/BP Wallpaper/", allow: "/Animations/|/Movies/|/TVShow/|/Performance/", filter: "" ),
		ThemeInfo(theme: .special1,
						  root: "/BP Wallpaper/", allow: "#nd#|#sn#", filter: "/Animations|Anime/" ),
		ThemeInfo(theme: .special2,
						  root: "/", allow: "/People/|#nd#|#sn#", filter: "" ),
		ThemeInfo(theme: .all,
						  root: "/", allow: "", filter: "" )
	]
    
	var _theme : Theme = .default1;
	var _root = String();
	var _allow = String();
	var _filter = String();
	
    private var _rootsArray : Array<String> = [];
    private var _allowWords : Array<String> = [];
    private var _filterWords : Array<String> = [];
	
}

