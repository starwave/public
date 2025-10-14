package com.thirdwavesoft.wallpaperinfo;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.DialogInterface.OnClickListener;
import android.content.DialogInterface.OnKeyListener;
import android.os.Environment;
import android.text.Editable;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

public class DirectoryChooserDialog {
	//////////////////////////////////////////////////////
    // Callback interface for selected directory
    //////////////////////////////////////////////////////
    public interface ChosenDirectoryListener {
        public void onChosenDir(String chosenDir);
    }

    public DirectoryChooserDialog(Context context, ChosenDirectoryListener chosenDirectoryListener) {
		_context = context;
		_sdcardDirectory = Environment.getExternalStorageDirectory().getAbsolutePath();
		_sdcardExtDirectory = PlatformInfo.getSDCardExtDirectory(context);
		_chosenDirectoryListener = chosenDirectoryListener;
		try {
			_sdcardDirectory = new File(_sdcardDirectory).getCanonicalPath();
		}
		catch (IOException ioe) {
		}
    }

    ///////////////////////////////////////////////////////////////////////
    // setNewFolderEnabled() - enable/disable new folder button
    ///////////////////////////////////////////////////////////////////////

    public void setNewFolderEnabled(boolean isNewFolderEnabled) {
        _isNewFolderEnabled = isNewFolderEnabled;
    }

    public boolean getNewFolderEnabled()
    {
        return _isNewFolderEnabled;
    }

    ///////////////////////////////////////////////////////////////////////
    // chooseDirectory() - load directory chooser dialog for initial
    // default sdcard directory
    ///////////////////////////////////////////////////////////////////////

