using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Threading;

namespace WallpaperInfoApp {

	class ImageFileManager {

		public ImageFileManager() {
			resetFiles();
		}

		void resetFiles() {
            lock (_self) {
                _themeReady = false;
                _unclassifiedPaths = new WLinkedHashMap<String, String>(); // will be overriden
				_wallpaperPaths = new WLinkedHashMap<String, String>(); // will be overriden
                _themePaths = new WLinkedHashMap<String, String>();
                _unthemePaths = new WLinkedHashMap<String, String>();
                _usedPaths = new WLinkedHashMap<String, String>();
                _lastUsedPaths = new WLinkedHashMap<String, String>();
                WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
                wpsi.setLastUsedPaths(_lastUsedPaths);
            }
            stopWatching();
        }

        public void stopWatching() {
            _writeInterrupt = true;
            waitForListFileWriting();
            lock(_self) {
                if (_fileObserver != null) {
                    _fileObserver.stopWatching();
                    _fileObserver = null;
                }
            }
        }

		public void setSourceRootPath(String sourceRootPath) {
			BPUtil.BPLog("ImageFileManager.setSourceRootPath");
			resetFiles();
            _writeInterrupt = false;
			_sourceRootPath = sourceRootPath;
            if (!BPUtil.fileExists(sourceRootPath)) {
                return;
            }
			if (readListCache()) {
				lock (_self) {
					BPUtil.BPLog("ImageFileManager.readListCache.");
					WPath.setPlatformRootPath(_unclassifiedPaths.getWPath(0).path);
					classifySourceByTheme();
				}
				_themeReady = true;
			}
			_fileObserver = new PlatformFileObserver(_sourceRootPath);
			_fileObserver.onEvent += (object sender, FileChangeEventArgs e) => {
            	switch (e._event) {
            	case PlatformFileObserver.ADD:
    				addWPath(e._wpath);
    				break;
            	case PlatformFileObserver.REMOVE:
					removePath(e._wpath.path);
    				break;
            	default:
            		return;
            	}
			};
			_fileObserver.fileWatchingStarted += (object sender, PathsEventArgs e) => {
				BPUtil.BPLog("ImageFileManager.fileWatchingStarted.");
				_wallpaperPaths = e._paths;
				writeListCache(_wallpaperPaths, _wallpaperListCacheFile);
				lock (_self) {
					// compare count to determine to use it over cache list.
					if (_wallpaperPaths.Count > getTotalImageCount()) {
						replaceCacheWithRealPaths(_wallpaperPaths);
					}
                }
			};
			_fileObserver.exifReadFinished += (object sender, PathsEventArgs e) => {
                BPUtil.BPLog("ImageFileManager.exifReadFinished.");
				_unclassifiedPaths = e._paths;
				writeListCache(_unclassifiedPaths, _photoListCacheFile);
				lock (_self) {
					if (_usingListCache) {
                        replaceCacheWithRealPaths(_unclassifiedPaths, _wallpaperPaths);
                    } else {
                        classifySourceByTheme();
                    }
	            }
			};
			// it's background scanning. _themeReady flag will protect to access the file source during scanning
			// It will call fileWatchingStarted when it's done
		    _fileObserver.startWatching();
		}

		private WPath getRandomPathFromSource() {
            lock (_self) {
                if (_themePaths == null || _usedPaths == null) {
                    BPUtil.BPLog("_sourcePaths shouldn't be null.");
                    return null;
                }
                if (_themePaths.Count <= 0) {
					// Rewind from the beginning
					rewindSource();
					if (_themePaths.Count <= 0) {
                        // when there is no images;
                        BPUtil.BPLog("There is no theme image in entire source.");
                        return null;
                    }
                }
                // pick new image path from source
                Random r = new Random();
				int index = r.Next(_themePaths.Count);
				WPath wpath = _themePaths.getWPath(index);
				// remove file from source if it doesn't exist
				while (!BPUtil.fileExists(wpath.path)) {
					_themePaths.Remove(wpath.path);
					index = r.Next(_themePaths.Count);
					wpath = _themePaths.getWPath(index);
				};
                // remove from source path
                _themePaths.Remove(wpath.path);
                // (in case source is small) Check if new path is still in last used path, then remove it to avoid the loop.
				_lastUsedPaths.Remove(wpath.path);
                // add to last used path
				_lastUsedPaths.Put(wpath.path, wpath.exif);
                // mainatain size for _lastUsedPaths
                if (_lastUsedPaths.Count > WallpaperService._maxLastUsedPaths) {
                    _lastUsedPaths.RemoveAt(0);
                }
                // add to used path
				_usedPaths.Put(wpath.path, wpath.exif);
				return wpath;
            }
		}

