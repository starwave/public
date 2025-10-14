package com.thirdwavesoft.wallpaperinfo;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.Serializable;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

import android.os.Handler;
import android.util.Log;

public class ImageFileManager {
	
	public ImageFileManager() {
		resetFiles();
	}

	synchronized public void resetFiles() {
		_themeReady = false;
		_unclassifiedPaths = new WLinkedHashMap<String, String>(); // will be overriden
		_wallpaperPaths = new WLinkedHashMap<String, String>(); // will be overriden
		_themePaths = new WLinkedHashMap<String, String>();
		_unthemePaths = new WLinkedHashMap<String, String>();
		_usedPaths = new WLinkedHashMap<String, String>();
		_lastUsedPaths = new WLinkedHashMap<String, String>();
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		wpsi.setLastUsedPaths(_lastUsedPaths);
		stopWatching();
	}

	public void stopWatching() {
		_writeInterrupt = true;
		waitForListFileWriting();
		synchronized (ImageFileManager.this) {
			if (_fileObserver != null) {
				_fileObserver.stopWatching();
				_fileObserver = null;
			}
		}
	}
	
	public void setSourceRootPath(String sourceRootPath) {
		BPUtil.BPLog("%s", "setSourceRootPath = " + sourceRootPath);
		resetFiles();
		_writeInterrupt = false;
		_sourceRootPath = sourceRootPath;
		if (!BPUtil.fileExists(_sourceRootPath)) {
			return;
		}
		if (readListCache()) {
			synchronized(ImageFileManager.this) {
				BPUtil.BPLog("ImageFileManager.readListCache.");
				WPath.setPlatformRootPath(_unclassifiedPaths.getWPath(0).path);
				classifySourceByTheme();
			}
			_themeReady = true;
		}
		_fileObserver = new PlatformFileObserver(_sourceRootPath)  {
            @Override
            public void onEvent(int event, WPath wpath) {
            	switch (event) {
            	case PlatformFileObserver.ADD:
    				addWPath(wpath);
    				break;
            	case PlatformFileObserver.REMOVE:
    				removePath(wpath.path);
    				break;
            	default:
            		return;
            	}
            }
			@Override
			public void fileWatchingStarted(WLinkedHashMap<String, String> sourcePaths) {
				BPUtil.BPLog("ImageFileManager.fileWatchingStarted.");
				_wallpaperPaths = sourcePaths;
				writeListCache(_wallpaperPaths, _wallpaperListCacheFile);
				synchronized(ImageFileManager.this) {
					// compare count to determine to use it over cache list.
					if (_wallpaperPaths.size() > getTotalImageCount()) {
						replaceCacheWithRealPaths(_wallpaperPaths);
					}
				}
			}
			@Override
			public void exifReadFinished(WLinkedHashMap<String, String> exifFilePaths) {
				BPUtil.BPLog("ImageFileManager.exifReadFinished.");
				_unclassifiedPaths = exifFilePaths;
				writeListCache(_unclassifiedPaths, _photoListCacheFile);
				synchronized(ImageFileManager.this) {
					if (_usingListCache) {
						replaceCacheWithRealPaths(_unclassifiedPaths, _wallpaperPaths);
					} else {
						classifySourceByTheme();
					}
				}
			}
		};
		// it's background scanning. _themeReady flag will protect to access the file source during scanning
		// It will call fileWatchingStarted when it's done
        _fileObserver.startWatching();
	}
	
