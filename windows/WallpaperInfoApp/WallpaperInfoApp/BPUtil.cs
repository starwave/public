using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Diagnostics;
using System.Windows.Forms;

namespace WallpaperInfoApp {

	public class BPUtil {

        public static string getExifDescription(String path) {
            ExifInterface exifInterface = new ExifInterface(path);
            String exif = exifInterface.getAttribute(ExifInterface.Attr.ImageDescription);
            if (exif!=null) {
                exif = exif.Trim();
            } else {
                exif = "";
            }
            return exif;
        }

		public static String getOnlyFileName(String path) {
			return Path.GetFileNameWithoutExtension(path);
		}

        public static String getFolderName(String path) {
            if (path == null) {
                return "";
            }
            FileInfo file_info = new FileInfo(path);
            string parentFolder = getOnlyFileName(file_info.DirectoryName);
            return parentFolder;
        }

        public static String abbreviate(String str, int maxWidth) {
			if (str == null) {
				return "";
			}
			String leader = "...";
			if (str.Length <= maxWidth) {
				return str;
			}
			int headCharactersCount = (int)(Math.Ceiling((float)(maxWidth - leader.Length) / 2.0));
			int tailCharactersCount = (int)(Math.Floor((float)(maxWidth - leader.Length) / 2.0));
			return str.Substring(0, headCharactersCount) + leader + str.Substring(str.Length - tailCharactersCount);
		}

		public static bool fileExists(String path) {
			return (File.Exists(path) || Directory.Exists(path));
		}

        public static void BPLog(String format, params object[] args) {
            var logs = (args.Length > 0) ? String.Format(format, args) : format;
            var dt_string = DateTime.Now.ToString("yyyy/MM/dd H:mm:ss");
            Console.WriteLine(dt_string + " " + logs);
            var logFile = getHomeDirectory() + "/logs/WallpaperInfoApp.log";
            lock (_logLock) {
                using (StreamWriter w = File.AppendText(logFile)) {
                    w.WriteLine(dt_string + " " + logs);
                }
            }
        }

		public static String getStringFromFile(String filePath) {
			lock (_fileLock) {
				try {
					return System.IO.File.ReadAllText(filePath, Encoding.UTF8);
				} catch (Exception e) {
					Console.WriteLine("Error in getStringFromFile: " + e.Message);
					return "";
				}
			}
		}

		public static void storeStringToFile(String filePath, String contents) {
			lock (_fileLock) {
				try {
					System.IO.File.WriteAllText(filePath, contents, Encoding.UTF8);
				} catch (Exception e) {
					Console.WriteLine("Error in storeStringToFile: " + e.Message);
				}
			}
		}

        public static String getHomeDirectory() {
            return Environment.GetFolderPath(Environment.SpecialFolder.UserProfile) + Path.DirectorySeparatorChar;
        }

        public static void showImageFile(String path) {
            Process.Start("explorer.exe", "/select, \"" + path + "\"");
        }

        public static void showImagePreview(String path) {
            Process.Start(path);
        }

        public static bool altKeyPressed() {
            return (Control.ModifierKeys == Keys.Alt);
        }

        public static bool shiftKeyPressed() {
            return (Control.ModifierKeys == Keys.Shift);
        }

        public static String bashCommand(String command) {
            Process myProcess = new Process();
            ProcessStartInfo startInfo = new ProcessStartInfo("bash.exe");
            startInfo.CreateNoWindow = true;
            startInfo.UseShellExecute = false;
            startInfo.RedirectStandardOutput = true;
            startInfo.RedirectStandardError = true;
            // TODO command should be quote, slash escaped
            startInfo.Arguments = " -c '" + command + "'";
            myProcess.StartInfo = startInfo;
            myProcess.Start();
            String result = "";
            using (StreamReader reader = myProcess.StandardOutput) {
                result = reader.ReadToEnd();
            }
            return result;
        }

		private static Object _fileLock = new Object();
        private static Object _logLock = new Object();
	}
}
