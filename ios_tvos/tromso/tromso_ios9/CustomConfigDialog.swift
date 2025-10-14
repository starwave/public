//
//  CustomConfigDialog.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 8/30/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import UIKit

struct CustomWord {
	var Word:String
	var WordType:Int
}

var _customConfigDialog: CustomConfigDialog?

class CustomConfigDialog : UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDataSource, UITableViewDelegate {
	
	// it's called from WallpaperInfoUI
	static func openCustomConfigDialog(viewController:TromsoIOS9ViewController, completion: @escaping (String?) -> Void) {
		let customConfigDialog = CustomConfigDialog(nibName: "CustomConfigDialog", bundle: nil)
		viewController.present(customConfigDialog, animated: true, completion: nil)
		customConfigDialog._confirmCustomConfigStringCompletion = completion
		customConfigDialog._parent = viewController
		customConfigDialog._parent?.setIdleTimerDisabled(false)
		customConfigDialog._parent?._serviceConnection?.sendMessageToService(command: MSG.PAUSE, intOption: 1)
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	override func viewDidLoad() {
		super.viewDidLoad()
		print("CustomConfigDialog - viewDidLoad")
        _themePickerView.delegate = self
        _themePickerView.dataSource = self
		let wpsi = WallpaperServiceInfo.getInstance()
		_themeLibsList.removeAll()
		_themeLibsListAdapter = ThemeLibsAdapter(parent:self)
		//_themeLibsListAdapter!.setColumnForAutoHeightOfRow(0)
		_themeLibsTableView.setAdapter(adapter: _themeLibsListAdapter!)
		_customWordsListAdapter = CustomWordsAdapter(parent:self)
		//_customWordsListAdapter!.setColumnForAutoHeightOfRow(1)
		_customWordsTableView.setAdapter(adapter: _customWordsListAdapter!)
		_selectedThemeLib = ThemeLib(Label: "Current", Config: wpsi.getCustomConfigString())
		getReservedWords()
		_customConfigString = _selectedThemeLib!.Config
		_customConfigStringTextField.text = _selectedThemeLib!.Config
		updateListFromCustomConfigString(customConfigString: _selectedThemeLib!.Config)
		getThemeLibrary()
		_themePickerView.selectRow(wpsi.getTheme().intValue, inComponent:0, animated: false)
		_saverSwitch.isOn = wpsi.getSaver()
        _offlineModeSwitch.isOn = wpsi.getOfflineMode()
		_intervalSlider.value = Float(wpsi.getInterval())
		
		// Setup Popup menu
		//Bundle.main.loadNibNamed("CustomWordTypePopupMenu", owner: self, topLevelObjects:nil)
		//_customWordTypePopupMenu.delegate = self
	}
	
	@IBAction func onSaverSwitchValueChanged(_ saverSwitch: UISwitch) {
		_parent?._serviceConnection?.sendMessageToService(command: MSG.SET_SAVER, intOption: saverSwitch.isOn ? 1 : 0)
	}
    
    @IBAction func onOfflineModeSwitchValueChanged(_ offlineModeSwitch: UISwitch) {
        _parent?._serviceConnection?.sendMessageToService(command: MSG.SET_OFFLINE_MODE, intOption: offlineModeSwitch.isOn ? 1 : 0)
    }

	@IBAction func saveToLibraryBtnPressed(sender: AnyObject?) {
		print("CustomConfigDialog - saveToLibraryBtnPressed")
		let currentRow = _themeLibsListAdapter!.getSelectedRow();
		if (currentRow == 0 || currentRow == -1) { // adding new theme library
			alertDialogWithNewText(title: "New Theme Label", completion: { (wordFromAlertDialog) in
				if let newWordFromAlertDialog = wordFromAlertDialog {
					if (newWordFromAlertDialog != "") {
						self._selectedThemeLib = ThemeLib(Label: newWordFromAlertDialog, Config: self._customConfigString)
						if (self.requestUpdateThemeLibrary(label: newWordFromAlertDialog, config: self._customConfigString)) {
							// Do nothing to avoid race condition
						} else {
							self.errorAlert(title: "Error", message: "Can't add new theme to the library.")
						}
					}
				}
			})
		} else { // modifying existing theme libarary
			if (requestUpdateThemeLibrary(label: _themeLibsList[currentRow].Label, config: _customConfigString)) {
				_themeLibsList[currentRow].Config = _customConfigString
				updateThemeLibLocalFileFromList()
			} else {
				self.errorAlert(title: "Error", message: "Can't update selected theme to the library.")
			}
		}
	}

	@IBAction func addBtnPressed(sender: AnyObject?) {
		print("CustomConfigDialog - addBtnPressed")
		alertDialogWithNewText(title: "New Word", completion: { (wordFromAlertDialog) in
			if let newWordFromAlertDialog = wordFromAlertDialog {
				if (newWordFromAlertDialog != "" && self.addCustomWord(newCustomWord: newWordFromAlertDialog, customType: 1)) {
					self.sortCustomWordList()
					self._customWordsListAdapter!.notifyDataSetChanged()
					self.updateCustomConfigStringFromList()
				}
			}
		})
	}

	@IBAction func clearBtnPressed(sender: AnyObject?) {
		print("CustomConfigDialog - clearBtnPressed")
		updateListFromCustomConfigString(customConfigString:_defaultCustomConfigString)
		_selectedThemeLib = nil
		_themeLibsListAdapter!.setSelectedRow(selectedRow: -1)
		_customWordsListAdapter!.notifyDataSetChanged()
	}
	
	@IBAction func okBtnPressed(sender: AnyObject?) {
		print("CustomConfigDialog - okBtnPressed")
		_confirmCustomConfigStringCompletion(_customConfigString)
		handleDismiss()
	}

	@IBAction func cancelBtnPressed(sender: AnyObject?) {
		print("CustomConfigDialog - cancelBtnPressed")
		handleDismiss()
	}
	
	func handleDismiss() {
		_parent?.setIdleTimerDisabled(true)
		_parent?._serviceConnection?.sendMessageToService(command: MSG.PAUSE, intOption: 0)
		self.dismiss(animated: true, completion: nil)
	}
	
    ///////////////////////////////////////////////
	// UITableViewDataSource, UITableViewDelegate Broker
    ///////////////////////////////////////////////
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let myCollectionView = tableView as? BPTableView {
			if let adapter = myCollectionView._adapter {
				return adapter.tableView(tableView, numberOfItemsInSection: section)
			}
		}
		return 0
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if let myCollectionView = tableView as? BPTableView {
			if let adapter = myCollectionView._adapter {
				return adapter.tableView(tableView, cellForItemAt: indexPath)
			}
		}
		return UITableViewCell()
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 35.0
	}

