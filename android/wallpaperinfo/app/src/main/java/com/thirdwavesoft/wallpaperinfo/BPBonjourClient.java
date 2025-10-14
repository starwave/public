package com.thirdwavesoft.wallpaperinfo;
import android.os.Bundle;
import static com.thirdwavesoft.wallpaperinfo.AppUtil.MSG_GALLERY_COPY;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.net.nsd.NsdManager;
import android.net.nsd.NsdServiceInfo;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageButton;
import android.widget.TextView;

import java.util.ArrayList;

public class BPBonjourClient {

    public BPBonjourClient(Context context) {
        _nsdManager = (NsdManager) context.getSystemService(Context.NSD_SERVICE);
    }

    public void discoverServices(Context context) {
        // Initialize the discovery listener
        _discoveryListener = new NsdManager.DiscoveryListener() {
            @Override
            public void onDiscoveryStarted(String serviceType) {
                Log.d(_TAG, "Service discovery started for type: " + serviceType);
            }

            @Override
            public void onServiceFound(NsdServiceInfo serviceInfo) {
                Log.d(_TAG, "Service discovery success: " + serviceInfo);
                if (serviceInfo.getServiceType().equals(SERVICE_TYPE)) {
                    // Add discovered service to the list
                    addUniqueService(serviceInfo);
                }
            }

            private void addUniqueService(NsdServiceInfo serviceInfo) {
                boolean exists = false;
                for (NsdServiceInfo existingService : _discoveredServices) {
                    if (existingService.getHost() != null) {
                        if (existingService.getServiceName().equals(serviceInfo.getServiceName())) {
                            exists = true;
                            break;
                        }
                    }
                }
                if (!exists) {
                    _discoveredServices.add(serviceInfo);
                }
            }

            @Override
            public void onServiceLost(NsdServiceInfo serviceInfo) {
                Log.e(_TAG, "Service lost: " + serviceInfo);
                _discoveredServices.remove(serviceInfo);
            }

            @Override
            public void onDiscoveryStopped(String serviceType) {
                Log.i(_TAG, "Discovery stopped: " + serviceType);
            }

            @Override
            public void onStartDiscoveryFailed(String serviceType, int errorCode) {
                Log.e(_TAG, "Discovery failed: Error code:" + errorCode);
                _nsdManager.stopServiceDiscovery(this);
            }

            @Override
            public void onStopDiscoveryFailed(String serviceType, int errorCode) {
                Log.e(_TAG, "Stop discovery failed: Error code:" + errorCode);
                _nsdManager.stopServiceDiscovery(this);
            }
        };
        _nsdManager.discoverServices(SERVICE_TYPE, NsdManager.PROTOCOL_DNS_SD, _discoveryListener);
    }

    public void showServiceSelectionDialog(Context context) {
        _context = context;
        ArrayList<String> serviceNames = new ArrayList<>();
        for (NsdServiceInfo serviceInfo : _discoveredServices) {
            if (serviceInfo.getServiceName().endsWith("-BPImage")) {
                serviceNames.add(serviceInfo.getServiceName().replace("-BPImage", ""));
                _filteredServices.add(serviceInfo);
            }
        }
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        View customTitleView = LayoutInflater.from(context).inflate(R.layout.bonjour_dialog_title_layout, null);
        builder.setCustomTitle(customTitleView);
        builder.setItems(serviceNames.toArray(new String[0]), new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                // Handle service selection
                NsdServiceInfo selectedService = _filteredServices.get(which);
                resolveService(_context, selectedService);
            }
        });
        AlertDialog alertDialog = builder.create();
        TextView titleTextView = (TextView) customTitleView.findViewById(R.id.bonjourTitle);
        titleTextView.setText("Select target: Album (" +_albumName + ")");
        ImageButton selectAlbumButton = (ImageButton) customTitleView.findViewById(R.id.albumLauncherButton);
        // Set up click listener for the button
        selectAlbumButton.setOnClickListener(v -> {
            _albumPickerDialog = new AlbumPickerDialog(_context, albumName -> {
                _albumName = albumName;
                titleTextView.setText("Select target: Album (" +_albumName + ")");
            });
            // Show the album selection dialog
            _albumPickerDialog.showAlbumSelectionDialog();
        });
        alertDialog.show();
    }

    // Resolve the selected service
    private void resolveService(Context context, NsdServiceInfo serviceInfo) {

        NsdManager.ResolveListener resolveListener = new NsdManager.ResolveListener() {
            @Override
            public void onResolveFailed(NsdServiceInfo serviceInfo, int errorCode) {
                Log.e(_TAG, "Resolve failed: " + errorCode);
            }

            @Override
            public void onServiceResolved(NsdServiceInfo serviceInfo) {
                Log.d(_TAG, "Service resolved: " + serviceInfo);
                String host = serviceInfo.getHost().getHostAddress();
                // int port = serviceInfo.getPort();
                Bundle keyValues = new Bundle();
                keyValues.putSerializable("host", host);
                keyValues.putSerializable("album_name", _albumName);
                WallpaperServiceConnection serviceConnection = new WallpaperServiceConnection(context, null);
                serviceConnection.sendMessageToService(MSG_GALLERY_COPY, 0, keyValues);
            }
        };
        _nsdManager.resolveService(serviceInfo, resolveListener);
    }

    // Stop service discovery when not needed
    public void stopDiscovery() {
        _nsdManager.stopServiceDiscovery(_discoveryListener);
    }
    private Context _context;
    private AlbumPickerDialog _albumPickerDialog;
    private NsdManager _nsdManager;
    private NsdManager.DiscoveryListener _discoveryListener;
    private String _albumName = "Camera";
    private ArrayList<NsdServiceInfo> _filteredServices = new ArrayList<>();
    private ArrayList<NsdServiceInfo> _discoveredServices = new ArrayList<>();
    private static final String SERVICE_TYPE = "_http._tcp.";  // Define the service type you want to discover (e.g., HTTP service)
    private final static String _TAG = "BPBonjourClient";
}