    public void chooseDirectory() {
        // Initial directory is sdcard directory
        chooseDirectory(_sdcardDirectory);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // chooseDirectory(String dir) - load directory chooser dialog for initial 
    // input 'dir' directory
    ////////////////////////////////////////////////////////////////////////////////

    public void chooseDirectory(String dir) {
        File dirFile = new File(dir);
        if (! dirFile.exists() || ! dirFile.isDirectory()) {
            dir = _sdcardDirectory;
        }

        try {
            dir = new File(dir).getCanonicalPath();
        }
        catch (IOException ioe) {
            return;
        }
        _dir = dir;
        _subdirs = getDirectories(dir);
        class DirectoryOnClickListener implements DialogInterface.OnClickListener {
            public void onClick(DialogInterface dialog, int item) {
                // Navigate into the sub-directory
				String selectedDir = (String)((AlertDialog) dialog).getListView().getAdapter().getItem(item);
				if (selectedDir.equals("..")) {
					_dir = new File(_dir).getParent();
				} else {
					_dir += "/" + selectedDir;
				}
                updateDirectory();
            }
        }
	    AlertDialog.Builder dialogBuilder =
	    createDirectoryChooserDialog(dir, _subdirs, new DirectoryOnClickListener());
	    dialogBuilder.setPositiveButton("OK", new OnClickListener() {
	        @Override
	        public void onClick(DialogInterface dialog, int which) {
	            // Current directory chosen
	            if (_chosenDirectoryListener != null) {
	                // Call registered listener supplied with the chosen directory
	                _chosenDirectoryListener.onChosenDir(_dir);
	            }
	        }
	    }).setNegativeButton("Cancel", null);
	    final AlertDialog dirsDialog = dialogBuilder.create();
	    dirsDialog.setOnKeyListener(new OnKeyListener() {
	        @Override
	        public boolean onKey(DialogInterface dialog, int keyCode, KeyEvent event) {
	            if (keyCode == KeyEvent.KEYCODE_BACK && event.getAction() == KeyEvent.ACTION_DOWN) {
	                // Back button pressed
	                if ( _dir.equals(_sdcardDirectory) ) {
	                    // The very top level directory, do nothing
	                    return false;
	                }
	                else {
	                    // Navigate back to an upper directory
	                    _dir = new File(_dir).getParent();
	                    updateDirectory();
	                }
	                return true;
	            }
	            else {
	                return false;
	            }
	        }
	    });
	    // Show directory chooser dialog
	    dirsDialog.show();
	}

	private boolean createSubDir(String newDir) {
	    File newDirFile = new File(newDir);
	    if (! newDirFile.exists() ) {
	        return newDirFile.mkdir();
	    }
	    return false;
	}
	
	private List<String> getDirectories(String dir) {
		boolean found = false;
	    List<String> dirs = new ArrayList<String>();
	    try {
	        File dirFile = new File(dir);
	        if (! dirFile.exists() || ! dirFile.isDirectory()) {
	            return dirs;
	        }
			File parentFile = dirFile.getParentFile();
	        if ( parentFile != null ) {
	        	dirs.add("..");
			}
			if (dirFile.listFiles() != null) {
				for (File file : dirFile.listFiles()) {
					if ( file.isDirectory() && !file.isHidden() ) {
						dirs.add( file.getName() );
						if (file.getAbsolutePath().equals(_sdcardExtDirectory)) {
							found = true;
						}
					}
				}
			}
	    }
	    catch (Exception e) {
	    	e.printStackTrace();
	    }
		// check if _sdcardExtDirectory is empty in case memory card doesn't exist with existing slot.
		if(!_sdcardExtDirectory.isEmpty() && (new File(_sdcardExtDirectory).getParentFile()).getAbsolutePath().equals(dir) && !found) {
			dirs.add(new File(_sdcardExtDirectory).getName());
		}
	    Collections.sort(dirs, new Comparator<String>() {
	        public int compare(String o1, String o2) {
	            return o1.compareTo(o2);
	        }
	    });
	    return dirs;
	}
	
	private AlertDialog.Builder createDirectoryChooserDialog(String title, List<String> listItems,
	        DialogInterface.OnClickListener onClickListener) {
	    AlertDialog.Builder dialogBuilder = new AlertDialog.Builder(_context);
	    // Create custom view for AlertDialog title containing
	    // current directory TextView and possible 'New folder' button.
	    // Current directory TextView allows long directory path to be wrapped to multiple lines.
	    LinearLayout titleLayout = new LinearLayout(_context);
	    titleLayout.setOrientation(LinearLayout.VERTICAL);
	    _titleView = new TextView(_context);
	    _titleView.setLayoutParams(new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));
	    _titleView.setTextAppearance(_context, android.R.style.TextAppearance_Large);
	    _titleView.setTextColor( _context.getResources().getColor(android.R.color.black) );
	    _titleView.setGravity(Gravity.CENTER_VERTICAL | Gravity.CENTER_HORIZONTAL);
	    _titleView.setTextSize(11);
	    _titleView.setText(title);
	    Button newDirButton = new Button(_context);
	    newDirButton.setLayoutParams(new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.WRAP_CONTENT));
	    newDirButton.setText("New folder");
		newDirButton.setTextSize(10);
	    newDirButton.setOnClickListener(new View.OnClickListener() {
	        @Override
	        public void onClick(View v) {
			final EditText input = new EditText(_context);
			// Show new folder name input dialog
			new AlertDialog.Builder(_context).
			setTitle("New folder Name").
			setView(input).setPositiveButton("OK", new DialogInterface.OnClickListener() {
				public void onClick(DialogInterface dialog, int whichButton)
				{
				Editable newDir = input.getText();
				String newDirName = newDir.toString();
				// Create new directory
				if ( createSubDir(_dir + "/" + newDirName) ) {
					// Navigate into the new directory
					_dir += "/" + newDirName;
					updateDirectory();
				}
				else {
					Toast.makeText(
							_context, "Failed to create '" + newDirName +
					  "' folder", Toast.LENGTH_SHORT).show();
				}
				}
			}).setNegativeButton("Cancel", null).show();
	        }
	    });
	    if (!_isNewFolderEnabled) {
	        newDirButton.setVisibility(View.GONE);
	    }
	    titleLayout.addView(_titleView);
	    titleLayout.addView(newDirButton);
	    dialogBuilder.setCustomTitle(titleLayout);
	    _listAdapter = createListAdapter(listItems);
	    dialogBuilder.setSingleChoiceItems(_listAdapter, -1, onClickListener);
	    dialogBuilder.setCancelable(false);
	    return dialogBuilder;
	}
	
	private void updateDirectory() {
	    _subdirs.clear();
	    _subdirs.addAll( getDirectories(_dir) );
	    _titleView.setText(_dir);
	    _listAdapter.notifyDataSetChanged();
	}
	
	private ArrayAdapter<String> createListAdapter(List<String> items) {
	    return new ArrayAdapter<String>(_context, android.R.layout.select_dialog_item, android.R.id.text1, items) {
	        @Override
	        public View getView(int position, View convertView,
	        ViewGroup parent) {
	            View v = super.getView(position, convertView, parent);
	            if (v instanceof TextView) {
	                // Enable list item (directory) text wrapping
	                TextView tv = (TextView) v;
	                tv.getLayoutParams().height = LayoutParams.WRAP_CONTENT;
	                tv.setEllipsize(null);
	                tv.setTextSize(13);
					tv.setHeight(130);
					tv.setMinimumHeight(130);
	            }
	            return v;
	        }
	    };
	}
	private boolean _isNewFolderEnabled = true;
	private String _sdcardDirectory = "";
	private String _sdcardExtDirectory = "";
	private Context _context;
	private TextView _titleView;
	private String _dir = "";
	private List<String> _subdirs = null;
	private ChosenDirectoryListener _chosenDirectoryListener = null;
	private ArrayAdapter<String> _listAdapter = null;
}