	// built-in selection is not suitable for this app purpose
	/*private func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		print("row = " + String(indexPath.row))
    }*/

    ///////////////////////////////////////////////
	// UIPickerViewDelegate, UIPickerViewDataSource
    ///////////////////////////////////////////////
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return _themeLables.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return _themeLables[row]
    }
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int,
	inComponent component: Int) {
		_parent?._serviceConnection?.sendMessageToService(command:MSG.SET_THEME, intOption: row)
	}
	
    ///////////////////////////////////////////////
    // ThemeLib TableView
    ///////////////////////////////////////////////
	class ThemeLibsAdapter: BPTableViewAdapter {
		override func onTableViewAssigned(collectionView:UITableView) {
			_tableView.register(ThemeLibsCollectionViewCell.self, forCellReuseIdentifier: "themelibscell")
		}
		
		override func selectedRowChanged(row: Int) {
			if (row >= 0) {
				let themeLibItem = _parent._themeLibsList[row]
				_parent.updateListFromCustomConfigString(customConfigString: themeLibItem.Config )
			} else { // -1 means no select
				_parent.updateListFromCustomConfigString(customConfigString: _parent._customConfigString)
			}
			_parent._customWordsListAdapter!.notifyDataSetChanged()
			_parent.updateCustomConfigStringFromList()
		}
		
		override func tableView(cellForItemAt indexPath: IndexPath) -> UITableViewCell {
			// Important to guard due to initial fast double update from local file and server update
			guard let cell = _tableView.dequeueReusableCell(withIdentifier: "themelibscell", for: indexPath) as? ThemeLibsCollectionViewCell else { return ThemeLibsCollectionViewCell() }
			// print("cell = " + _parent._themeLibsList[indexPath.row].Label)
			objc_sync_enter(_parent)
			cell._themeLabel.text = _parent._themeLibsList[indexPath.row].Label
			if (indexPath.row == getSelectedRow()) {
				cell._themeLabel.backgroundColor = CustomConfigDialog._selectedRowColor
			} else {
				cell._themeLabel.backgroundColor = UIColor.white
			}
			if (indexPath.row == 0) {
				cell._trashIcon.isHidden = true
			} else {
				cell._trashIcon.isHidden = false
			}
			objc_sync_exit(_parent)
			return cell
		}
		
        override public func getItemCount() -> Int {
			return _parent._themeLibsList.count
        }
		
		override public func onItemClicked(row: Int, col: Int) {
			print("ThemeLibsAdapter: row = " + String(row) + " col = " + String(col))
			setSelectedRow(selectedRow: row)
			/*if (col == 1) {
				if (_parent.requestUpdateThemeLibrary(label: _parent._themeLibsList[row].Label, config: "")) {
                    // unselect row if it's deleted
                    if (row == getSelectedRow()) {
                        setSelectedRow(selectedRow: -1)
                    }
					_parent._themeLibsList.remove(at: row)
                    _parent._themeLibsListAdapter!.notifyDataSetChanged()
					_parent.updateThemeLibLocalFileFromList()
				}
			}*/
		}
        
		/*
        override func stringForAutoheightOfRow(_ row: Int) -> String {
			return _parent._themeLibsList[row].Label
        }*/
	}
	
	///////////////////////////////////////////////
	// NSMenuDelegate Broker
	///////////////////////////////////////////////
	/*@IBAction func customItemTypePopupMenuClicked(sender: AnyObject?) {
		_customWordsListAdapter?.customItemTypePopupMenuClicked(sender)
	}*/
	
	/*func confinementRect(for: NSMenu, on: NSScreen?) -> NSRect {
		var mouseLocation: NSPoint { NSEvent.mouseLocation }
		return NSRect(x: mouseLocation.x - 520, y: mouseLocation.y - 70, width: 500, height: 500)
	}*/
	
	/*func menuDidClose(_ menu: NSMenu) {
		_customWordsListAdapter?.menuDidClose(menu)
	}*/
	
	///////////////////////////////////////////////
    // CustomWord TableView
    ///////////////////////////////////////////////
	class CustomWordsAdapter: BPTableViewAdapter {
		override func onTableViewAssigned(collectionView:UITableView) {
			_tableView.register(CustomWordsCollectionViewCell.self, forCellReuseIdentifier: "customwordcell")
		}

		private var _custom_row_selected = -1; // for popu pmenu, split from selectedRow to avoid crash around menuDidClose
		
		override func selectedRowChanged(row: Int) {
		}
		
		override func tableView(cellForItemAt indexPath: IndexPath) -> UITableViewCell {
			guard let cell = _tableView.dequeueReusableCell(withIdentifier: "customwordcell", for: indexPath) as? CustomWordsCollectionViewCell else { return CustomWordsCollectionViewCell() }
			// Important to guard due to initial fast double update from local file and server update
			objc_sync_enter(_parent)
			let type = _parent._customWordsList[indexPath.row].WordType
			cell._wordType.image = UIImage(named: _parent._icon_array[type])
			cell._word.text = _parent._customWordsList[indexPath.row].Word
			cell._word.textColor = _parent._color_array[type]
			if (indexPath.row == getSelectedRow()) {
				cell._word.backgroundColor = CustomConfigDialog._selectedRowColor
			} else {
				cell._word.backgroundColor = UIColor.white
			}
			cell._trashIcon.isHidden = false
			if  (_parent._customWordsList[indexPath.row].WordType == 3) {
				if let _ = _parent._reservedWordList.firstIndex(where: { $0.Word == _parent._customWordsList[indexPath.row].Word }) {
					cell._trashIcon.isHidden = true
				}
			}
			objc_sync_exit(_parent)
			return cell
		}
		
		override public func getItemCount() -> Int {
			return _parent._customWordsList.count
		}
		
		/*override public func onItemClicked(row: Int, col: Int) {
			print("CustomWordsAdapter.onItemClicked: row = " + String(row) + " col = " + String(col))
			if (col == 2) {
				if let _ = _parent._reservedWordList.firstIndex(where: { $0.Word == _parent._customWordsList[row].Word }) {
					_parent._customWordsList[row].WordType = 3
					_parent.sortCustomWordList()
				} else {
					_parent._customWordsList.remove(at: row)
				}
				_parent._customWordsListAdapter!.notifyDataSetChanged()
				_parent.updateCustomConfigStringFromList()
			} else if (col == 0) { // Popup Menu
				if let event = NSApplication.shared.currentEvent {
					_custom_row_selected = row
					setSelectedRow(selectedRow: row)
					_parent._customWordsListAdapter?.notifyDataSetChanged()
					for (index, menuItem) in _parent._customWordTypePopupMenu!.items.enumerated() {
						if (index == _parent._customWordsList[row].WordType) {
							menuItem.state = NSControl.StateValue.on
						} else {
							menuItem.state = NSControl.StateValue.off
						}
					}
					NSMenu.popUpContextMenu(_parent._customWordTypePopupMenu, with: event, for: _parent._customWordsTableView)
				}
			}
		}
		
		override func stringForAutoheightOfRow(_ row: Int) -> String {
			return _parent._customWordsList[row].Word
		}
		
		public func menuDidClose(_ menu: NSMenu) {
			setSelectedRow(selectedRow: -1)
			_parent._customWordsListAdapter?.notifyItemChanged(row: _custom_row_selected)
		}
		
		public func customItemTypePopupMenuClicked(_ sender: AnyObject?) {
			if let menuItem = sender as? NSMenuItem {
				if let index = _parent._customWordTypePopupMenu.items.firstIndex(of: menuItem) {
					switch (index) {
						case 0:
							if let reservedIndex = _parent._reservedWordList.firstIndex(where: { $0.Word == _parent._customWordsList[_custom_row_selected].Word }) {
								if _parent._reservedWordList[reservedIndex].WordPath != "" {
									let newCustomWordItem = CustomWord(Word: _parent._reservedWordList[reservedIndex].WordPath, WordType: 0)
									_parent._customWordsList.append(newCustomWordItem)
									break
								}
							} else if let _ = _parent._reservedWordList.firstIndex(where: { $0.WordPath == _parent._customWordsList[_custom_row_selected].Word }) {
								_parent._customWordsList[_custom_row_selected].WordType = 0
								break
							}
							AppUtil.errorAlert(title: "Error", message: "Selected word is not path.")
							break;
						case 1:
							_parent._customWordsList[_custom_row_selected].WordType = 1
							break;
						case 2:
							_parent._customWordsList[_custom_row_selected].WordType = 2
							break;
						case 3:
							_parent._customWordsList[_custom_row_selected].WordType = 3
							break;
						default:
							break;
					}
					_parent.sortCustomWordList()
					notifyDataSetChanged()
					_parent.updateCustomConfigStringFromList()
				}
			}
		}*/
	}
	
    ///////////////////////////////////////////////
    // themeLib json <-> List
    ///////////////////////////////////////////////
	private func updateListFromThemeLibJsonString(themeLibString: String) {
		objc_sync_enter(self)
		let previousSelectedThemeLib = _selectedThemeLib
		_selectedThemeLib = nil
		_themeLibsList.removeAll()
		if (themeLibString != "") {
			_themeLibsList = _themeLibraryInterface.parseThemeLib(themeLibString)
		}
		let currentThemeLib = ThemeLib(Label: "Current", Config: WallpaperServiceInfo.getInstance().getCustomConfigString())
		_themeLibsList.insert(currentThemeLib, at: 0)
        var newSelectedRow = -1
		for (index, themeLibItem) in _themeLibsList.enumerated() {
			if (previousSelectedThemeLib?.Label == themeLibItem.Label) {
				_selectedThemeLib = themeLibItem
				newSelectedRow = index
				break
			}
		}
		_themeLibsListAdapter!.notifyDataSetChanged()
		if (newSelectedRow >= 0) {
			_themeLibsTableView.scrollToRow(at: IndexPath(row: newSelectedRow, section: 0), at: .none, animated: true)
		}
		objc_sync_exit(self)
		// delay row selection until fully populated by notifyDataSetChanged()
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
			self._themeLibsListAdapter!.setSelectedRow(selectedRow: newSelectedRow)
		}
    }

	private func updateThemeLibLocalFileFromList() {
		_themeLibraryInterface.updateThemeLibLocalFileFromList(_themeLibsList)
	}

    ///////////////////////////////////////////////
    // ThemeLibraryInterface Wrappers
    ///////////////////////////////////////////////
	private func requestUpdateThemeLibrary(label: String, config: String) -> Bool {
		return _themeLibraryInterface.requestUpdateThemeLibrary(label: label, config: config, completion: { (response) in
			if let themeLibData = response {
				self.updateListFromThemeLibJsonString(themeLibString: themeLibData)
			}
		})
	}
	
	private func getThemeLibrary() {
		if let themeLibData = _themeLibraryInterface.getThemeLibrary(completion: { (themeLibData) in
			self.updateListFromThemeLibJsonString(themeLibString: themeLibData)
		}) {
			updateListFromThemeLibJsonString(themeLibString: themeLibData)
		}
	}

    ///////////////////////////////////////////////
    // CustomConfigString <-> List
    ///////////////////////////////////////////////
	private func updateListFromCustomConfigString(customConfigString:String) {
		objc_sync_enter(self)
        _customWordsList.removeAll()
        _customConfigString = customConfigString
		var reservedWords = [ReservedWord](_reservedWordList)
        let wpti = ThemeInfo.parseCustomConfig(customConfigString)
		let rootsArray = AppUtil.getWordsArray(wordString: wpti._root)
		let allowWords = AppUtil.getWordsArray(wordString: wpti._allow)
		let filterWords = AppUtil.getWordsArray(wordString: wpti._filter)
        for word in rootsArray {
			_ = addCustomWord(newCustomWord: word, customType: 0)
			if let index = reservedWords.firstIndex(where: { $0.Word == word }) {
				reservedWords.remove(at: index)
			}
        }
        for word in allowWords {
			_ = addCustomWord(newCustomWord: word, customType: 1)
			if let index = reservedWords.firstIndex(where: { $0.Word == word }) {
				reservedWords.remove(at: index)
			}
        }
        for word in filterWords {
			_ = addCustomWord(newCustomWord: word, customType: 2)
			if let index = reservedWords.firstIndex(where: { $0.Word == word }) {
				reservedWords.remove(at: index)
			}
        }
        for word in reservedWords {
			_ = addCustomWord(newCustomWord: word.Word, customType: 3);
        }
		sortCustomWordList()
		objc_sync_exit(self)
    }

    private func updateCustomConfigStringFromList() {
		objc_sync_enter(self)
        var root = "", allow = "", filter = ""
        for customWordItem in _customWordsList {
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
        if (root.count > 0) {
			root = String(root.dropLast())
        }
        if (allow.count > 0) {
            allow = String(allow.dropLast())
        }
        if (filter.count > 0) {
            filter = String(filter.dropLast())
        }
        _customConfigString = root + ";" + allow + ";" + filter
		_customConfigStringTextField.text = _customConfigString
		objc_sync_exit(self)
    }
	
    ///////////////////////////////////////////////
    // custom word utility methods
    ///////////////////////////////////////////////
	private func getReservedWords() {
		if let reservedWordsData = _themeLibraryInterface.getReservedWords(completion: { (reservedWordsData) in
			self.updateReservedWords(reservedWordsData)
		}) {
			updateReservedWords(reservedWordsData)
		}
	}
	
	private func updateReservedWords(_ reservedWordsData: String) {
		objc_sync_enter(self)
		_reservedWordList = _themeLibraryInterface.parseReservedWord(reservedWordsData)
		objc_sync_exit(self)
	}

	private func customWordCompare(custom_item1: CustomWord, custom_item2: CustomWord) -> Bool {
		if (custom_item1.WordType > custom_item2.WordType) {
			return false
		} else if (custom_item1.WordType < custom_item2.WordType) {
			return true
		} else {
			return custom_item1.Word < custom_item2.Word
		}
    }
	
	private func sortCustomWordList() {
		_customWordsList.sort(by: customWordCompare)
    }

	private func addCustomWord(newCustomWord: String, customType: Int) -> Bool {
		if (newCustomWord.firstIndex(of: "|") != nil || newCustomWord.firstIndex(of: ";") != nil ) {
			errorAlert(title: "Error", message: "Word can't include the bar (|) or semi-colon (;) character.")
            return false;
        }
		_customWordsList.append(CustomWord(Word: newCustomWord, WordType: customType))
		return true;
    }

	private func alertDialogWithNewText(title: String, completion: @escaping (String?) -> Void ) {
		let alert = UIAlertController(title: title, message: "", preferredStyle: UIAlertController.Style.alert)
		alert.addTextField(configurationHandler: { (textField: UITextField!) in
			textField.text = ""
		})
		alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler:{ (UIAlertAction)in
			if let textField = alert.textFields?[0] {
				completion(textField.text)
			}
		}))
		alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler:{ (UIAlertAction)in
		}))
		self.present(alert, animated: true, completion: {
		})
    }
	
	private func errorAlert(title: String, message: String) {
		let alert = UIAlertController(title: title, message: "", preferredStyle: UIAlertController.Style.alert)
		self.present(alert, animated: true, completion: {
		})
	}
	
	// UI
	@IBOutlet weak var _themePickerView: UIPickerView!
	@IBOutlet weak var _saverSwitch: UISwitch!
    @IBOutlet weak var _offlineModeSwitch: UISwitch!
	@IBOutlet weak var _intervalSlider: UISlider!
	@IBOutlet weak var _customWordsTableView: BPTableView!
	@IBOutlet weak var _themeLibsTableView: BPTableView!
	@IBOutlet weak var _customConfigStringTextField: UITextField!
	@IBOutlet weak var _saveToLibraryButton:UIButton!
	@IBOutlet weak var _addButton:UIButton!
	@IBOutlet weak var _clearButton:UIButton!
	@IBOutlet weak var _okButton:UIButton!
	@IBOutlet weak var _cancelButton:UIButton!
	//@IBOutlet weak var _customWordTypePopupMenu:NSMenu!
	private var _themeLibsListAdapter: ThemeLibsAdapter? = nil
	private var _customWordsListAdapter: CustomWordsAdapter? = nil

	// Instance Var
	private var _themeLibsList = [ThemeLib]()
	private var _customWordsList = [CustomWord]()
	private var _reservedWordList = [ReservedWord]()
	private var _selectedThemeLib: ThemeLib?
	private var _selectedCustomWord: CustomWord?
	private var _customConfigString = ""
	private var _confirmCustomConfigStringCompletion:(String?) -> Void = {(response) in }
	private let _themeLibraryInterface = ThemeLibraryInterface()
	private var _parent:TromsoIOS9ViewController? = nil

	// Const
	private let _icon_array = [ "folder_mac", "green_light", "red_light", "gray_light" ]
	private let _icon_label = [ "Root", "Allow", "Filter", "Reserved" ]
	private let _color_array = [ UIColor.black,
						UIColor.init(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0),
						UIColor.init(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0),
						UIColor.init(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0) ]
	private let _themeLables = ThemeInfo.getLabels()
	private static let _selectedRowColor = UIColor(red: 255.0 / 255.0, green: 252.0 / 255.0, blue: 153.0 / 255.0, alpha: 1.0)
	private let _defaultCustomConfigString =
					ThemeInfo._default_custom_root + ";" +
					ThemeInfo._default_custom_allow + ";" +
					ThemeInfo._default_custom_filter
}