	synchronized private WPath getRandomPathFromSource() {
		if (_themePaths == null || _usedPaths == null) {
			Log.e(_TAG, "_sourcePaths shouldn't be null.");
			return null;
		}
		if (_themePaths.size() <= 0) {
			// Rewind from the beginning
			rewindSource();
			if (_themePaths.size() <= 0) {
				// when there is no images;
				Log.d(_TAG, "There is no theme image in entire source.");
				return null;
			}
		}
		// pick new image path from source
		Random r = new Random();
		int index = r.nextInt(_themePaths.size());
		WPath newWPath = _themePaths.getWPath(index);
		// remove from source path
		_themePaths.remove(newWPath.path);
		// (in case source is small) Check if new path is still in last used path, then remove it to avoid the loop.
		_lastUsedPaths.remove(newWPath.path);
		// add to last used path
		_lastUsedPaths.put(newWPath.path, newWPath.exif);
		// mainatain size for _lastUsedPaths
		if (_lastUsedPaths.size() > WallpaperService._maxLastUsedPaths) {
			_lastUsedPaths.removeAt(0);
		}
		// add to used path
		_usedPaths.put(newWPath.path, newWPath.exif);
		return newWPath;
	}
	
	synchronized public WPath retrievePathFromSource(WPath pivotWPath, int offset) {
		if (pivotWPath == null) {
			return getRandomPathFromSource();
		}
		if (_lastUsedPaths == null) {
			Log.e(_TAG, "_lastUsedPaths shouldn't be null.");
			return null;
		}
		int index = _lastUsedPaths.firstIndexOf(pivotWPath.path);
		if (index < 0) {                                        // No matching image
			if (offset == -1) {
				Log.d(_TAG,"shouldn't happen when no index but offset is -1");
			}
			return getRandomPathFromSource();
		} else if (index + offset < 0) {                        // get previous at the first
			return _lastUsedPaths.getWPath(0);
		} else if (index + offset < _lastUsedPaths.size())      // get within the range
			return _lastUsedPaths.getWPath(index + offset);
		return getRandomPathFromSource();                     // get next at the last
	}

	synchronized private void addWPath(WPath wpath) {
		if (_themePaths == null) {
			Log.e(_TAG, "_sourcePaths shouldn't be null.");
			return;
		}
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		ThemeInfo themeInfo = wpsi.getThemeInfo();
		if (themeInfo.isThemeImage(wpath.coden())) {
			_themePaths.put(wpath.path, wpath.exif);
		} else {
			_unthemePaths.put(wpath.path, wpath.exif);
		}
	}
	
	synchronized private void removePath(String path) {
		if (_themePaths == null || _usedPaths == null) {
			Log.e(_TAG, "_sourcePaths shouldn't be null.");
			return;
		}
		_lastUsedPaths.remove(path);
		_themePaths.remove(path);
		_unthemePaths.remove(path);
		_usedPaths.remove(path);
	}

	private void classifySourceByTheme() {
		WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		wpsi.getThemeInfo().classifyPathsByTheme(
				_unclassifiedPaths,
				_themePaths,
				_unthemePaths);
	}

	private void rewindSource() {
		_themeReady = false;
		BPUtil.BPLog("rewindSource is called.");
		_unclassifiedPaths = _usedPaths;
		_usedPaths = new WLinkedHashMap<String, String>();
		classifySourceByTheme();
		_themeReady = true;
	}

