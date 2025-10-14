using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;
using System.Windows.Interop;
using System.Windows.Forms;
using System.Data;
using System.ComponentModel;
using System.Collections.ObjectModel;
using Microsoft.VisualBasic;

namespace WpfCustomControlLib {
	/// <summary>
	/// Interaction logic for CustomConfigDialog.xaml
	/// </summary>
	public partial class CustomConfigDialog : Window {

		public static void openCustomConfigDialog(String currentConfigString, Action<String> completion) {
			CustomConfigDialog customConfigDialog = new CustomConfigDialog(currentConfigString, completion);
			var screen = Screen.PrimaryScreen;
			var windowsScale = (Screen.PrimaryScreen.Bounds.Width / SystemParameters.PrimaryScreenWidth);
			var point = new Point(screen.WorkingArea.Right / windowsScale - customConfigDialog.Width - 5,
												screen.WorkingArea.Bottom / windowsScale - customConfigDialog.Height - 1);
			customConfigDialog.Left = point.X ;
			customConfigDialog.Top = point.Y ;
			customConfigDialog.ShowDialog();
		}

		public CustomConfigDialog(String currentConfigString, Action<String> completion) {
			InitializeComponent();
			_currentCustomConfigString = currentConfigString;
			_confirmCustomConfigStringCompletion = completion;
			getReservedWords();
			getThemeLibrary();
		}

		// Equivalent to windowDidLoad or onResume
		private void windowContentRendered(object sender, EventArgs e) {
			themeLibsListView_SelectedRow(0);
		}

		private void saveToLibraryBtnClicked(object sender, RoutedEventArgs e) {
			Console.WriteLine("CustomConfigDialog - saveToLibraryBtnClicked");
			int currentRow = _themeLibsListView.SelectedIndex;
			if (currentRow == 0 || currentRow == -1) { // adding new theme library
				alertDialogWithNewText("New Theme Label", (response) => {
					if (response != "") {
						if (requestUpdateThemeLibrary(response, _customConfigString)) {
                            lock (this) {
                                ThemeLib themeLibItem = new ThemeLib(response, _customConfigString);
                                _themeLibsList.Add(themeLibItem);
                                updateThemeLibLocalFileFromList();
                            }
						} else {
							errorAlert("Error", "Can't add new theme to the library.");
						}
					}
				});
			} else { // modifying existing theme libarary
				ThemeLib themeLibItem = _themeLibsList[currentRow];
                if (requestUpdateThemeLibrary(themeLibItem.Label, _customConfigString)) {
                    lock (this) {
                        themeLibItem.Config = _customConfigString;
                        updateThemeLibLocalFileFromList();
                    }
				} else {
					errorAlert("Error", "Can't update selected theme to the library.");
				}
			}
		}

		private void addBtnClicked(object sender, RoutedEventArgs e) {
			BPUtil.BPLog("CustomConfigDialog - addBtnClicked");
			alertDialogWithNewText("New Word",  (response) => {
				if (response != "" && addCustomWord(response, 1)) {
					sortCustomWordList();
					updateCustomConfigStringFromList();
					customWordsListView_NotifyItemChanged();
				}
			});
		}

		private void clearBtnClicked(object sender, RoutedEventArgs e) {
            BPUtil.BPLog("CustomConfigDialog - clearBtnClicked");
			_customConfigString = _defaultCustomConfigString;
			themeLibsListView_SelectedRow(-1);
		}

		private void okBtnClicked(object sender, RoutedEventArgs e) {
            BPUtil.BPLog("CustomConfigDialog - okBtnClicked");
			if (_confirmCustomConfigStringCompletion != null) {
				_confirmCustomConfigStringCompletion(_customConfigString);
			}
			this.Close();
		}

		private void cancelButtonClicked(object sender, RoutedEventArgs e) {
            BPUtil.BPLog("CustomConfigDialog - cancelButtonClicked");
			this.Close();
		}

		///////////////////////////////////////////////
		// ListView Utility Method
		///////////////////////////////////////////////
		private void themeLibsListView_SelectedRow(int row) {
			_themeLibsListView.SelectedIndex = row;
			themeLibsListView_HandleSelectionChanged(row);
		}

		private void themeLibsListView_HandleSelectionChanged(int row) {
			if (row >= 0) {
				var config = _themeLibsList[row].Config;
				updateListFromCustomConfigString(config);
			} else { // no selection update for clear button
				updateListFromCustomConfigString(_customConfigString);
			}
			updateCustomConfigStringFromList();
		}

		private void themeLibsListView_NotifyItemChanged() {
			_themeLibsListView.DataContext = _themeLibsList.Select(x => new ThemeLibDataContext() {
				Label = x.Label,
			});
		}

