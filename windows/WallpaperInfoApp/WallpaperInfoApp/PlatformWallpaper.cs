using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace WallpaperInfoApp {

    class PlatformWallpaper {

        public enum Style : int {
            Tiled,
            Centered,
            Stretched,
            Fit
        }

        public PlatformWallpaper() {
        }

		public bool setWallpaper(String path) {
			if (!BPUtil.fileExists(path)) {
				Console.WriteLine("Wallpaper " + path + " doesn't exist.");
				return false;
			}
			return applyWallpaperFromFile(path);
		}

		public void makeThumbnailFromScreenWallpaper() {
		}

        private bool applyWallpaperFromFile(String path, Style style = PlatformWallpaper.Style.Fit) {
			/*
			System.IO.Stream stream = new System.Net.WebClient().OpenRead(path);
			System.Drawing.Image img = System.Drawing.Image.FromStream(stream);
			String tempPath = Path.Combine(Path.GetTempPath(), "wallpaper.bmp");
			img.Save(tempPath, System.Drawing.Imaging.ImageFormat.Bmp);
			stream.Close();*/

			const int SPI_SETDESKWALLPAPER = 20;
			const int SPIF_UPDATEINIFILE = 0x01;
			const int SPIF_SENDWININICHANGE = 0x02;

			RegistryKey key = Microsoft.Win32.Registry.CurrentUser.OpenSubKey(@"Control Panel\Desktop", true);
			if (style == Style.Stretched) {
				key.SetValue(@"WallpaperStyle", 2.ToString());
				key.SetValue(@"TileWallpaper", 0.ToString());
			}

			if (style == Style.Centered) {
				key.SetValue(@"WallpaperStyle", 1.ToString());
				key.SetValue(@"TileWallpaper", 0.ToString());
			}

			if (style == Style.Tiled) {
				key.SetValue(@"WallpaperStyle", 1.ToString());
				key.SetValue(@"TileWallpaper", 1.ToString());
			}

            if (style == Style.Fit) {
                key.SetValue(@"WallpaperStyle", 6.ToString());
                key.SetValue(@"TileWallpaper", 0.ToString());
            }

			int ret = SystemParametersInfo(SPI_SETDESKWALLPAPER,
				0,
				path,
				SPIF_UPDATEINIFILE | SPIF_SENDWININICHANGE);

			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			if (!(ret == 0)) {
				Bitmap thumbnail = makeThumbnail(path);
				wpsi.setThumbnail(thumbnail);
				return true;
			}
            WallpaperWidgetProvider.updateLabelWidget("Set Wallpaper Error");
			wpsi.setThumbnail(null);			
			return false;
		}

		// TODO must consider exif rotation
		Bitmap makeThumbnail(String path) {
			if (path == null) {
				Console.WriteLine("Error with make thumbnial with null path");
			} else {
				try {
					Bitmap source = new Bitmap(path);
					int thumbnail_width = source.Width * _thumbnail_height / source.Height;
					Bitmap result = new Bitmap(thumbnail_width, _thumbnail_height);
					using (Graphics g = Graphics.FromImage(result)) {
						g.DrawImage(source, 0, 0, thumbnail_width, _thumbnail_height);
					}
					source.Dispose();
					return result;
				} catch {
					Console.WriteLine("Error with make thumbnial with " + path);
				}
			}
			return null;
		}

        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);

		static int _thumbnail_height = 150;
    }
}
