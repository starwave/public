package com.thirdwavesoft.wallpaperinfo;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Stack;

import android.os.FileObserver;
import android.util.Log;

public class PlatformFileObserver extends FileObserver {

	public PlatformFileObserver(String path) {
	    this(path, ALL_EVENTS);
	}
	
	public PlatformFileObserver(String path, int mask) {
		super(path, mask);
	    _sourceRootPath = path;
	    _mask = mask;
	}
	
	@Override
	public void startWatching() {
	    if (_fileWatcher != null) {
	    	Log.e(_TAG, "It's already watching files");
	    	return;
		}
		Runnable r = new Runnable() {
			public void run() {
				_fileWatcher = new ArrayList<SingleFileObserver>();
				Stack<String> stack = new Stack<String>();
				stack.push(_sourceRootPath);
				_sourcePaths = new WLinkedHashMap<String, String>();
				_exifPaths = new WLinkedHashMap<String, String>();
				synchronized(_sourcePaths) {
					while (!stack.empty()) {
						String parent = stack.pop();
						_fileWatcher.add(new SingleFileObserver(parent, _mask));
						File path = new File(parent);
						File[] files = path.listFiles();
						if (files == null) continue;
						for (int i = 0; i < files.length; ++i) {
							String fileName = files[i].getName();
							if (fileName.startsWith(".")) {
								continue;
							}
							// already filtered by hidden folder (.)
							// no need to check !files[i].getName().equals(".") && !files[i].getName().equals("..")
							if (files[i].isDirectory()) {
								stack.push(files[i].getPath());
							} else {
								int pos = fileName.lastIndexOf('.');
								if (pos >= 0) {
									if (fileName.substring(pos+1).toLowerCase().equals("jpg")) {
										String full_path = files[i].getPath();
										if (full_path.contains("/BP Photo/")) {
											_exifPaths.put(full_path, "");
										} else {
											_sourcePaths.put(full_path, "");
										}
									}
								}
							}
						}
					}
				}
				for (int i = 0; i < _fileWatcher.size(); i++) {
					_fileWatcher.get(i).startWatching();
				}
				if (_sourcePaths.size() > 0) {
					WPath.setPlatformRootPath(_sourcePaths.getWPath(0).path);
				}
				fileWatchingStarted(_sourcePaths);
				exifReadStart();
			}
		};
		new Thread(r).start();
	}

	@Override public void onEvent(int event, String file) {
		switch (event) {
			case PlatformFileObserver.CREATE:
				BPUtil.BPLog("%s", "File Change : CREATE " + file);
				addPathInternal(file);
				break;
			case PlatformFileObserver.MOVED_FROM:
				BPUtil.BPLog("%s", "File Change : MOVED_FROM " + file);
				onEvent(PlatformFileObserver.REMOVE, new WPath( file, ""));
				break;
			case PlatformFileObserver.MOVED_TO:
				BPUtil.BPLog("%s", "File Change : MOVED_TO " + file);
				addPathInternal(file);
				break;
			case PlatformFileObserver.DELETE:
				BPUtil.BPLog("%s", "File Change : DELETE " + file);
				onEvent(PlatformFileObserver.REMOVE, new WPath( file, ""));
				break;
			default:
				// TODO Modify should be handled for exif update later
				// public static int CHANGES_ONLY = CLOSE_WRITE | MOVE_SELF | MOVED_FROM;
				return;
		}
	}

	@Override
	public void stopWatching() {
	    if (_fileWatcher == null) return;
	    for (int i = 0; i < _fileWatcher.size(); ++i) {
			_fileWatcher.get(i).stopWatching();
		}
	    _fileWatcher.clear();
	    _fileWatcher = null;
	}

	private void addPathInternal(String path) {
		int pos = path.lastIndexOf('.');
		if (path.substring(pos+1).toLowerCase().equals("jpg")) {
			if (path.contains("/BP Photo/")) {
				String exif = BPUtil.getExifDescription(path);
				onEvent(PlatformFileObserver.ADD, new WPath(path, exif));
			} else {
				onEvent(PlatformFileObserver.ADD, new WPath(path, ""));
			}
		}
	}

	private void exifReadStart() {
		for (Map.Entry<String, String> wpath_entry : _exifPaths.entrySet()) {
			String path = wpath_entry.getKey();
			String exif = BPUtil.getExifDescription(path);
			_exifPaths.put(path, exif);
		}
		// In case there is only /BP Photo/ images
		if (_sourcePaths.size() == 0 && _exifPaths.size() > 0) {
			WPath.setPlatformRootPath(_exifPaths.getWPath(0).path);
		}
		exifReadFinished(_exifPaths);
	}

	private List<SingleFileObserver> _fileWatcher;
	private WLinkedHashMap<String, String> _sourcePaths;
	private WLinkedHashMap<String, String> _exifPaths;
	private String _sourceRootPath;
	public void onEvent(int event, WPath wpath) {}
	public void fileWatchingStarted(WLinkedHashMap<String, String> sourcePaths) {} // will be override
	public void exifReadFinished(WLinkedHashMap<String, String> exifFilePaths) {} // will be override

	// Following is already defined.
	// public static int MOVED_FROM = 0x00000040;
	// public static int MOVED_TO = 0x00000080;
	// public static int CREATE = 0x00000100;
	// public static int DELETE = 0x00000200;
	public final static int ADD = 0x00000180; // MOVED_TO | CREATE
	public final static int REMOVE = 0x00000240; // MOVED_FROM | DELETE

	// only for Android
	int _mask;
	private final static String _TAG = "PlatformFileObserver";

	private class SingleFileObserver extends FileObserver {
		private String _path;
		public SingleFileObserver(String path, int mask) {
			super(path, mask);
			_path = path;
		}
		// TODO must handle when new sub folder is created or sub folder is deleted.
		@Override
		public void onEvent(int event, String path) {
			String newPath = _path + "/" + path;
			PlatformFileObserver.this.onEvent(event, newPath);
		}
	}
}
