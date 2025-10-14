package com.thirdwavesoft.wallpaperinfo;

import android.os.Environment;
import android.util.Log;
import java.io.*;
import java.net.Socket;

public class BPFileSender {

    public void copyGalleryAlbum(String host, String albumName, WallpaperServiceHandler.GalleryCopyCallback galleryCopyCallback) {
        if (_isCopyingFiles) {
            galleryCopyCallback.callback("It's still copying gallery files.");
            return;
        }
        File folderDCIM = new File(Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DCIM), albumName);
        File[] files = folderDCIM.listFiles((dir, name) ->
                name.toLowerCase().endsWith(".jpg") || name.toLowerCase().endsWith(".mp4")|| name.toLowerCase().endsWith(".png"));
        if (files == null || files.length == 0) {
            galleryCopyCallback.callback("No files found or unable to access directory.");
            return;
        }
        _isCopyingFiles = true;
        // network code must be in background process
        new Thread(new Runnable() {
            @Override
            public void run() {
                if (!sendAlbumName(host, albumName)) {
                    galleryCopyCallback.callback("network error while sending album name.");
                    _isCopyingFiles = false;
                    return;
                }
                _albumName = albumName;
                int i = 0;
                for (File file : files) {
                    String message = String.format("Sending %d of %d: %s.", ++i, files.length, file.getName());
                    Log.i(_TAG, message);
                    galleryCopyCallback.callback(message);
                    sendFile(host, file);
                }
                galleryCopyCallback.callback(String.format("%d gallery file(s) are sent successfully.", files.length));
                _isCopyingFiles = false;
            }
        }).start();
    }

    private boolean sendAlbumName(String host, String albumName) {
        try (Socket socket = new Socket(host, SERVER_PORT);
            DataOutputStream dos = new DataOutputStream(socket.getOutputStream())) {
            // send command = 1; album Name
            dos.writeLong(1);
            // Send file name
            writeString(dos, albumName);
            Log.i(_TAG, "Album Name " + albumName + " sent successfully");
            return true;
        } catch (IOException e) {
            e.printStackTrace();
        }
        return false;
    }

    private void sendFile(String host, File file) {
        try (Socket socket = new Socket(host, SERVER_PORT);
            DataOutputStream dos = new DataOutputStream(socket.getOutputStream());
            FileInputStream fis = new FileInputStream(file)) {
                // send command = 0; file
                dos.writeLong(0);
                // Send file name
                writeString(dos, _albumName + "/" + file.getName());
                // Send file size
                dos.writeLong(file.length());
                // Send file content
                byte[] buffer = new byte[4096];
                int bytesRead;
                while ((bytesRead = fis.read(buffer)) != -1) {
                    dos.write(buffer, 0, bytesRead);
            }
            Log.i(_TAG, "File " + file.getName() + " sent successfully");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void writeString(DataOutputStream dos, String string) {
        try {
            byte[] utfBytes = string.getBytes("UTF-8");
            long nameLength = (long)utfBytes.length;
            dos.writeLong(nameLength);
            dos.write(utfBytes,0, utfBytes.length);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    private static final int SERVER_PORT = 8081;
    private String _albumName = "Camera";
    private static boolean _isCopyingFiles = false;
    private final static String _TAG = "BPFileSender";
}