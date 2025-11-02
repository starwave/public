package com.thirdwavesoft.wallpaperinfo;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public class AsynchronousHttpRequest {

    public static Future<String> sendAsyncGetRequest(String urlString) {
        ExecutorService executor = Executors.newSingleThreadExecutor();
        Future<String> future = executor.submit(() -> {
            try {
                URL url = new URL(urlString);
                HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                connection.setRequestMethod("GET");
                connection.setReadTimeout(10000); // Set a timeout for reading data

                int responseCode = connection.getResponseCode();
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream()));
                    StringBuilder response = new StringBuilder();
                    String line;
                    while ((line = reader.readLine()) != null) {
                        response.append(line).append("\n");
                    }
                    reader.close();
                    return response.toString();
                } else {
                    throw new Exception("HTTP request failed with response code: " + responseCode);
                }
            } catch (Exception e) {
                e.printStackTrace();
                return null;
            }
        });

        executor.shutdown();
        return future;
    }

    public static void main(String[] args) {
        String url = "https://api.example.com/data"; // Replace with your desired URL
        Future<String> future = sendAsyncGetRequest(url);

        try {
            String response = future.get(); // Wait for the response
            System.out.println(response);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}