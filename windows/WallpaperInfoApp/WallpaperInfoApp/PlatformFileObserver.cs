using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Permissions;
using System.Text;
using System.Threading.Tasks;

namespace WallpaperInfoApp {

    class PlatformFileObserver {

		public PlatformFileObserver(String path) {
			_sourceRootPath = path;
		}

		~PlatformFileObserver() {
			stopWatching();
		}

		public void startWatching() {
			Task.Run(() => {
                _interrupt = false; 
                Stack<String> stack = new Stack<String>();
				stack.Push(_sourceRootPath);
				_sourcePaths = new WLinkedHashMap<String, String>();
				_exifPaths = new WLinkedHashMap<String, String>();
				while (stack.Count > 0) {
					String parent = stack.Pop();
					string[] filePaths = Directory.GetFiles(parent, "*.*", SearchOption.AllDirectories);
					foreach (var filePath in filePaths) {
						if (Path.GetFileName(filePath).StartsWith(".")) {
							continue;
						}
						FileAttributes attr = File.GetAttributes(filePath);
						if (attr.HasFlag(FileAttributes.Directory)) {
							stack.Push(filePath);
						} else {
							if (String.Equals(Path.GetExtension(filePath), ".jpg", StringComparison.OrdinalIgnoreCase)) {
								if (filePath.Contains("\\BP Photo\\")) {
									_exifPaths.Put(filePath, "");
								} else {
									_sourcePaths.Put(filePath, "");
								}
							}
						}
					}
				};

				// Create a new FileSystemWatcher and set its properties.
				_fileWatcher = new FileSystemWatcher();
				_fileWatcher.Path = _sourceRootPath;

				// Watch for changes in LastAccess and LastWrite times, and
				// the renaming of files or directories.
				_fileWatcher.NotifyFilter = NotifyFilters.LastAccess
										| NotifyFilters.LastWrite
										| NotifyFilters.FileName
										| NotifyFilters.DirectoryName;

				// Only watch image files.
				_fileWatcher.Filter = "*.jpg";
				_fileWatcher.IncludeSubdirectories = true;

				// Add event handlers.
				_fileWatcher.Created += new FileSystemEventHandler(OnCreated);
				_fileWatcher.Changed += new FileSystemEventHandler(OnChanged);
				_fileWatcher.Deleted += new FileSystemEventHandler(OnDeleted);
				_fileWatcher.Renamed += new RenamedEventHandler(OnRenamed);

				// Begin watching.
                BPUtil.BPLog("PlatformFileObserver Watching " + _sourceRootPath);
				_fileWatcher.EnableRaisingEvents = true;

				if (_sourcePaths.Count > 0) {
					WPath.setPlatformRootPath(_sourcePaths.getWPath(0).path);
				}
				if (fileWatchingStarted != null) {
					fileWatchingStarted(this, new PathsEventArgs(_sourcePaths));
				}
				exifReadStart();
			});
		}

		public void stopWatching() {
            _interrupt = true;
			if (_fileWatcher == null) return;
			if (_fileWatcher.EnableRaisingEvents) {
				_fileWatcher.EnableRaisingEvents = false;
			}
			_fileWatcher.Dispose();
			_fileWatcher = null;
		}

        private void addPathInternal(String path) {

        }

		private void exifReadStart() {
			// Must make the clone since modifying object while iteration is not allowed.
			LinkedList<Tuple<String, String>> items = new LinkedList<Tuple<String, String>>(_exifPaths.Items());
			foreach (var item in items) {
                if (_interrupt) {
                    BPUtil.BPLog("exifReadStart is interrupted.");
                    return; // must return without calling callback since it's not complete scan
                } 
                String path = item.Item2;
                String exif = BPUtil.getExifDescription(path);
				_exifPaths.Put(path, exif);
			}
			// In case there is only /BP Photo/ images
			if (_sourcePaths.Count == 0 && _exifPaths.Count > 0) {
				WPath.setPlatformRootPath(_exifPaths.getWPath(0).path);
			}
			if (exifReadFinished != null) {
				exifReadFinished(this, new PathsEventArgs(_exifPaths));
			}
		}

		public WLinkedHashMap<String, String> getSourcePaths() {
			lock (_sourcePaths) {
				return _sourcePaths;
			}
	    }