		public WPath retrievePathFromSource(WPath pivotWPath, int offset) {
            lock (_self) {
                if (pivotWPath == null) {
                    return getRandomPathFromSource();
                }
                if (_lastUsedPaths == null) {
                    BPUtil.BPLog("_lastUsedPaths shouldn't be null.");
                    return null;
                }
				int index = _lastUsedPaths.FirstIndexOf(pivotWPath.path);
                if (index < 0) {                                        // No matching image
                    if (offset == -1) {
                        BPUtil.BPLog("shouldn't happen when no index but offset is -1");
                    }
                    return getRandomPathFromSource();
                } else if (index + offset < 0) {                        // get previous at the first
                    return _lastUsedPaths.getWPath(0);
                } else if (index + offset < _lastUsedPaths.Count)      // get within the range
                    return _lastUsedPaths.getWPath(index + offset);
                return getRandomPathFromSource();                     // get next at the last
            }
		}

		private void addWPath(WPath wpath) {
            lock (_self) {
                if (_themePaths == null) {
                    BPUtil.BPLog("_sourcePaths shouldn't be null.");
                    return;
                }
				WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
				ThemeInfo themeInfo = wpsi.getThemeInfo();
				if (themeInfo.isThemeImage(wpath.coden())) {
					_themePaths.Put(wpath.path, wpath.exif);
				} else {
					_unthemePaths.Put(wpath.path, wpath.exif);
				}
            }			
		}
	
		private void removePath(String path) {
            lock (_self) {
                if (_themePaths == null || _usedPaths == null) {
                    BPUtil.BPLog("_sourcePaths shouldn't be null.");
                    return;
                }
                _lastUsedPaths.Remove(path);
				_themePaths.Remove(path);
				_unthemePaths.Remove(path);
				_usedPaths.Remove(path);
            }
		}

		private void classifySourceByTheme() {
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			wpsi.getThemeInfo().classifyPathsByTheme(
					_unclassifiedPaths,
					ref _themePaths,
					ref _unthemePaths);
		}

		private void rewindSource() {
			_themeReady = false;
            BPUtil.BPLog("rewindSource is called.");
			_unclassifiedPaths = _usedPaths;
			_usedPaths = new WLinkedHashMap<String, String>();
			classifySourceByTheme();
			_themeReady = true;
		}

		public void prepareSourceForTheme() {
			_themeReady = false;
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			ThemeInfo requestedThemeInfo = wpsi.getThemeInfo();
            BPUtil.BPLog("prepareSourceForTheme is called with " + requestedThemeInfo._theme.stringValue());
			Task.Delay(1100).ContinueWith(_ => {
				//Console.WriteLine("prepareSourceForTheme enters dispatchqueue with " + requestedThemeInfo._theme.stringValue());
				lock (_self) {
					//Console.WriteLine("prepareSourceForTheme enters synchronized with " + requestedThemeInfo._theme.stringValue());
					if (requestedThemeInfo.equals(wpsi.getThemeInfo())) {
						//Console.WriteLine("prepareSourceForTheme execution starts with " + requestedThemeInfo._theme.stringValue());
						_unclassifiedPaths = _themePaths;
						WLinkedHashMap<String, String> backupPaths = _unthemePaths;
						_themePaths = new WLinkedHashMap<String, String>();
						_unthemePaths = new WLinkedHashMap<String, String>();
						classifySourceByTheme();
						_unclassifiedPaths = backupPaths;
						classifySourceByTheme();
						_themeReady = true;
                        BPUtil.BPLog("prepareSourceForTheme is done with " + requestedThemeInfo._theme.stringValue());
					}
				}
			});
		}

		public bool isThemeReady() {
			return _themeReady;
		}

		public String getImageStat(String path) {
            lock (_self) {
				int index = _usedPaths.Count + _unthemePaths.Count;
                int i = _lastUsedPaths.FirstIndexOf(path);
				if (i >= 0) { // current image is in the mid offset
                    index = index - _lastUsedPaths.Count + i;
                }
                return (index + 1).ToString() + " of " + getTotalImageCount().ToString();
            }			
		}

		public int getTotalImageCount () {
            lock (_self) {
				return _usedPaths.Count + _themePaths.Count + _unthemePaths.Count;
            }
		}

		public static String getDefaultSourceRootPath() {
			return Environment.GetFolderPath(Environment.SpecialFolder.MyPictures); 
		}