class BPTableViewAdapter: NSObject {

    init(parent:CustomConfigDialog) {
        _parent = parent
    }
    public func setCollectionView(_ collectionView:UITableView) {
        _tableView = collectionView
        //_defaultRowHeight = _collectionView.rowHeight
		onTableViewAssigned(collectionView: _tableView)
		let tapOnScreen: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onItemClickedInternal(_:)))
		tapOnScreen.cancelsTouchesInView = false
		_tableView.addGestureRecognizer(tapOnScreen)
    }
    public func getSelectedRow() -> Int {
        return _selectedRow;
    }
    public func setSelectedRow(selectedRow: Int) {
        if (selectedRow != _selectedRow) {
            let oldRow = _selectedRow
            _selectedRow = selectedRow;
            if (oldRow >= 0) {
                notifyItemChanged(row:oldRow)
            }
            if (selectedRow >= 0) {
                notifyItemChanged(row:selectedRow)
            }
            selectedRowChanged(row:_selectedRow)
        }
    }
    public func notifyItemChanged(row:Int) {
		_tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
    }
    public func notifyDataSetChanged() {
        DispatchQueue.main.async {
            self._tableView.reloadData()
        }
    }
	@objc private func onItemClickedInternal(_ sender: UITapGestureRecognizer? = nil) {
		if let gestureRecognizer = sender {
			let location = gestureRecognizer.location(in: _tableView)
			if let indexPath = _tableView.indexPathForRow(at: location) {  // indexPath.item == indexPath.row
				print("section = " + String(indexPath.section))
				onItemClicked(row: indexPath.row, col: 0)
			}
		}
	}
    public func tableView(_ collectionView: UITableView, cellForItemAt indexPath: IndexPath) -> UITableViewCell {
		return self.tableView(cellForItemAt: indexPath)
    }
	public func tableView(_ collectionView: UITableView, numberOfItemsInSection section: Int) -> Int {
		return getItemCount()
	}
    public func heightOfRow(_ row: Int) -> CGFloat {
        if (_columnForAutoHeightOfRow > -1) {
            let length = stringForAutoheightOfRow(row).count
            return (CGFloat)((length / Int(_defaultRowHeight) + 1)) * _defaultRowHeight
        }
        return _defaultRowHeight
    }
    public func setColumnForAutoHeightOfRow(_ col:Int) {
        _columnForAutoHeightOfRow = col
    }
    
    // Child must override the followings
    public func getItemCount() -> Int { assert(true); return 0 }
    public func tableView(cellForItemAt indexPath: IndexPath) -> UITableViewCell { assert(true); return UITableViewCell() }
    // Child may override the followings
    public func stringForAutoheightOfRow(_ row:Int) -> String { return "" }
    public func selectedRowChanged(row:Int) { }
    public func onItemClicked(row:Int, col:Int) {  }
	public func onTableViewAssigned(collectionView:UITableView) {  }

	// Propery
    private var _columnForAutoHeightOfRow:Int = -1
    private var _selectedRow = -1
    private var _defaultRowHeight:CGFloat = 17 as CGFloat
    public var _tableView: UITableView!
    public var _parent:CustomConfigDialog
}