		private void customWordsListView_NotifyItemChanged() {
			_customWordsListView.DataContext = _customWordsList.Select(x => new CustomWordDataContext() {
				Word = x.Word,
				WordType = x.WordType,
			});
		}

		///////////////////////////////////////////////
		// ListView Event Handler
		///////////////////////////////////////////////
		private void themeLibsListView_SelectionChanged(object sender, SelectionChangedEventArgs e) {
			var row = _themeLibsListView.SelectedIndex;
            BPUtil.BPLog("ThemeLibsListView_SelectionChanged = " + row.ToString());
			themeLibsListView_HandleSelectionChanged(row);
		}

		private void themeLibsListView_Trash_MouseButtonDown(object sender, MouseButtonEventArgs e) {
			var item = sender as System.Windows.Controls.Image;
			if (item != null) {
				var label = item.Tag.ToString();
                BPUtil.BPLog("ThemeLibsListViewItemTrash_MouseButtonDown = " + label);
				var row = _themeLibsList.FindIndex(0, _themeLibsList.Count, (x) => { return x.Label == label; });
				if (row >= 0) {
					String theme_label = _themeLibsList[row].Label;
					if (requestUpdateThemeLibrary(theme_label, "")) {
                        // some pc does http faster than inline step over so that it makes sure item exists before it deletes
                        lock (this) {
                            var previousThemeLabel = "";
                            var selectedRow = _themeLibsListView.SelectedIndex;
                            // unselect row if it's deleted
                            if ( selectedRow == row) {
                                themeLibsListView_SelectedRow(-1);
                            } else {
                                if (selectedRow >= 0) {
                                    previousThemeLabel = _themeLibsList[selectedRow].Label;                 
                                }
                            }
							var rowToDelete = _themeLibsList.FindIndex(0, _themeLibsList.Count, (x) => { return x.Label == label; });
							if (rowToDelete >= 0) {
								_themeLibsList.RemoveAt(rowToDelete);
                                // move selected row in case it's affected by deletion
                                var newSelectedRow = _themeLibsList.FindIndex(0, _themeLibsList.Count, (x) => { return x.Label == previousThemeLabel; });
                                themeLibsListView_SelectedRow(newSelectedRow);
 								themeLibsListView_NotifyItemChanged();
								updateThemeLibLocalFileFromList();
							}
						}
					}
				}
			}
		}

		private void customWordsListView_WordType_Click(object sender, RoutedEventArgs e) {
			var item = sender as System.Windows.Controls.Button;
			var word = item.Tag.ToString();
			var row = _customWordsList.FindIndex(0, _customWordsList.Count, (x) => { return x.Word == word; });
			if (row >= 0) {
				_customWordsListView.SelectedIndex = row;
			}
			System.Windows.Controls.ContextMenu cm = this.FindResource("WordStyleMenu") as System.Windows.Controls.ContextMenu;
			if (cm != null) {
				cm.PlacementTarget = item;
				cm.IsOpen = true;
			}
		}

		private void customWordsListView_WordType_MenuItemClick(object sender, RoutedEventArgs e) {
			var item = sender as System.Windows.Controls.MenuItem;
			if (item != null) {
				var word = item.Tag.ToString();
				var row = _customWordsList.FindIndex(0, _customWordsList.Count, (x) => { return x.Word == word; });
				var wordType = item.CommandParameter.ToString();
                BPUtil.BPLog("customWordsListView_WordType_MenuItemClick = " + word + "," + wordType);
				CustomWord customWordItem = _customWordsList[row];
				switch (wordType) {
					case "0":
						int reservedIndex = _reservedWordList.FindIndex(0, _reservedWordList.Count, (x) => { return x.Word == customWordItem.Word; });
						if (reservedIndex >= 0) {
							if (_reservedWordList[reservedIndex].WordPath != "") {
								CustomWord newCustomWordItem = new CustomWord(_reservedWordList[reservedIndex].WordPath, 0);
								_customWordsList.Add(newCustomWordItem);
								break;
							}
						} else if (_reservedWordList.FindIndex(0, _reservedWordList.Count, (x) => { return x.WordPath == customWordItem.Word; }) >= 0) {
							_customWordsList[row].WordType = 0;
							break;
						}
						errorAlert("Error", "Selected word is not path.");
						break;
					case "1":
						_customWordsList[row].WordType = 1;
						break;
					case "2":
						_customWordsList[row].WordType = 2;
						break;
					case "3":
						_customWordsList[row].WordType = 3;
						break;
					default:
						break;
				}
				sortCustomWordList();
				customWordsListView_NotifyItemChanged();
				updateCustomConfigStringFromList();
			}
		}

