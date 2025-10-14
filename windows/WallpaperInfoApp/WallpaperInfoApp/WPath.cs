using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Text.RegularExpressions;

namespace WallpaperInfoApp {

    public class WPath {

        public String path;
        public String exif;
        public WPath(String _path, String _exif) {
            path = _path;
            exif = _exif;
        }
        public String coden() {
            String coden = (_platformRootPath.Length == 0) ? path : path.Replace(_platformRootPath, "");
            if (exif != "") {
                String extension = path.Substring(path.LastIndexOf('.'));
                return coden.Replace(extension, "%" + exif + extension);
            }
            return coden;
        }
        public String label() {
            String label = "";
            String rawImageName = BPUtil.getOnlyFileName(path);
            String imageName = Regex.Replace(rawImageName, @"^[0-9]{8}_[0-9]{6}@", "");
            if (exif != "") {
                label = BPUtil.getFolderName(path) + " / #" + exif + " | " + imageName;
            } else {
                label = BPUtil.getFolderName(path) + " / " + imageName;
            }
            label = label.Replace("#sn#", "~").Replace("#nd#", "!");
            return BPUtil.abbreviate(label, _maxImageDescriptionLength);
        }
        public static void setPlatformRootPath(String path) {
            int index = -1;
            if ((index = path.IndexOf("\\BP Wallpaper\\")) >= 0) {
                _platformRootPath = path.Substring(0, index);
            } else if ((index = path.IndexOf("\\BP Photo\\")) >= 0) {
                _platformRootPath = path.Substring(0, index);
            }
        }
        private static String _platformRootPath = "";
        // Windows specific. It must be less than 64
        private const int _maxImageDescriptionLength = 63;
    }
}