class BPTableView:UITableView {
    func setAdapter(adapter:BPTableViewAdapter) {
        _adapter = adapter
        _adapter.setCollectionView(self)
    }
    public var _adapter:BPTableViewAdapter!
}

class ThemeLibsCollectionViewCell: UITableViewCell {
    public let _themeLabel: UILabel = {
        let label = UILabel()
		label.font = UIFont.systemFont(ofSize: 14)
		label.textColor = UIColor.black
        label.text = ""
        label.translatesAutoresizingMaskIntoConstraints = false
		label.frame = CGRect(x: 0, y: 0, width: 120, height: 40)
        return label
    }()
	public let _trashIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.clear
        imageView.image = UIImage(named: "trash")
        imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.frame = CGRect(x: 130, y: 0, width: 30, height: 30)
        return imageView
    }()
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		makeCollectionViewCellByAddViews()
	 }
	func makeCollectionViewCellByAddViews() {
		//self.accessoryView = _trashIcon
		//self.accessoryType = .detailDisclosureButton
		backgroundColor = UIColor.clear
		addSubview(_themeLabel)
		addSubview(_trashIcon)
		_themeLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 0).isActive = true
        _themeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
		_themeLabel.widthAnchor.constraint(equalTo: self.contentView.widthAnchor).isActive = true
        _themeLabel.heightAnchor.constraint(equalToConstant: 100).isActive = false
		_trashIcon.leftAnchor.constraint(equalTo: leftAnchor, constant: 130).isActive = false
        _trashIcon.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        _trashIcon.widthAnchor.constraint(equalToConstant: 30).isActive = false
        _trashIcon.heightAnchor.constraint(equalToConstant: 30).isActive = false
		_trashIcon.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 5.0).isActive = true
	}
	 required init?(coder aDecoder: NSCoder) {
	   super.init(coder: aDecoder)
	}
}

