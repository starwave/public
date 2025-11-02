package com.thirdwavesoft.wallpaperinfo;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.text.Format;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Locale;

import android.media.ExifInterface;
import android.os.Environment;
import android.util.Log;

import com.thirdwavesoft.exif.UnicodeExifInterface;

public class BPUtil {

    public static String getExifDescription(String path) {
        try {
            String imageDescription = null;
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                ExifInterface exifInterface = new ExifInterface(path);
                byte[] imageDescriptionByte = new byte[0];
                imageDescriptionByte = exifInterface.getAttributeBytes(ExifInterface.TAG_IMAGE_DESCRIPTION);
                if (imageDescriptionByte != null) {
                    imageDescription = new String(imageDescriptionByte, StandardCharsets.UTF_8);
                }
            } else {
                // use UnicodeExifInterface to encode UTF8 encoding for Android P or below OS
                // TAG_IMAGE_DESCRIPTION is ASCII encoding by default
                UnicodeExifInterface unicodeExifInterface = new UnicodeExifInterface(path);
                imageDescription = unicodeExifInterface.getAttribute(UnicodeExifInterface.TAG_IMAGE_DESCRIPTION);
            }
            if (imageDescription != null) {
                imageDescription = imageDescription.trim();
                if (imageDescription.length() > 0) {
                    return imageDescription;
                }
            }
        }  catch (IOException e) {
            e.printStackTrace();
        }
        return "";
    }

    public static String getOnlyFileName(String path) {
        String str = new File(path).getName();
        int index = str.lastIndexOf('.');
        if (index > 0) {
            return str.substring(0, index);
        } else {
            return str;
        }
    }

    public static String getFolderName(String path) {
        return 	new File(path).getParentFile().getName();
    }

    public static String abbreviate(String str, int maxWidth) {
        if (str == null) {
            return "";
        }
        String leader = "...";
        if (str.length() <= maxWidth) {
            return str;
        }
        int headCharactersCount = (int)(Math.ceil((float)(maxWidth - leader.length()) / 2.0));
        int tailCharactersCount = (int)(Math.floor((float)(maxWidth - leader.length()) / 2.0));
        return str.substring(0, headCharactersCount) + leader + str.substring(str.length() - tailCharactersCount);
	}

	public static boolean fileExists(String path) {
        return new File(path).exists();
    }

	public static int BPLog(String format, Object... args ) {
		final String TAG = "BPLog";
        try {

            File logFile = new File(_logFilePath);
            if (!logFile.exists()) {
                logFile.createNewFile();
            }
            Format formatter = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss", Locale.US);
            String dt_string = formatter.format(Calendar.getInstance().getTime());
            if (!dt_string.startsWith(_previousDate) && !_previousDate.equals("")) {
                String archiveLogFile = _logFilePath.replace(".log", "-" +
                        _previousDate.replace("/", "") + ".log");
                logFile.renameTo(new File(archiveLogFile));
                BPUtil.bashCommand("find " + _logDir + " -mtime +10 -type f -delete");
            }
            _previousDate = dt_string.substring(0, 10);
            String msg = String.format(format, args);
            Log.i(TAG, msg);
            FileWriter fstream = new FileWriter(_logFilePath, true);
            BufferedWriter out = new BufferedWriter(fstream);
            out.write(dt_string + " " + msg + "\n");
            out.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return 0;
	}

    public static String getStringFromFile (String filePath) {
        synchronized (_fileLock) {
            try {
                File file = new File(filePath);
                FileInputStream fin = new FileInputStream(file);
                String ret = PlatformInfo.convertStreamToString(fin);
                fin.close();
                return ret;
            } catch (IOException e) {
                return "";
            }
        }
    }

    public static void storeStringToFile (String filePath, String contents) {
        synchronized (_fileLock) {
            File file = new File(filePath);
            FileOutputStream stream;
            try {
                stream = new FileOutputStream(file);
                stream.write(contents.getBytes());
                stream.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public static String getHomeDirectory() {
        return new String(Environment.getExternalStorageDirectory().getPath());
    }

    public static String bashCommand(String command) {
        StringBuffer output = new StringBuffer();
        Process p;
        try {
            p = Runtime.getRuntime().exec(command);
            p.waitFor();
            BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()));
            String line = "";
            while ((line = reader.readLine())!= null) {
                output.append(line + "n");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        String response = output.toString();
        return response;
    }
    private static String _previousDate = "";
    private static final Object _fileLock = new Object();
    private static final String _bp_log_path = "wallpaperinfo.log";
    private final static String _logDir = PlatformInfo.getLogDir();
    private final static String _logFilePath = _logDir + File.separatorChar + _bp_log_path;
}