		// Wrap event invocations inside a protected virtual method
        // to allow derived classes to override the event invocation behavior
		protected virtual void onFileChange(int file_event, String path) {
			if (String.Equals(Path.GetExtension(path), ".jpg", StringComparison.OrdinalIgnoreCase)) {
				// _onEvent will be null if there are no subscribers
				FileChangeEventArgs e;
				if (onEvent != null) {
					switch (file_event) {
						case PlatformFileObserver.CREATE:
						case PlatformFileObserver.MOVED_TO:
							if (path.Contains("\\BP Photo\\")) {
								if (waitForFileReleaase(path)) {
									String exif = BPUtil.getExifDescription(path);
									e = new FileChangeEventArgs(PlatformFileObserver.ADD, new WPath(path, exif));
									onEvent(this, e);
									break;
								} else {
                                    BPUtil.BPLog("File: {0} is locked to read exif.", path);
								}
							}
							e = new FileChangeEventArgs(PlatformFileObserver.ADD, new WPath(path, ""));
							onEvent(this, e);
							break;
						case PlatformFileObserver.DELETE:
						case PlatformFileObserver.MOVED_FROM:
							e = new FileChangeEventArgs(PlatformFileObserver.REMOVE, new WPath(path, ""));
							onEvent(this, e);
							break;
						default:
							break;
					}
				}
			}
		}

		private void OnCreated(object source, FileSystemEventArgs e) {
            BPUtil.BPLog("File: {0} {1}", e.FullPath, e.ChangeType);
			onFileChange(PlatformFileObserver.CREATE, e.FullPath);
		}

		private void OnChanged(object source, FileSystemEventArgs e) {
			// TODO Modify should be handled for exif update later
			// Console.WriteLine("File: {0} {1}", e.FullPath, e.ChangeType);
		}

		private void OnDeleted(object source, FileSystemEventArgs e) {
            BPUtil.BPLog("File: {0} {1}", e.FullPath, e.ChangeType);
			onFileChange(PlatformFileObserver.DELETE, e.FullPath);
		}

		private void OnRenamed(object source, RenamedEventArgs e) {
            BPUtil.BPLog("File: {0} renamed to {1}", e.OldFullPath, e.FullPath);
			onFileChange(PlatformFileObserver.MOVED_FROM, e.OldFullPath);
			onFileChange(PlatformFileObserver.MOVED_TO, e.FullPath);
		}

        // only for windows since it crashes when it tries to get exif with newly added file
        bool waitForFileReleaase(string fullPath) {
            int numTries = 0;
            while (true) {
                ++numTries;
                try {
                    // Attempt to open the file exclusively.
                    using (FileStream fs = new FileStream(fullPath, FileMode.Open, FileAccess.ReadWrite,
                        FileShare.None, 100)) {
                        fs.ReadByte();
                        // If we got this far the file is ready
                        break;
                    }
                } catch {
                    BPUtil.BPLog("{0} is locked at {1} trial.", fullPath, numTries);
                    if (numTries > 10) {
                        return false;
                    }
                    // TODO : Consecutive CREATE event with same file causes crashes during exif read due to file access exception from different process
                    // Wait for the lock to be released
                    System.Threading.Thread.Sleep(1000);
                }
            }
            return true;
        }

		private FileSystemWatcher _fileWatcher = null;
		private WLinkedHashMap<String, String> _sourcePaths;
		private WLinkedHashMap<String, String> _exifPaths;
		private String _sourceRootPath;
        private bool _interrupt = true;
		public event EventHandler<FileChangeEventArgs> onEvent;
		public event EventHandler<PathsEventArgs> fileWatchingStarted;
		public event EventHandler<PathsEventArgs> exifReadFinished;

		public const int MOVED_FROM = 0x00000040;
		public const int MOVED_TO = 0x00000080;
		public const int CREATE = 0x00000100;
		public const int DELETE = 0x00000200;
		public const int ADD = 0x00000180; // MOVED_TO | CREATE
		public const int REMOVE = 0x00000240; // MOVED_FROM | DELETE
    }

	public class FileChangeEventArgs : EventArgs {
		public FileChangeEventArgs(int file_event, WPath wpath) {
			_event = file_event;
			_wpath = wpath;
		}
		public int _event;
		public WPath _wpath;
	}

	public class PathsEventArgs : EventArgs {
		public PathsEventArgs(WLinkedHashMap<String, String> paths) {
			_paths = paths;
		}
		public WLinkedHashMap<String, String> _paths;
	}
}