class CustomWordsCollectionViewCell: UITableViewCell {
	public let _wordType: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.clear
        imageView.image = UIImage(named: "green_light")
        imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        return imageView
    }()
    public let _word: UILabel = {
        let label = UILabel()
		label.font = UIFont.systemFont(ofSize: 14)
		label.textColor = UIColor.black
        label.text = ""
        label.translatesAutoresizingMaskIntoConstraints = false
		label.frame = CGRect(x: 50, y: 0, width: 120, height: 40)
        return label
    }()
	public let _trashIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.clear
        imageView.image = UIImage(named: "trash")
        imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.frame = CGRect(x: 180, y: 0, width: 30, height: 30)
        return imageView
    }()
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		makeCollectionViewCellByAddViews()
	 }
	func makeCollectionViewCellByAddViews() {
		backgroundColor = UIColor.clear
		addSubview(_wordType)
		addSubview(_word)
		addSubview(_trashIcon)
		_wordType.leftAnchor.constraint(equalTo: leftAnchor, constant: 0).isActive = true
        _wordType.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        _wordType.widthAnchor.constraint(equalToConstant: 30).isActive = false
        _wordType.heightAnchor.constraint(equalToConstant: 30).isActive = false
		_word.leftAnchor.constraint(equalTo: leftAnchor, constant: 50).isActive = true
        _word.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
		_word.widthAnchor.constraint(equalTo: self.contentView.widthAnchor).isActive = true
        _word.heightAnchor.constraint(equalToConstant: 100).isActive = false
		_trashIcon.leftAnchor.constraint(equalTo: leftAnchor, constant: 180).isActive = false
        _trashIcon.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = false
        _trashIcon.widthAnchor.constraint(equalToConstant: 30).isActive = false
        _trashIcon.heightAnchor.constraint(equalToConstant: 30).isActive = false
		_trashIcon.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 5.0).isActive = true
	}
	 required init?(coder aDecoder: NSCoder) {
	   super.init(coder: aDecoder)
	}
}

