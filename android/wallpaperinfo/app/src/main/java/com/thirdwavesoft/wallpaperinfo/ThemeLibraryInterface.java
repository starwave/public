package com.thirdwavesoft.wallpaperinfo;

import android.content.Context;
import android.os.Environment;
import android.util.Log;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Future;

public class ThemeLibraryInterface {

    ThemeLibraryInterface(Context context) {
        _context = context;
    }

    synchronized public boolean requestUpdateThemeLibrary(String label, String config, final MaramboiCompletion completion) {
        try {
            String option = "a=u&l=" + URLEncoder.encode(label, "utf-8") + "&c=" + URLEncoder.encode(config, "utf-8");
            class MyCompletion extends MaramboiCompletion {
                @Override
                void completion(String response) {
                    BPUtil.storeStringToFile(_themeJsonPath, response);
                    completion.setResponse(response);
                    completion.run();
                }
            }
            MyCompletion myCompletion = new MyCompletion();
            maramboi(option, myCompletion);
            return true;
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        return false;
    }

    synchronized public String getThemeLibrary(final MaramboiCompletion completion) {
        String contents = "";
        String option = "a=g";
        class MyCompletion extends MaramboiCompletion {
            @Override
            void completion(String response) {
                BPUtil.storeStringToFile(_themeJsonPath, response);
                completion.setResponse(response);
                completion.run();
            }
        }
        MyCompletion myCompletion = new MyCompletion();
        maramboi(option, myCompletion);
        if (!BPUtil.fileExists(_themeJsonPath)) {
            if (copyAssetFile("themelib.txt", _themeJsonPath)) {
                contents = BPUtil.getStringFromFile(_themeJsonPath);
                if (contents != "") {
                    BPUtil.storeStringToFile(_themeJsonPath, contents);
                }
            } else {
                Log.e(_TAG, "Error: getThemeLibrary - copying asset themeLib.txt file");
            }
        } else {
            contents = BPUtil.getStringFromFile(_themeJsonPath);
        }
        return contents;
    }

    synchronized public String getReservedWords(final MaramboiCompletion completion) {
        String contents = "";
        String option = "a=r";
        class MyCompletion extends MaramboiCompletion {
            @Override
            void completion(String response) {
                BPUtil.storeStringToFile(_reservedJsonPath, response);
                completion.setResponse(response);
                completion.run();
            }
        }
        MyCompletion myCompletion = new MyCompletion();
        maramboi(option, myCompletion);
        if (!BPUtil.fileExists(_reservedJsonPath)) {
            if (copyAssetFile("reservedword.txt", _reservedJsonPath)) {
                contents = BPUtil.getStringFromFile(_reservedJsonPath);
                if (contents != "") {
                    BPUtil.storeStringToFile(_reservedJsonPath, contents);
                }
            } else {
                Log.e(_TAG, "Error: getReservedWords - copying asset reservedword.txt file");
            }
        } else {
            contents = BPUtil.getStringFromFile(_reservedJsonPath);
        }
        return contents;
    }

    synchronized public void updateThemeLibLocalFileFromList(List<ThemeLib> parsedThemeLibs) {
        JSONArray jArray = new JSONArray();
        for(int i = 1; i< parsedThemeLibs.size(); i++) {
            ThemeLib themeLibItem = parsedThemeLibs.get(i);
            JSONObject jObject = new JSONObject();
            try {
                jObject.put("label", themeLibItem.Label);
                jObject.put("config", themeLibItem.Config);
            } catch (JSONException e) {
                e.printStackTrace();
            }
            jArray.put(jObject);
        }
        try {
            BPUtil.storeStringToFile(_themeJsonPath, jArray.toString(1));
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    synchronized private boolean copyAssetFile(String assetName, String fileName) {
        try {
            File themeJsonPath = new File(fileName);
            if (!themeJsonPath.exists()) {
                InputStream in = _context.getAssets().open(assetName);
                OutputStream out = new FileOutputStream(fileName);
                byte[] buf = new byte[1024];
                int len;
                while ((len = in.read(buf)) > 0)
                    out.write(buf, 0, len);
                in.close();
                out.close();
                return true;
            }
        } catch (IOException e ){
            Log.e(_TAG, "Error in copying asset " + assetName + " file.");
        }
        return false;
    }

    public List<ThemeLib> parseThemeLib(String themeLibString) {
        List<ThemeLib> parsedThemeLibs = new ArrayList<ThemeLib>();
        try {
            JSONArray jArray = new JSONArray(themeLibString);
            for (int i=0; i < jArray.length(); i++) {
                JSONObject jObject = jArray.getJSONObject(i);
                String label = jObject.getString("Label");
                String config = jObject.getString("Config");
                ThemeLib themeLib = new ThemeLib(label, config);
                parsedThemeLibs.add(themeLib);
            }
        } catch (Exception e) {
            Log.e(_TAG, "Error in parsing json from themelib.txt file.");
        }
        return parsedThemeLibs;
    }

    public ReservedWordList parseReservedWord(String reservedWordString) {
        ReservedWordList parsedReservedWord = new ReservedWordList();
        try {
            JSONArray jArray = new JSONArray(reservedWordString);
            for (int i=0; i < jArray.length(); i++) {
                JSONObject jObject = jArray.getJSONObject(i);
                String label = jObject.getString("Word");
                String config = jObject.getString("WordPath");
                ReservedWord reservedWord = new ReservedWord(label, config);
                parsedReservedWord.add(reservedWord);
            }
        } catch (Exception e) {
            Log.e(_TAG, "Error in parsing json from reservedword.txt file.");
        }
        return parsedReservedWord;
    }

    synchronized private void maramboi(String option, final MaramboiCompletion completion) {
        String url = "http://" + _host + ":8080/maramboi?" + option;
        AsynchronousHttpRequest http = new AsynchronousHttpRequest();
        Future<String> future = http.sendAsyncGetRequest(url);
        try {
            String response = future.get();
            completion.setResponse(response);
            completion.run();
            System.out.println(response);
        } catch (Exception e) {
            Toast.makeText(
                    _context, "maramboi error", Toast.LENGTH_SHORT).show();
        }
    }

    public final String _documentsDir = Environment.getExternalStorageDirectory().getPath() + File.separatorChar + "Documents" + File.separatorChar;
    public final String _themeJsonPath = _documentsDir + ".themelib.txt";
    public final String _reservedJsonPath = _documentsDir + ".reservedword.txt";
    public final String _host = "192.168.1.111";
    private Context _context;
    private final static String _TAG = "ThemeLibraryInterface";
}

class ThemeLib {
    public String Label;
    public String Config;

    ThemeLib(String label, String config) {
        Label = label;
        Config = config;
    }
};

class ReservedWord {
    public String Word;
    public String WordPath;

    ReservedWord(String word, String wordPath) {
        Word = word;
        WordPath = wordPath;
    }
};

class MaramboiCompletion implements Runnable {
    String _response;
    void setResponse(String response) {
        _response = response;
    }
    public void run() {
        completion(_response);
    }
    // should be overidden by child
    void completion(String response) {
    }
}
