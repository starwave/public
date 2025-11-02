package com.thirdwavesoft.wallpaperinfo;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.Drawable;
import android.text.method.ScrollingMovementMethod;
import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.PopupMenu;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class CustomConfigDialog {

    public interface ConfirmCustomConfigStringListner {
        public void onConfirmCustomConfigString(String filterString);
    }

    // it's called from WallpaperInfoUI
    public CustomConfigDialog(Context context, ConfirmCustomConfigStringListner confirmFilterStringListner) {
        _context = context;
        _confirmFilterStringListner = confirmFilterStringListner;
        // post background retrieve from the server
        _themeLibraryInterface = new ThemeLibraryInterface(context);
        AlertDialog.Builder dialogBuilder = createCustomConfigDialog();
        dialogBuilder.setPositiveButton("OK", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                if (_confirmFilterStringListner != null) {
                    _confirmFilterStringListner.onConfirmCustomConfigString(_customConfigString);
                }
            }
        }).setNegativeButton("Cancel", null);
        AlertDialog customConfigDialog = dialogBuilder.create();
        customConfigDialog.show();
    }

    private AlertDialog.Builder createCustomConfigDialog() {
        AlertDialog.Builder dialogBuilder = new AlertDialog.Builder(_context);
        LayoutInflater inflater = (LayoutInflater) _context.getSystemService( Context.LAYOUT_INFLATER_SERVICE );
        View dialogLayoutView = inflater.inflate(R.layout.customconfig_dialog_layout, null);
        dialogBuilder.setView(dialogLayoutView);

        Button saveToLibraryBtn = dialogLayoutView.findViewById(R.id.libraryButton);
        saveToLibraryBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                int currentRow = _themeLibsListAdapter.getSelectedRow();
                if (currentRow == 0 || currentRow == -1) { // adding new theme library
                    alertDialogWithNewText("New Theme Label", new Runnable() {
                        @Override
                        public void run() {
                            if (!_newWordFromAlertDialog.isEmpty()) {
                                if (requestUpdateThemeLibrary(_newWordFromAlertDialog, _customConfigString)) {
                                    synchronized (this) {
                                        ThemeLib themeLibItem = new ThemeLib(_newWordFromAlertDialog, _customConfigString);
                                        _themeLibsList.add(themeLibItem);
                                        updateThemeLibLocalFileFromList();
                                        _themeLibsListAdapter.notifyDataSetChanged();
                                        _themeLibsListAdapter.setSelectedRow(_themeLibsList.size() - 1);
                                    }
                                } else {
                                    errorAlert("Can't add new theme to the library.");
                                }
                            }
                        }
                    });
                } else { // modifying existing theme libarary
                    ThemeLib themeLibItem = _themeLibsList.get(currentRow);
                    if (requestUpdateThemeLibrary(themeLibItem.Label, _customConfigString)) {
                        synchronized (this) {
                            themeLibItem.Config = _customConfigString;
                            updateThemeLibLocalFileFromList();
                        }
                    } else {
                        errorAlert("Can't update selected theme to the library.");
                    }
                }
            }
        });
        Button addCustomWord = dialogLayoutView.findViewById(R.id.addcustomconfig);
        addCustomWord.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                alertDialogWithNewText("New Word", new Runnable() {
                    @Override
                    public void run() {
                        if (!_newWordFromAlertDialog.isEmpty() && addCustomWord(_newWordFromAlertDialog, 1)) {
                            sortCustomWordList();
                            _customWordsListAdapter.notifyDataSetChanged();
                            updateCustomConfigStringFromList();
                        }
                    }
                });
            }
        });
        Button clearCustomConfigBtn = dialogLayoutView.findViewById(R.id.clearcustomconfig);
        clearCustomConfigBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                _customConfigString = WallpaperInfoUI._defaultCustomConfigString;
                _themeLibsListAdapter.setSelectedRow(-1);
            }
        });

        dialogBuilder.setCustomTitle(buildTitleLayout());
        _customConfigString = WallpaperServiceInfo.getInstance().getCustomConfigString();
        _customStringTextView.setText(_customConfigString);
        _themeLibsRecyclerView = dialogLayoutView.findViewById(R.id.themelib_list);
        _themeLibsRecyclerView.setLayoutManager(new LinearLayoutManager(_context));
        _themeLibsRecyclerView.setAdapter(_themeLibsListAdapter = new ThemeLibsAdapter());
        _customWordsRecyclerView = dialogLayoutView.findViewById(R.id.customwords_list);
        _customWordsRecyclerView.setLayoutManager(new LinearLayoutManager(_context));
        _customWordsRecyclerView.setAdapter(_customWordsListAdapter = new CustomWordsAdapter());

        // show library the first with the local file
        getReservedWords();
        getThemeLibrary();
        _themeLibsListAdapter.setSelectedRow(0); // select and show the current config string

        return dialogBuilder;
    }

    ///////////////////////////////////////////////
    // ThemeLib Adapter
    ///////////////////////////////////////////////
    class ThemeLibsAdapter extends RecyclerView.Adapter<ThemeLibsAdapter.MyViewHolder> {
        private int _selectedRow = -1;
        public int getSelectedRow() {
            return _selectedRow;
        }
        public void setSelectedRow(int selectedRow) {
            if (selectedRow != _selectedRow) {
                int oldRow = _selectedRow;
                _selectedRow = selectedRow;
                if (oldRow >= 0) {
                    notifyItemChanged(oldRow);
                }
                if (selectedRow >= 0) {
                    ThemeLib themeLibItem = _themeLibsList.get(_selectedRow);
                    String theme_config = themeLibItem.Config;
                    updateListFromCustomConfigString(theme_config);
                } else { // -1 means no select
                    updateListFromCustomConfigString(_customConfigString);
                }
                notifyItemChanged(_selectedRow);
                updateCustomConfigStringFromList();
            }
        }
        @Override
        public MyViewHolder onCreateViewHolder(@NonNull ViewGroup viewGroup, int viewType) {
            View itemView = LayoutInflater.from(viewGroup.getContext()).inflate(R.layout.themelib_row_layout, viewGroup, false);
            return new MyViewHolder(itemView);
        }
        @Override
        public void onBindViewHolder(@NonNull MyViewHolder viewHolder, int position) {
            ThemeLib themeLibItem = _themeLibsList.get(position);
            viewHolder.tv.setText(themeLibItem.Label);
            if (position == _selectedRow) {
                viewHolder.tv.setBackgroundColor(_selectedRowColor);
            } else {
                viewHolder.tv.setBackgroundResource(android.R.color.transparent);
            }
            if (position == 0) {
                viewHolder.bt.setVisibility(View.GONE);
            } else {
                viewHolder.bt.setVisibility(View.VISIBLE);
            }
        }
        @Override
        public int getItemCount() {
            return _themeLibsList.size();
        }

        class MyViewHolder extends RecyclerView.ViewHolder implements View.OnClickListener {
            TextView tv;
            Button bt;
            public MyViewHolder(View itemView)  {
                super(itemView);
                this.tv = (TextView) itemView.findViewById(R.id.lv_item_theme_lib);
                this.bt = (Button) itemView.findViewById(R.id.lv_item_delete_btn);
                itemView.setOnClickListener(this);
                bt.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        String previousThemeLabel = "";
                        int row = getAdapterPosition();
                        if (row != RecyclerView.NO_POSITION) {
                            String theme_label = _themeLibsList.get(row).Label;
                            if (requestUpdateThemeLibrary(theme_label, "")) {
                                // unselect row if it's deleted
                                if (row == _selectedRow) {
                                    _selectedRow = -1;
                                } else {
                                    previousThemeLabel = _themeLibsList.get(_selectedRow).Label;
                                }
                                _themeLibsList.remove(row);
                                // move selected row in case it's affected by deletion
                                for (int i=0; i < _themeLibsList.size(); i++) {
                                    String label = _themeLibsList.get(i).Label;
                                    if (previousThemeLabel.equals(label)) {
                                        setSelectedRow(i);
                                        break;
                                    }
                                }
                                updateThemeLibLocalFileFromList();
                                _themeLibsListAdapter.notifyDataSetChanged();
                            }
                        }
                    }
                });
            }
            @Override
            public void onClick(View v) {
                int row = getAdapterPosition();
                if (row != RecyclerView.NO_POSITION) {
                    setSelectedRow(row);
                }
            }
        }
    }

    ///////////////////////////////////////////////
    // CustomWord Adapter
    ///////////////////////////////////////////////
    class CustomWordsAdapter extends RecyclerView.Adapter<CustomWordsAdapter.MyViewHolder> {

        private int _custom_row_selected = -1; // for popup menu

        @Override
        public MyViewHolder onCreateViewHolder(@NonNull ViewGroup viewGroup, int viewType) {
            View itemView = LayoutInflater.from(viewGroup.getContext()).inflate(R.layout.customconfig_row_layout, viewGroup, false);
            return new MyViewHolder(itemView);
        }
        @Override
        public void onBindViewHolder(@NonNull MyViewHolder viewHolder, int position) {
            CustomWord customWordItem = _customWordsList.get(position);
            int icon_array[] = {
                    R.drawable.folder,
                    R.drawable.green_light,
                    R.drawable.red_light,
                    R.drawable.gray_light };
            int color_array[] = {
                    Color.parseColor("#000000"),
                    Color.parseColor("#008000"),
                    Color.parseColor("#800000"),
                    Color.parseColor("#C0C0C0")};
            int custom_type = customWordItem.WordType;
            Drawable myDrawable = _context.getResources().getDrawable(icon_array[custom_type]);
            viewHolder.iv.setImageDrawable(myDrawable);
            viewHolder.tv.setText(customWordItem.Word);
            viewHolder.tv.setTextColor(color_array[custom_type]);
            switch (custom_type) {
                case 0:
                case 1:
                case 2:
                    viewHolder.tv.setTypeface(null, Typeface.NORMAL);
                    viewHolder.bt.setVisibility(View.VISIBLE);
                    break;
                case 3:
                    viewHolder.tv.setTypeface(null, Typeface.BOLD_ITALIC);
                    if (_reservedWordList.indexOfWord(customWordItem.Word) >= 0) {
                        viewHolder.bt.setVisibility(View.GONE);
                    } else {
                        viewHolder.bt.setVisibility(View.VISIBLE);
                    }
                    break;
            }
            if (position == _custom_row_selected) {
                viewHolder.tv.setBackgroundColor(_selectedRowColor);
            } else {
                viewHolder.tv.setBackgroundResource(android.R.color.transparent);
            }
        }
        @Override
        public int getItemCount() {
            return _customWordsList.size();
        }

        class MyViewHolder extends RecyclerView.ViewHolder implements PopupMenu.OnMenuItemClickListener, PopupMenu.OnDismissListener {
            ImageView iv;
            TextView tv;
            Button bt;

            @Override
            public void onDismiss(PopupMenu menu) {
                int pos = _custom_row_selected;
                _custom_row_selected= -1;
                _customWordsListAdapter.notifyItemChanged(pos);
            }

            @Override public boolean onMenuItemClick(MenuItem item) {
                CustomWord customWordItem = _customWordsList.get(_custom_row_selected);
                switch(item.getItemId()) {
                    case R.id.custom_root:
                        int reservedIndex = _reservedWordList.indexOfWord(customWordItem.Word);
                        if (reservedIndex >= 0) {
                            if (!_reservedWordList.get(reservedIndex).WordPath.isEmpty()) {
                                CustomWord newCustomWordItem = new CustomWord(_reservedWordList.get(reservedIndex).WordPath, 0);
                                _customWordsList.add(newCustomWordItem);
                                break;
                            }
                        } else if (_reservedWordList.indexOfWordPath(customWordItem.Word) >= 0) {
                            _customWordsList.get(_custom_row_selected).WordType = 0;
                            break;
                        }
                        errorAlert("Selected word is not path.");
                        break;
                    case R.id.custom_allow:
                        _customWordsList.get(_custom_row_selected).WordType = 1;
                        break;
                    case R.id.custom_filter:
                        _customWordsList.get(_custom_row_selected).WordType = 2;
                        break;
                    case R.id.custom_reserve:
                        _customWordsList.get(_custom_row_selected).WordType = 3;
                        break;
                }
                sortCustomWordList();
                _customWordsListAdapter.notifyDataSetChanged();
                updateCustomConfigStringFromList();
                return true;
            }
            public MyViewHolder(View itemView)  {
                super(itemView);
                this.iv = (ImageView) itemView.findViewById(R.id.lv_item_custom_type);
                this.tv = (TextView) itemView.findViewById(R.id.lv_item_custom_word);
                this.bt = (Button) itemView.findViewById(R.id.lv_item_delete_btn);
                iv.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        int row = getAdapterPosition();
                        if (row != RecyclerView.NO_POSITION) {
                            ImageView cb = (ImageView) v;
                            CustomWord customWordItem = _customWordsList.get(row);
                            PopupMenu popup = new PopupMenu(_context, v);
                            // to get around android strange bug which is not showing icon in popup menu
                            try {
                                Method method = popup.getMenu().getClass().getDeclaredMethod("setOptionalIconsVisible", boolean.class);
                                method.setAccessible(true);
                                method.invoke(popup.getMenu(), true);
                            } catch (Exception e) {
                                e.printStackTrace();
                            }
                            popup.setOnMenuItemClickListener(MyViewHolder.this);
                            popup.setOnDismissListener(MyViewHolder.this);
                            _custom_row_selected = row;
                            _customWordsListAdapter.notifyItemChanged(row);
                            MenuInflater inflater = popup.getMenuInflater();
                            inflater.inflate(R.menu.custom_type_menu, popup.getMenu());
                            int current_custom_type = customWordItem.WordType;
                            popup.getMenu().getItem(current_custom_type).setChecked(true);
                            popup.show();
                        }
                    }
                });
                bt.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        int row = getAdapterPosition();
                        if (row != RecyclerView.NO_POSITION) {
                            if (_reservedWordList.indexOfWord(_customWordsList.get(row).Word) >=0) {
                                _customWordsList.get(row).WordType = 3;
                                sortCustomWordList();
                            } else {
                                _customWordsList.remove(row);
                            }
                            _customWordsListAdapter.notifyDataSetChanged();
                            updateCustomConfigStringFromList();
                        }
                    }
                });
            }
        }
    }

    ///////////////////////////////////////////////
    // themeLib json <-> List
    ///////////////////////////////////////////////
    private void updateListFromThemeLibJsonString(String themeLibString) {
        synchronized (this) {
            String previousThemeLabel = "Current";
            int newSelectedRow = -1;
            if (_themeLibsListAdapter != null) {
                int selectedRow = _themeLibsListAdapter.getSelectedRow();
                if (selectedRow >= 0) {
                    previousThemeLabel = _themeLibsList.get(selectedRow).Label;
                }
            }
            // Log.i(_TAG, "updateListFromThemeLibJsonString\n" + themeLibString);
            _themeLibsList.clear();
            if (!themeLibString.isEmpty()) {
                _themeLibsList = _themeLibraryInterface.parseThemeLib(themeLibString);
            }
            ThemeLib currentThemeLib = new ThemeLib("Current", WallpaperServiceInfo.getInstance().getCustomConfigString());
            _themeLibsList.add(0, currentThemeLib);
            for (int i=0; i < _themeLibsList.size(); i++)  {
                String label = _themeLibsList.get(i).Label;
                if (previousThemeLabel.equals(label)) {
                    newSelectedRow = i;
                    break;
                }
            }
            if (_themeLibsListAdapter != null) {
                _themeLibsListAdapter.notifyDataSetChanged();
                _themeLibsListAdapter.setSelectedRow(newSelectedRow);
            }
        }
    }

    synchronized private void updateThemeLibLocalFileFromList() {
        _themeLibraryInterface.updateThemeLibLocalFileFromList(_themeLibsList);
    }

    ///////////////////////////////////////////////
    // ThemeLibraryInterface Wrappers
    ///////////////////////////////////////////////
    synchronized private boolean requestUpdateThemeLibrary(String label, String config) {
        class MyInterfaceCompletion extends MaramboiCompletion {
            @Override
            void completion(String response) {
                updateListFromThemeLibJsonString(response);
            }
        }
        MyInterfaceCompletion completion = new MyInterfaceCompletion();
        return _themeLibraryInterface.requestUpdateThemeLibrary(label, config, completion);
    }

    synchronized private void getThemeLibrary() {
        class MyInterfaceCompletion extends MaramboiCompletion {
            @Override
            void completion(String response) {
                updateListFromThemeLibJsonString(response);
            }
        }
        MyInterfaceCompletion completion = new MyInterfaceCompletion();
        String themeLibData = _themeLibraryInterface.getThemeLibrary(completion);
        if (themeLibData != "") {
            updateListFromThemeLibJsonString(themeLibData);
        }
    }

    ///////////////////////////////////////////////
    // CustomConfigString <-> List
    ///////////////////////////////////////////////
    synchronized private void updateListFromCustomConfigString(String customConfigString) {
        _customWordsList.clear();
        _customConfigString = customConfigString;
        ReservedWordList reservedWords = (ReservedWordList) _reservedWordList.clone();

        ThemeInfo wpti = ThemeInfo.parseCustomConfig(customConfigString);
        ArrayList<String> rootsArray = AppUtil.getWordsArray(wpti._root);
        ArrayList<String> allowWords = AppUtil.getWordsArray(wpti._allow);
        ArrayList<String> filterWords = AppUtil.getWordsArray(wpti._filter);

        for (int i = 0; i < rootsArray.size(); i++) {
            addCustomWord(rootsArray.get(i), 0);
            int index = reservedWords.indexOfWord(rootsArray.get(i));
            if (index >= 0) {
                reservedWords.remove(index);
            }
        }
        for (int i = 0; i < allowWords.size(); i++) {
            addCustomWord(allowWords.get(i), 1);
            int index = reservedWords.indexOfWord(allowWords.get(i));
            if (index >= 0) {
                reservedWords.remove(index);
            }
        }
        for (int i = 0; i < filterWords.size(); i++) {
            addCustomWord(filterWords.get(i), 2);
            int index = reservedWords.indexOfWord(filterWords.get(i));
            if (index >= 0) {
                reservedWords.remove(index);
            }
        }
        for (int i = 0; i < reservedWords.size(); i++) {
            addCustomWord(reservedWords.get(i).Word, 3);
        }
        sortCustomWordList();
        _customWordsListAdapter.notifyDataSetChanged();
    }

    synchronized private void updateCustomConfigStringFromList() {
        String root = "", allow = "", filter = "";
        for (int i = 0; i < _customWordsList.size(); i++) {
            CustomWord customWordItem = _customWordsList.get(i);
            switch (customWordItem.WordType) {
                case 0:
                    root += customWordItem.Word + "|";
                    break;
                case 1:
                    allow += customWordItem.Word + "|";
                    break;
                case 2:
                    filter += customWordItem.Word + "|";
                    break;
                default:
                    break;
            }
        }
        // Remove the last bar if exists
        if (root.length() > 0) {
            root = root.substring(0, root.length() - 1);
        }
        if (allow.length() > 0) {
            allow = allow.substring(0, allow.length() - 1);
        }
        if (filter.length() > 0) {
            filter = filter.substring(0, filter.length() - 1);
        }
        _customConfigString = root + ";" + allow + ";" + filter;
        _customStringTextView.setText(_customConfigString);
    }

    ///////////////////////////////////////////////
    // custom word utility methods
    ///////////////////////////////////////////////
    private void getReservedWords() {
        class MyInterfaceCompletion extends MaramboiCompletion {
            @Override
            void completion(String response) {
                updateReservedWords(response);
            }
        }
        MyInterfaceCompletion completion = new MyInterfaceCompletion();
        String reservedWordsData = _themeLibraryInterface.getReservedWords(completion);
        if (reservedWordsData != "") {
            updateReservedWords(reservedWordsData);
        }
    }

    private void updateReservedWords(String reservedWordsData) {
        _reservedWordList = _themeLibraryInterface.parseReservedWord(reservedWordsData);
    }

    private class CustomWordComparator implements Comparator<CustomWord> {
        @Override
        public int compare(CustomWord custom_item1, CustomWord custom_item2) {
            int custom_type1 = custom_item1.WordType;
            int custom_type2 = custom_item2.WordType;
            if (custom_type1 > custom_type2) {
                return 1;
            } else if (custom_type1 < custom_type2) {
                return -1;
            } else {
                String custom_word1 = custom_item1.Word;
                String custom_word2 = custom_item2.Word;
                return custom_word1.compareTo(custom_word2);
            }
        }
    }

    private void sortCustomWordList() {
        Collections.sort(_customWordsList, new CustomWordComparator());
    }

    private boolean addCustomWord(String newCustomWord, int customType) {
        if (newCustomWord != null) {
            if (newCustomWord.indexOf('|') >= 0 || newCustomWord.indexOf(';') >= 0 ) {
                errorAlert("Word can't include the bar (|) or semi-colon (;) character.");
                return false;
            }
            CustomWord customWordItem = new CustomWord(newCustomWord, customType);
            _customWordsList.add(customWordItem);
            return true;
        }
        errorAlert("Invalid custom word.");
        return false;
    }

    private void alertDialogWithNewText(String title, final Runnable block ) {
        final LinearLayout container = new LinearLayout(_context);
        final EditText inputEditText = new EditText(_context);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        lp.setMargins(40, 0, 40, 0);
        inputEditText.setLayoutParams(lp);
        container.addView(inputEditText);
        _newWordFromAlertDialog = "";
        new AlertDialog.Builder(_context).
                setTitle(title).
                setView(container).setPositiveButton("OK", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int whichButton) {
                _newWordFromAlertDialog = inputEditText.getText().toString();
                block.run();
            }
        }).setNegativeButton("Cancel", null).show();
    }

    private void errorAlert(String message) {
        Toast.makeText(_context, message, Toast.LENGTH_LONG).show();
    }

    private LinearLayout buildTitleLayout() {
        LinearLayout titleLayout = new LinearLayout(_context);
        _customStringTextView = new TextView(_context);
        _customStringTextView.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 120));
        _customStringTextView.setMovementMethod(new ScrollingMovementMethod());
        _customStringTextView.setTextAppearance(_context, android.R.style.TextAppearance_Large);
        _customStringTextView.setTextColor( _context.getResources().getColor(android.R.color.black) );
        _customStringTextView.setGravity(Gravity.CENTER_VERTICAL | Gravity.CENTER_HORIZONTAL);
        _customStringTextView.setTextSize(11);
        titleLayout.addView(_customStringTextView);
        return titleLayout;
    }

    // UI
    private RecyclerView _customWordsRecyclerView;
    private RecyclerView _themeLibsRecyclerView;
    private TextView _customStringTextView;
    // Android doesn't need button instance vars
    // private Button _saveToLibraryBtn;
    // private Button _addBtn;
    // private Button _clearBtn;
    // private Button _okBtn;
    // private Button _cancelBtn;
    private ThemeLibsAdapter _themeLibsListAdapter = null;
    private CustomWordsAdapter _customWordsListAdapter = null;

    // Instance var
    private List<ThemeLib> _themeLibsList = new ArrayList<ThemeLib>();
    private List<CustomWord> _customWordsList = new ArrayList<CustomWord>();
    private ReservedWordList _reservedWordList = new ReservedWordList();
    private String _customConfigString = "";
    private ConfirmCustomConfigStringListner _confirmFilterStringListner = null;
    private ThemeLibraryInterface _themeLibraryInterface = null;

    // Const
    private final static int _selectedRowColor = Color.parseColor("#FFFC99");

    // Android Only
    private Context _context;
    private String _newWordFromAlertDialog = "";
    private final static String _TAG = "CustomConfigDialog";

}

class CustomWord {
    public String Word;
    public int WordType;

    CustomWord(String word, int wordType) {
        Word = word;
        WordType = wordType;
    }
};

class ReservedWordList extends ArrayList<ReservedWord> {
    public int indexOfWord(String word) {
        for (int i =0; i <size(); i++) {
            if (word.equals(get(i).Word)) {
                return i;
            }
        }
        return -1;
    }

    public int indexOfWordPath(String wordPath) {
        for (int i =0; i <size(); i++) {
            if (wordPath.equals(get(i).WordPath)) {
                return i;
            }
        }
        return -1;
    }
}