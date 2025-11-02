package com.thirdwavesoft.wallpaperinfo;

import android.app.AlertDialog;
import android.content.ContentUris;
import android.content.Context;
import android.content.DialogInterface;
import android.database.Cursor;
import android.net.Uri;
import android.net.nsd.NsdServiceInfo;
import android.provider.MediaStore;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;

public class AlbumPickerDialog {

    public AlbumPickerDialog(Context context, AlbumSelectionListener selectionListener) {
        this._context = context;
        this._selectionListener = selectionListener;
    }

    public interface AlbumSelectionListener {
        void onAlbumSelected(String albumName);
    }

    // Show AlertDialog with a list of albums
    public void showAlbumSelectionDialog() {
        _albumNames = get_albumNames();
        if (_albumNames.isEmpty()) {
            Toast.makeText(_context, "No albums found.", Toast.LENGTH_SHORT).show();
            return;
        }
        AlertDialog.Builder builder = new AlertDialog.Builder(_context);
        builder.setTitle("Choose Galley Album")
        .setItems(_albumNames.toArray(new String[0]),
        new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                String selectedAlbum = _albumNames.get(which);
                if (_selectionListener != null) {
                    _selectionListener.onAlbumSelected(selectedAlbum);
                }
            }
        });
        AlertDialog alertDialog = builder.create();
        alertDialog.show();
        /*
        AlbumAdapter adapter = new AlbumAdapter(_context, _albumNames);
        new AlertDialog.Builder(_context)
                .setTitle("Select Album")
                .setAdapter(adapter, (dialog, which) -> {
                    String selectedAlbum = _albumNames.get(which);
                    if (_selectionListener != null) {
                        _selectionListener.onAlbumSelected(selectedAlbum);
                    }
                })
                .setCancelable(true)
                .show();

         */
    }


    // Query MediaStore to get a list of unique album names
    private ArrayList<String> get_albumNames() {
        ArrayList<String> albumNames = new ArrayList<>();
        HashSet<String> albumSet = new HashSet<>();
        String[] projection = {MediaStore.Images.Media.BUCKET_DISPLAY_NAME};
        Cursor cursor = _context.getContentResolver().query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                projection,
                null,
                null,
                MediaStore.Images.Media.BUCKET_DISPLAY_NAME + " ASC");

        if (cursor != null) {
            int bucketColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_DISPLAY_NAME);
            while (cursor.moveToNext()) {
                String albumName = cursor.getString(bucketColumn);
                if (albumSet.add(albumName)) { // Add only unique album names
                    albumNames.add(albumName);
                }
            }
            cursor.close();
        }
        return albumNames;
    }

    public class AlbumAdapter extends ArrayAdapter<String> {
        private final Context _context;
        private final List<String> _albumNames;

        public AlbumAdapter(Context context, List<String> albumNames) {
            super(context, R.layout.gallery_album_item, albumNames);
            Log.d(_TAG, "AlbumAdapter");
            this._context = context;
            this._albumNames = albumNames;
        }

        @Override
        public View getView(int position, View convertView, ViewGroup viewGroup) {
            // LayoutInflater inflater = (LayoutInflater) _context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
            // View rowView = inflater.inflate(R.layout.gallery_album_item, parent, false);
            View rowView = LayoutInflater.from(viewGroup.getContext()).inflate(R.layout.gallery_album_item, viewGroup, false);
            ImageView thumbnailView = rowView.findViewById(R.id.albumThumbnail);
            TextView textView = rowView.findViewById(R.id.albumName);
            String albumName = _albumNames.get(position);
            textView.setText(albumName);
            Uri thumbnailUri = getAlbumThumbnailUri(albumName);
            if (thumbnailUri != null) {
                thumbnailView.setImageURI(thumbnailUri);
            } else {
                thumbnailView.setImageResource(R.drawable.thirdwave); // Set a default icon
            }
            return rowView;
        }

        private Uri getAlbumThumbnailUri(String albumName) {
            String[] projection = {MediaStore.Images.Media._ID};
            String selection = MediaStore.Images.Media.BUCKET_DISPLAY_NAME + "=?";
            String[] selectionArgs = {albumName};
            String sortOrder = MediaStore.Images.Media.DATE_ADDED + " DESC";
            try (Cursor cursor = _context.getContentResolver().query(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                    projection,
                    selection,
                    selectionArgs,
                    sortOrder)) {
                if (cursor != null && cursor.moveToFirst()) {
                    long id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID));
                    return ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id);
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
            return null;
        }
    }
    private final Context _context;
    private AlbumSelectionListener _selectionListener;
    private ArrayList<String> _albumNames;
    private final static String _TAG = "AlbumPickerDialog";
}
