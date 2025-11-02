package com.thirdwavesoft.wallpaperinfo;

import java.io.Serializable;

public class WPath implements Serializable {
    public String path;
    public String exif;
    WPath(String Path, String Exif) {
        path = Path;
        exif = Exif;
    }
    public String coden() {
        String coden = path.replace(_platformRootPath, "");
        if (!exif.isEmpty()) {
            String extension = path.substring(path.lastIndexOf('.'));
            return coden.replace(extension, "%" + exif + extension);
        }
        return coden;
    }
    public String label() {
        String label = "";
        String rawImageName = BPUtil.getOnlyFileName(path);
        String imageName = rawImageName.replaceAll("^[0-9]{8}_[0-9]{6}@", "");
        if (!exif.isEmpty()) {
            label = BPUtil.getFolderName(path) + " / #" + exif + " | " + imageName;
        } else {
            label = BPUtil.getFolderName(path) + " / " + imageName;
        }
        label = label.replace("#sn#", "~").replace("#nd#", "!");
        return BPUtil.abbreviate(label, _maxImageDescriptionLength);
    }
    public static void setPlatformRootPath(String path) {
        int index = -1;
        if ((index = path.indexOf("/BP Wallpaper/")) >= 0) {
            _platformRootPath = path.substring(0, index);
        } else if ((index = path.indexOf("/BP Photo/")) >= 0) {
            _platformRootPath = path.substring(0, index);
        }
    }
    private static String _platformRootPath = "";
    private static final int _maxImageDescriptionLength = 50;
}