		private void customWordsListView_Trash_MouseButtonDown(object sender, MouseButtonEventArgs e) {
			var item = sender as System.Windows.Controls.Image;
			if (item != null) {
				var word = item.Tag.ToString();
                BPUtil.BPLog("CustomWordsListViewItemTrash_MouseButtonDown = " + word);
				var row = _customWordsList.FindIndex(0, _customWordsList.Count, (x) => { return x.Word == word; });
				if (_reservedWordList.FindIndex(0, _reservedWordList.Count, (x) => { return x.Word == _customWordsList[row].Word; }) >= 0) {
					_customWordsList[row].WordType = 3;
					sortCustomWordList();
				} else {
					_customWordsList.RemoveAt(row);
				}
				customWordsListView_NotifyItemChanged();
				updateCustomConfigStringFromList();
			}
		}

	    ///////////////////////////////////////////////
	    // themeLib json <-> List
	    ///////////////////////////////////////////////
		private void updateListFromThemeLibJsonString(String themeLibString) {
			lock(this) {
				String previousThemeLabel = "Current";
				int newSelectedRow = -1;
				var selectedRow = _themeLibsListView.SelectedIndex;
				if (selectedRow >= 0) {
					previousThemeLabel = _themeLibsList[selectedRow].Label;
				}
				_themeLibsList.Clear();
				if (themeLibString != "") {
					_themeLibsList = _themeLibraryInterface.parseThemeLib(themeLibString);
				}
				ThemeLib currentThemeLib = new ThemeLib("Current", _currentCustomConfigString);
                _themeLibsList.Insert(0, currentThemeLib);
				for (int i=0; i < _themeLibsList.Count; i++)  {
					String label = _themeLibsList[i].Label;
					if (previousThemeLabel == label) {
						newSelectedRow = i;
					}
				}
				themeLibsListView_NotifyItemChanged();
                _themeLibsListView.SelectedIndex = newSelectedRow;
            }
		}

		private void updateThemeLibLocalFileFromList() {
			_themeLibraryInterface.updateThemeLibLocalFileFromList(_themeLibsList);
		}

		///////////////////////////////////////////////
		// ThemeLibraryInterface Wrappers
		///////////////////////////////////////////////
		private bool requestUpdateThemeLibrary(String label, String config) {
			lock (this) { // this lock is important to prevent hang in some computer
				return _themeLibraryInterface.requestUpdateThemeLibrary(label, config, response => {
					updateListFromThemeLibJsonString(response);
				});
			}
		}

		private void getThemeLibrary() {
			String themeLibData = _themeLibraryInterface.getThemeLibrary(response => {
				updateListFromThemeLibJsonString(response);
			});
			if (themeLibData != "") {
				updateListFromThemeLibJsonString(themeLibData);
			}
		}

		///////////////////////////////////////////////
		// CustomConfigString <-> List
		///////////////////////////////////////////////
		private void updateListFromCustomConfigString(String customConfigString) {
			lock (this) {
				_customWordsList.Clear();
				_customConfigString = customConfigString;
				List<ReservedWord> reservedWords = new List<ReservedWord>(_reservedWordList);
				List<String> configWords = new List<String>(customConfigString.Split(';'));
				List<String> rootsArray = getWordsArray((configWords.Count > 0 && !customConfigString.Equals("")) ? configWords[0] : "/");
				List<String> allowWords = getWordsArray((configWords.Count > 1) ? configWords[1] : "");
				List<String> filterWords = getWordsArray((configWords.Count > 2) ? configWords[2] : "#nd#|#sn#");
				for (int i = 0; i < rootsArray.Count; i++) {
					addCustomWord(rootsArray[i], 0);
					int index = reservedWords.FindIndex(0, reservedWords.Count, (x) => { return x.Word == rootsArray[i]; });
					if (index >= 0) {
						reservedWords.RemoveAt(index);
					}
				}
				for (int i = 0; i < allowWords.Count; i++) {
					addCustomWord(allowWords[i], 1);
					int index = reservedWords.FindIndex(0, reservedWords.Count, (x) => { return x.Word == allowWords[i]; });
					if (index >= 0) {
						reservedWords.RemoveAt(index);
					}
				}
				for (int i = 0; i < filterWords.Count; i++) {
					addCustomWord(filterWords[i], 2);
					int index = reservedWords.FindIndex(0, reservedWords.Count, (x) => { return x.Word == filterWords[i]; });
					if (index >= 0) {
						reservedWords.RemoveAt(index);
					}
				}
				for (int i = 0; i < reservedWords.Count; i++) {
					addCustomWord(reservedWords[i].Word, 3);
				}
				sortCustomWordList();
				customWordsListView_NotifyItemChanged();
			}
		}