		private bool readListCache() {
  			_usingListCache = false;
			_unclassifiedPaths.RemoveAll();
			if (BPUtil.fileExists(_wallpaperListCacheFile)) {
                waitForListFileWriting();
				using (StreamReader reader = new StreamReader(_wallpaperListCacheFile, Encoding.UTF8)) {
					var path = reader.ReadLine();
					if (path == _sourceRootPath) {
						String line;
						while ((line = reader.ReadLine()) != null) {
							String[] path_exif = line.Split('\t');
							_unclassifiedPaths.Put(path_exif[0], "");
						}
					}
				}
			}
			if (BPUtil.fileExists(_photoListCacheFile)) {
				using (StreamReader reader = new StreamReader(_photoListCacheFile, Encoding.UTF8)) {
                    waitForListFileWriting();
					var path = reader.ReadLine();
					if (path == _sourceRootPath) {
						String line;
						while ((line = reader.ReadLine()) != null) {
							String[] path_exif = line.Split('\t');
							String exif = path_exif.Length > 1 ? path_exif[1] : "";
							_unclassifiedPaths.Put(path_exif[0], exif);
						}
					}
				}
			}
			_usingListCache = _unclassifiedPaths.Count > 0;
			return _usingListCache;
		}

		// null to delete
		private void writeListCache(WLinkedHashMap<String, String> paths, String listCacheFile) {
			if (paths != null) {
                waitForListFileWriting();
                _writeFileTask = Task.Run(() => {
                    BPUtil.BPLog("writeListCache {0} started", listCacheFile);
					using (FileStream fs = new FileStream(listCacheFile+".tmp", FileMode.OpenOrCreate)) {
						using (StreamWriter writer = new StreamWriter(fs, Encoding.UTF8)) {
							writer.WriteLine(_sourceRootPath);
							for (int index = 0; index < paths.Count; index++) {
                                if (_writeInterrupt) {
                                    BPUtil.BPLog("writeListCache is interrupted for {0}.", listCacheFile);
                                    break;
                                }
								WPath wpath = paths.getWPath(index);
								writer.WriteLine(wpath.path + "\t" + wpath.exif);
							}
                        }
					}
                    if (!_writeInterrupt) {
                        if (BPUtil.fileExists(listCacheFile)) {
                            File.Delete(listCacheFile);
                        } 
                        File.Move(listCacheFile + ".tmp", listCacheFile);
                    } else {
                        File.Delete(listCacheFile + ".tmp");
                    }
                    BPUtil.BPLog("writeListCache {0} ended", listCacheFile);
				});
			}
		}

        private void waitForListFileWriting() {
            if (_writeFileTask != null) {
                BPUtil.BPLog("waitForListFileWriting started");
                Task.WaitAll(_writeFileTask);
                BPUtil.BPLog("waitForListFileWriting ended");
            }
        }

        private void replaceCacheWithRealPaths(WLinkedHashMap<String, String> realPaths, WLinkedHashMap<String, String> realPaths2 = null) {
			_themeReady = false;
			_unclassifiedPaths = realPaths;
			_themePaths.RemoveAll();
			_unthemePaths.RemoveAll();
			classifySourceByTheme();
            if (realPaths2 != null) {
                _unclassifiedPaths = realPaths2;
                classifySourceByTheme();
            }
			for (int index = 0; index < _usedPaths.Count; index++) {
				WPath wpath = _usedPaths.getWPath(index);
				// remove from _themePaths which was already used from cache
				_themePaths.Remove(wpath.path);
			}
			_usingListCache = false;
			_themeReady = true;
			WallpaperWidgetProvider.updateLabelWidget(text: "Image list is updated.");
		}

		private PlatformFileObserver _fileObserver = null;
		private WLinkedHashMap<String, String> _unclassifiedPaths = null;
		private WLinkedHashMap<String, String> _wallpaperPaths = null;
		private WLinkedHashMap<String, String> _themePaths = null;
		private WLinkedHashMap<String, String> _unthemePaths = null;
		private WLinkedHashMap<String, String> _usedPaths = null;
		private WLinkedHashMap<String, String> _lastUsedPaths = null;
		private String _sourceRootPath;
		private bool _themeReady = false;
		private bool _usingListCache = false;
        private bool _writeInterrupt = false;
        private Task _writeFileTask = null;
		private static String _wallpaperListCacheFile = ".wallpaper_list.txt";
		private static String _photoListCacheFile = ".photo_list.txt";
		// only for Windows
		private object _self = new object(); // for lock object
	}

	public class WLinkedHashMap<K, V> : LinkedHashMap<String, String> {
		public WPath getWPath(int index) {
			String path = this.Get(index);
			String exif = this[path];
			return new WPath(path, exif);
		}
	}
}