	void prepareSourceForTheme() {
		_themeReady = false;
		final WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		final ThemeInfo requestedThemeInfo = wpsi.getThemeInfo();
		BPUtil.BPLog("prepareSourceForTheme is called with " + requestedThemeInfo._theme.stringValue());
		final Handler handler = new Handler();
		handler.postDelayed(new Runnable() {
			@Override
			public void run() {
				// Log.i(_TAG, "prepareSourceForTheme enters postDelayed with " + requestedThemeInfo._theme.stringValue());
				synchronized(this) {
					// Log.i(_TAG, "prepareSourceForTheme enters synchronized with " + requestedThemeInfo._theme.stringValue());
					if (requestedThemeInfo.equals(wpsi.getThemeInfo())) {
						// Log.i(_TAG, "prepareSourceForTheme execution starts with " + requestedThemeInfo._theme.stringValue());
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
			}
		}, 1100);
	}

	boolean isThemeReady() {
		return _themeReady;
	}

	public synchronized String getImageStat(String path) {
		int index = _usedPaths.size() + _unthemePaths.size();
		int i = _lastUsedPaths.firstIndexOf(path);
		if (i >= 0) {   // current image is in the mid offset
			index = index - _lastUsedPaths.size() + i;
		}
		return new Integer(index + 1).toString()  + " of " + new Integer(getTotalImageCount()).toString();
	}

	public synchronized int getTotalImageCount () {
		return _usedPaths.size() + _themePaths.size() + _unthemePaths.size();
	}

	public static String getDefaultSourceRootPath() {
		// TODO get android default image folder (camera) instead of the following paths
		String [] candidates = {
				"/storage/emulated/0/CloudStation/BP Wallpaper", // Nexus 10, Galaxy S10
		};
		for (int i=0;i<candidates.length;i++) {
			if (BPUtil.fileExists(candidates[i])) {
				BPUtil.BPLog("%s", "getDefaultSourceRootPath = " + candidates[i]);
				return candidates[i];
			}
		}
		return candidates[0];
	}

	private boolean readListCache() {
		_usingListCache = false;
		_unclassifiedPaths.clear();
		if (BPUtil.fileExists(_wallpaperListCacheFile)) {
			waitForListFileWriting();
			try (FileInputStream fis = new FileInputStream(new File(_wallpaperListCacheFile));
				InputStreamReader isr = new InputStreamReader(fis, StandardCharsets.UTF_8);
				BufferedReader reader = new BufferedReader(isr)) {
				String path = reader.readLine();
				if (path.equals(_sourceRootPath)) {
					String line;
					while ((line = reader.readLine()) != null) {
						String[] path_exif = line.split("\t");
						_unclassifiedPaths.put(path_exif[0], "");
					}
				}
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		if (BPUtil.fileExists(_photoListCacheFile)) {
			waitForListFileWriting();
			try (FileInputStream fis = new FileInputStream(new File(_photoListCacheFile));
				 InputStreamReader isr = new InputStreamReader(fis, StandardCharsets.UTF_8);
				 BufferedReader reader = new BufferedReader(isr)) {
				String path = reader.readLine();
				if (path.equals(_sourceRootPath)) {
					String line;
					while ((line = reader.readLine()) != null) {
						String[] path_exif = line.split("\t");
						String exif = path_exif.length > 1 ? path_exif[1] : "";
						_unclassifiedPaths.put(path_exif[0], exif);
					}
				}
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		_usingListCache = _unclassifiedPaths.size() > 0;
		return _usingListCache;
	}

	public class WriteListCacheThread extends Thread {
		WriteListCacheThread(WLinkedHashMap<String, String> paths, String listCacheFile) {
			_paths = paths;
			_listCacheFile = listCacheFile;
			_shortlistCacheFile = BPUtil.getOnlyFileName(_listCacheFile);
		}
		public void run() {
			BPUtil.BPLog("writeListCache %s started", _shortlistCacheFile);
			try (OutputStreamWriter writer =
						 new OutputStreamWriter(new FileOutputStream(new File(_listCacheFile + ".tmp")), StandardCharsets.UTF_8)) {
				writer.write(_sourceRootPath + "\n");
				for (int index = 0; index < _paths.size(); index++) {
					if (_writeInterrupt) {
						BPUtil.BPLog("writeListCache is interrupted for %s.", _shortlistCacheFile);
						break;
					}
					WPath wpath = _paths.getWPath(index);
					writer.write(wpath.path + "\t" + wpath.exif + "\n");
				}
			} catch (IOException e) {
				e.printStackTrace();
			}
			if (!_writeInterrupt) {
				if (BPUtil.fileExists(_listCacheFile)) {
					new File(_listCacheFile).delete();
				}
				new File(_listCacheFile + ".tmp").renameTo(new File(_listCacheFile));
			} else {
				new File(_listCacheFile+ ".tmp").delete();
			}
			BPUtil.BPLog("writeListCache %s ended", _shortlistCacheFile);
		}
		WLinkedHashMap<String, String> _paths;
		String _listCacheFile, _shortlistCacheFile;
	}

	// null to delete
	private void writeListCache(WLinkedHashMap<String, String> paths, String listCacheFile) {
		if (paths != null) {
			waitForListFileWriting();
			_writeFileThread = new Thread(new WriteListCacheThread(paths, listCacheFile));
			_writeFileThread.start();
		}
	}

	private void waitForListFileWriting() {
		if (_writeFileThread != null) {
			BPUtil.BPLog("waitForListFileWriting started");
			try {
				_writeFileThread.join();
			} catch (Exception e) {
				e.printStackTrace();
			}
			BPUtil.BPLog("waitForListFileWriting ended");
		}
	}

	private void replaceCacheWithRealPaths(WLinkedHashMap<String, String> realPaths) {
		replaceCacheWithRealPaths(realPaths, null);
	}

	private void replaceCacheWithRealPaths(WLinkedHashMap<String, String> realPaths, WLinkedHashMap<String, String> realPaths2) {
		_themeReady = false;
		_unclassifiedPaths = realPaths;
		_themePaths.clear();
		_unthemePaths.clear();
		classifySourceByTheme();
		if (realPaths2 != null) {
			_unclassifiedPaths = realPaths2;
			classifySourceByTheme();
		}
		for (int index = 0; index < _usedPaths.size(); index++) {
			WPath wpath = _usedPaths.getWPath(index);
			// remove from _themePaths which was already used from cache
			_themePaths.remove(wpath.path);
		}
		_usingListCache = false;
		_themeReady = true;
	}

	private PlatformFileObserver _fileObserver = null;
	private WLinkedHashMap<String, String> _unclassifiedPaths = null;
	private WLinkedHashMap<String, String> _wallpaperPaths = null;
	private WLinkedHashMap<String, String> _themePaths = null;
	private WLinkedHashMap<String, String> _unthemePaths = null;
    private WLinkedHashMap<String, String> _usedPaths = null;
    private WLinkedHashMap<String, String> _lastUsedPaths = null;
    private String _sourceRootPath;
    private boolean _themeReady = false;
	private boolean _usingListCache = false;
	private boolean _writeInterrupt = false;
	private Thread _writeFileThread = null;
	final private String _wallpaperListCacheFile = PlatformInfo.getDocumentsDir() + ".wallpaper_list.txt";
	final private String _photoListCacheFile = PlatformInfo.getDocumentsDir() + ".photo_list.txt";
    private final static String _TAG = "ImageFileManager";
}

class WLinkedHashMap<k,v> extends LinkedHashMap<k,v> {
	public WPath getWPath(int index) {
		String path = (String)this.keySet().toArray()[index];
		String exif = (String)this.get(path);
		return new WPath(path, exif);
	}
	public int firstIndexOf(k key) {
		List<k> pathListforIndexAccess = new ArrayList<k>(this.keySet());
		return pathListforIndexAccess.indexOf(key);
	}
	public void removeAt(int index) {
		String path = (String)this.keySet().toArray()[index];
		this.remove(path);
	}
	public void addFirst(k key, v value) {
		WLinkedHashMap<k,v> newmap = (WLinkedHashMap<k,v>)this.clone();
		this.clear();
		this.put((k)key, (v)value);
		this.putAll((Map<k,v>)newmap);
	}
}

class WLinkedHashMapWrapper <WLinkedHashMap extends Serializable> implements Serializable {
	private WLinkedHashMap wrapped;
	public WLinkedHashMapWrapper(WLinkedHashMap wrapped) {
		this.wrapped = wrapped;
	}
	public WLinkedHashMap get() {
		return wrapped;
	}
}