		private void updateCustomConfigStringFromList() {
			lock (this) {
				String root = "", allow = "", filter = "";
				for (int i = 0; i < _customWordsList.Count; i++) {
					CustomWord customWordItem = _customWordsList[i];
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
				if (root.Length > 0) {
					root = root.Substring(0, root.Length - 1);
				}
				if (allow.Length > 0) {
					allow = allow.Substring(0, allow.Length - 1);
				}
				if (filter.Length > 0) {
					filter = filter.Substring(0, filter.Length - 1);
				}
				_customConfigString = root + ";" + allow + ";" + filter;
				_customConfigStringTextBox.Text = (_customConfigString);
			}
		}

		///////////////////////////////////////////////
		// custom word utility methods
		///////////////////////////////////////////////
		private void getReservedWords() {
			String reservedWordsData = _themeLibraryInterface.getReservedWords(response => {
				updateReservedWords(response);
			});
			if (reservedWordsData != "") {
				updateReservedWords(reservedWordsData);
			}
		}

		private void updateReservedWords(String reservedWordsData) {
			lock (this) {
				_reservedWordList = _themeLibraryInterface.parseReservedWord(reservedWordsData);
			}
		}

		private void sortCustomWordList() {
			_customWordsList.Sort();
		}

		private bool addCustomWord(String newCustomWord, int customType) {
			if (newCustomWord != null) {
				if (newCustomWord.IndexOf('|') >= 0 || newCustomWord.IndexOf(';') >= 0 ) {
					errorAlert("Error", "Word can't include the bar (|) or semi-colon (;) character.");
					return false;
				}
				CustomWord customWordItem = new CustomWord(newCustomWord, customType);
				_customWordsList.Add(customWordItem);
				return true;
			}
			errorAlert("Error", "Invalid custom word.");
			return false;
		}

		private void alertDialogWithNewText(String title, Action<String> completion) {
			String response = Interaction.InputBox("Press OK or Cancel after typed.", title, "");
			completion(response);
		}

		private void errorAlert(String title, String message) {
			System.Windows.MessageBox.Show(message, title);
		}

		public List<String> getWordsArray(String wordString) {
			if (wordString.Equals("")) {
				return new List<String>();
			} else {
				return new List<String>(wordString.Split('|'));
			}
		}

		// Instance var
		private List<ThemeLib> _themeLibsList = new List<ThemeLib>();
		private List<CustomWord> _customWordsList = new List<CustomWord>();
		private List<ReservedWord> _reservedWordList = new List<ReservedWord>();
		private String _customConfigString = "";
		private String _currentCustomConfigString = "";
		private Action<String> _confirmCustomConfigStringCompletion;
		private ThemeLibraryInterface _themeLibraryInterface = new ThemeLibraryInterface();
		private const String _defaultCustomConfigString = "/;;#sn#|#nd#";

		// Const
		//private static Color _selectedRowColor = Color.FromRgb(0xFF,0xFC,0x99); // Not Used. It's specified in xaml
	}

	public class CustomWord : IComparable<CustomWord> {
		public String Word;
		public int WordType;
		public CustomWord(String word, int wordType) {
			Word = word;
			WordType = wordType;
		}
		// c# defines custom sort here
		public int CompareTo(CustomWord custom_item2) {
			int custom_type1 = WordType;
			int custom_type2 = custom_item2.WordType;
			if (custom_type1 > custom_type2) {
				return 1;
			} else if (custom_type1 < custom_type2) {
				return -1;
			} else {
				String custom_word1 = Word;
				String custom_word2 = custom_item2.Word;
				return custom_word1.CompareTo(custom_word2);
			}
		}
	};

	public class ThemeLibDataContext : INotifyPropertyChanged {
		public String Label { get; set; }
		public event PropertyChangedEventHandler PropertyChanged;
		protected virtual void OnPropertyChanged(string property) {
			PropertyChangedEventHandler handler = PropertyChanged;
			if (handler != null) handler(this, new PropertyChangedEventArgs(property));
		}
	}

	public class CustomWordDataContext : INotifyPropertyChanged {
		public String Word { get; set; }
		public int WordType { get; set; }
		public event PropertyChangedEventHandler PropertyChanged;
		protected virtual void OnPropertyChanged(string property) {
			PropertyChangedEventHandler handler = PropertyChanged;
			if (handler != null) handler(this, new PropertyChangedEventArgs(property));
		}
	}

	public class ForegroundConverter : System.Windows.Data.IValueConverter {
		List<SolidColorBrush> _wordColors = new List<SolidColorBrush> {
			new SolidColorBrush(Colors.Black),
			new SolidColorBrush(Colors.DarkGreen),
			new SolidColorBrush(Colors.DarkRed),
			new SolidColorBrush(Colors.Gray)};
		public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture) {
			// var range = (Point)parameter;
			return _wordColors[(int)value];
		}
		public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture) {
			throw new NotImplementedException();
		}
	} 
}
