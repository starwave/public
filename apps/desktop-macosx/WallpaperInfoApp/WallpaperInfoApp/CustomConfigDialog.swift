//
//  CustomConfigDialog.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 8/30/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import AppKit
import Cocoa

var _customConfigDialog: CustomConfigDialog?

class CustomConfigDialog : NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate {

	// it's called from WallpaperInfoUI
	static func openCustomConfigDialog(window:NSWindow, completion: @escaping (String?) -> Void) {
		let customConfigWindowController = CustomConfigDialog(windowNibName: "CustomConfigDialog")
		customConfigWindowController.window?.setFrameOrigin(NSPoint(x: window.frame.minX, y: window.frame.minY))
		customConfigWindowController._confirmCustomConfigStringCompletion = completion
		if let modal_window = customConfigWindowController.window {
			NSApp.runModal(for: modal_window)
		}
	}
	
    override func windowDidLoad() {
        super.windowDidLoad()
		print("CustomConfigDialog - windowDidLoad")
        // must assign to retain the instance of WallpaperInfoWindowController
        _customConfigDialog = self
		self.window?.delegate = self
		_themeLibsListAdapter = ThemeLibsAdapter(parent:self)
        _themeLibsListAdapter!.setColumnForAutoHeightOfRow(0)
		_themeLibsTableView.setAdapter(adapter: _themeLibsListAdapter!)
		_customWordsListAdapter = CustomWordsAdapter(parent:self)
		_customWordsListAdapter!.setColumnForAutoHeightOfRow(1)
		_customWordsTableView.setAdapter(adapter: _customWordsListAdapter!)

        // show library the first with the local file
		getReservedWords()
        getThemeLibrary()
		_themeLibsListAdapter?.setSelectedRow(selectedRow: 0)

		// Setup Popup menu
		Bundle.main.loadNibNamed("CustomWordTypePopupMenu", owner: self, topLevelObjects:nil)
		_customWordTypePopupMenu.delegate = self
    }
	
	@IBAction func saveToLibraryBtnPressed(sender: AnyObject?) {
        BPUtil.BPLog("CustomConfigDialog - saveToLibraryBtnPressed")
		let currentRow = _themeLibsListAdapter!.getSelectedRow();
		if (currentRow == 0 || currentRow == -1) { // adding new theme library
			alertDialogWithNewText(title: "New Theme Label", completion: { (wordFromAlertDialog) in
				if let newWordFromAlertDialog = wordFromAlertDialog {
					if (newWordFromAlertDialog != "") {
						if (self.requestUpdateThemeLibrary(label: newWordFromAlertDialog, config: self._customConfigString)) {
							objc_sync_enter(self)
							let themeLibItem = ThemeLib(Label: newWordFromAlertDialog, Config: self._customConfigString)
							self._themeLibsList.append(themeLibItem)
							self._themeLibsListAdapter!.notifyDataSetChanged()
							self._themeLibsListAdapter!.setSelectedRow(selectedRow: self._themeLibsList.count - 1)
							self.updateThemeLibLocalFileFromList()
							objc_sync_exit(self)
						} else {
							AppUtil.errorAlert(title: "Error", message: "Can't add new theme to the library.")
						}
					}
				}
			})
		} else { // modifying existing theme libarary
			if (requestUpdateThemeLibrary(label: _themeLibsList[currentRow].Label, config: _customConfigString)) {
				objc_sync_enter(self)
				_themeLibsList[currentRow].Config = _customConfigString
				updateThemeLibLocalFileFromList()
				objc_sync_exit(self)
			} else {
				AppUtil.errorAlert(title: "Error", message: "Can't update selected theme to the library.")
			}
		}
	}

	@IBAction func addBtnPressed(sender: AnyObject?) {
        BPUtil.BPLog("CustomConfigDialog - addBtnPressed")
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
        BPUtil.BPLog("CustomConfigDialog - clearBtnPressed")
		_customConfigString = WallpaperInfoUI._defaultCustomConfigString;
		_themeLibsListAdapter!.setSelectedRow(selectedRow: -1);
	}

	@IBAction func okBtnPressed(sender: AnyObject?) {
        BPUtil.BPLog("CustomConfigDialog - okBtnPressed")
		_confirmCustomConfigStringCompletion(_customConfigString)
		NSApp.stopModal()
		self.close()
	}

	@IBAction func cancelBtnPressed(sender: AnyObject?) {
        BPUtil.BPLog("CustomConfigDialog - cancelBtnPressed")
		NSApp.stopModal()
		self.close()
	}
	
	// NSTableViewDataSource, NSTableViewDelegate Broker
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		if let myTableView = tableView as? BPTableView {
			if let adapter = myTableView._adapter {
				return adapter.tableView(tableView, viewFor: tableColumn, row: row)
			}
		}
		return nil
	}

	func numberOfRows(in tableView: NSTableView) -> Int {
		if let myTableView = tableView as? BPTableView {
			if let adapter = myTableView._adapter {
				return adapter.getItemCount()
			}
		}
		return 0
	}
	
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		if let myTableView = tableView as? BPTableView {
			if let adapter = myTableView._adapter {
				return adapter.heightOfRow(row)
			}
		}
		return 0
	}
	
    ///////////////////////////////////////////////
    // ThemeLib TableView
    ///////////////////////////////////////////////
	class ThemeLibsAdapter: BPTableViewAdapter {
		override func selectedRowChanged(row: Int) {
			if (row >= 0) {
				let themeLibItem = _parent._themeLibsList[row]
				_parent.updateListFromCustomConfigString(customConfigString: themeLibItem.Config )
			} else { // no selection update for clear button
				_parent.updateListFromCustomConfigString(customConfigString: _parent._customConfigString)
			}
			_parent.updateCustomConfigStringFromList()
		}
		
		override func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int, col: Int) -> NSView? {
			guard let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else { return nil }
			// Important to lock due to initial fast double update from local file and server update,
			objc_sync_enter(_parent)
			switch (col) {
				case 0:
					cell.textField?.stringValue = _parent._themeLibsList[row].Label
					cell.textField?.drawsBackground = true
					if (row == getSelectedRow()) {
						cell.textField?.backgroundColor = CustomConfigDialog._selectedRowColor
					} else {
						cell.textField?.backgroundColor = NSColor.textBackgroundColor
					}
					break
				case 1:
					if (row == 0) {
						cell.isHidden = true
					} else {
						cell.isHidden = false
					}
					break
				default:
					break
			}
			objc_sync_exit(_parent)
			return cell
		}
		
        override public func getItemCount() -> Int {
			return _parent._themeLibsList.count
        }
		
		override public func onItemClicked(row: Int, col: Int) {
            BPUtil.BPLog("ThemeLibsAdapter: row = " + String(row) + " col = " + String(col))
			if (col == 1) {
				if (_parent.requestUpdateThemeLibrary(label: _parent._themeLibsList[row].Label, config: "")) {
					// in case http is faster than inline step
					objc_sync_enter(self)
					var previousThemeLabel = ""
					let selectedRow = getSelectedRow()
                    // unselect row if it's deleted
                    if (row == selectedRow) {
                        setSelectedRow(selectedRow: -1)
					} else {
						previousThemeLabel = _parent._themeLibsList[selectedRow].Label
					}
					_parent._themeLibsList.remove(at: row)
					// move selected row in case it's affected by deletion
					for (index, themeLibItem) in _parent._themeLibsList.enumerated() {
						if (previousThemeLabel == themeLibItem.Label) {
							setSelectedRow(selectedRow: index)
							break
						}
					}
                    _parent._themeLibsListAdapter!.notifyDataSetChanged()
					_parent.updateThemeLibLocalFileFromList()
					objc_sync_exit(self)
				}
			} else {
				setSelectedRow(selectedRow: row)
			}
		}
        
        override func stringForAutoheightOfRow(_ row: Int) -> String {
			return _parent._themeLibsList[row].Label
        }
	}
	
	///////////////////////////////////////////////
	// NSMenuDelegate Broker
	///////////////////////////////////////////////
	@IBAction func customItemTypePopupMenuClicked(sender: AnyObject?) {
		_customWordsListAdapter?.customItemTypePopupMenuClicked(sender)
	}
	
	func confinementRect(for: NSMenu, on: NSScreen?) -> NSRect {
		var mouseLocation: NSPoint { NSEvent.mouseLocation }
		return NSRect(x: mouseLocation.x - 520, y: mouseLocation.y - 70, width: 500, height: 500)
	}
	
	func menuDidClose(_ menu: NSMenu) {
		_customWordsListAdapter?.menuDidClose(menu)
	}
	
	///////////////////////////////////////////////
    // CustomWord TableView
    ///////////////////////////////////////////////
	class CustomWordsAdapter: BPTableViewAdapter {
		
		private var _custom_row_selected = -1; // for popu pmenu, split from selectedRow to avoid crash around menuDidClose
		
		override func selectedRowChanged(row: Int) {
		}
		
		override func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int, col: Int) -> NSView? {
			guard let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else { return nil }
			// Important to lock due to initial fast double update from local file and server update,
			objc_sync_enter(_parent)
			let type = _parent._customWordsList[row].WordType
            let icon_array = [ "folder_mac", "green_light", "red_light", "gray_light" ]
			let color_array = [ NSColor.textColor,
								NSColor.init(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0),
								NSColor.init(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0),
								NSColor.lightGray ]
			switch (col) {
				case 0:
					cell.imageView?.image = NSImage(named: icon_array[type])
					break
				case 1:
					cell.textField?.stringValue = _parent._customWordsList[row].Word
					cell.textField?.textColor = color_array[type]
					cell.textField?.drawsBackground = true
					if (row == getSelectedRow()) {
						cell.textField?.backgroundColor = CustomConfigDialog._selectedRowColor
					} else {
                        cell.textField?.backgroundColor = NSColor.textBackgroundColor;
					}
					break
				case 2:
					if  (_parent._customWordsList[row].WordType == 3) {
						if let _ = _parent._reservedWordList.firstIndex(where: { $0.Word == _parent._customWordsList[row].Word }) {
							cell.imageView?.isHidden = true
							break
						}
					}
					cell.imageView?.isHidden = false
					break
				default:
					break
			}
			objc_sync_exit(_parent)
			return cell
		}
		
		override public func getItemCount() -> Int {
			return _parent._customWordsList.count
		}
		
		override public func onItemClicked(row: Int, col: Int) {
            BPUtil.BPLog("CustomWordsAdapter.onItemClicked: row = " + String(row) + " col = " + String(col))
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
		}
	}
	
    ///////////////////////////////////////////////
    // themeLib json <-> List
    ///////////////////////////////////////////////
	private func updateListFromThemeLibJsonString(themeLibString: String) {
		objc_sync_enter(self)
		var previousThemeLabel = "Current"
		var newSelectedRow = -1
		let selectedRow = _themeLibsListAdapter!.getSelectedRow()
		if (selectedRow >= 0) {
			previousThemeLabel = _themeLibsList[selectedRow].Label
		}
		_themeLibsList.removeAll()
		if (themeLibString != "") {
			_themeLibsList = _themeLibraryInterface.parseThemeLib(themeLibString)
		}
		let currentThemeLib = ThemeLib(Label: "Current", Config: WallpaperServiceInfo.getInstance().getCustomConfigString())
		_themeLibsList.insert(currentThemeLib, at: 0)
		for (index, themeLibItem) in _themeLibsList.enumerated() {
			if (previousThemeLabel == themeLibItem.Label) {
				newSelectedRow = index
				break
			}
		}
		_themeLibsListAdapter?.notifyDataSetChanged()
		_themeLibsListAdapter?.setSelectedRow(selectedRow: newSelectedRow)
		objc_sync_exit(self)
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
        _customWordsListAdapter!.notifyDataSetChanged()
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
		_customConfigStringTextField.stringValue = _customConfigString
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
			AppUtil.errorAlert(title: "Error", message: "Word can't include the bar (|) or semi-colon (;) character.")
            return false;
        }
		_customWordsList.append(CustomWord(Word: newCustomWord, WordType: customType))
		return true;
    }

	private func alertDialogWithNewText(title: String, completion: @escaping (String?) -> Void ) {
		let alert = NSAlert()
		alert.messageText = title
		alert.informativeText = ""
		alert.addButton(withTitle: "Ok")
		alert.addButton(withTitle: "Cancel")
		let textField = NSTextField(frame: CGRect(x: 20, y: 80, width: 300, height: 20))
		alert.accessoryView = textField
		alert.window.initialFirstResponder = textField
		let button = alert.runModal()
		if (button == NSApplication.ModalResponse.alertFirstButtonReturn) {
			completion(textField.stringValue)
		} else if (button == NSApplication.ModalResponse.alertSecondButtonReturn) {
			completion("")
		}
    }
	
	// UI
	@IBOutlet weak var _customWordsTableView: BPTableView!
	@IBOutlet weak var _themeLibsTableView: BPTableView!
	@IBOutlet weak var _customConfigStringTextField: NSTextField!
	@IBOutlet weak var _saveToLibraryButton:NSButton!
	@IBOutlet weak var _addButton:NSButton!
	@IBOutlet weak var _clearButton:NSButton!
	@IBOutlet weak var _okButton:NSButton!
	@IBOutlet weak var _cancelButton:NSButton!
	@IBOutlet weak var _customWordTypePopupMenu:NSMenu!
	private var _themeLibsListAdapter: ThemeLibsAdapter? = nil
	private var _customWordsListAdapter: CustomWordsAdapter? = nil

	// Instance Var
	private var _themeLibsList = [ThemeLib]()
	private var _customWordsList = [CustomWord]()
	private var _reservedWordList = [ReservedWord]()
	private var _customConfigString = ""
	private var _confirmCustomConfigStringCompletion:(String?) -> Void = {(response) in }
	private let _themeLibraryInterface = ThemeLibraryInterface()

	// Const
    private static let _selectedRowColor = NSColor.init(red: 128.0 / 255.0, green: 128.0 / 255.0, blue: 64.0 / 255.0, alpha: 1.0)
}

class BPTableViewAdapter {

    init(parent:CustomConfigDialog) {
        _parent = parent
    }
    
    public func setTableView(_ tableView:NSTableView) {
        _tableView = tableView
        _tableView.action = #selector(onItemClickedInternal)
        _tableView.target = self
        _defaultRowHeight = _tableView.rowHeight
    }
    
    @objc private func onItemClickedInternal() {
        if (_tableView.clickedRow >= 0 && _tableView.clickedColumn >= 0) {
            onItemClicked(row: _tableView.clickedRow, col: _tableView.clickedColumn)
        }
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
        _tableView.reloadData(forRowIndexes: IndexSet(integer: row),
                              columnIndexes: IndexSet(0 ... _tableView.numberOfColumns - 1))
    }
    
    public func notifyDataSetChanged() {
        DispatchQueue.main.async {
            self._tableView.reloadData()
        }
    }

    public func tableView(_ tableView:NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let index = _tableView.tableColumns.firstIndex(of: tableColumn!) {
            return self.tableView(tableView, viewFor:tableColumn, row: row, col: index)
        }
        return nil
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
    public func tableView(_ tableView:NSTableView, viewFor tableColumn: NSTableColumn?, row: Int, col: Int) -> NSView? { assert(true); return nil }
    // Child may override the followings
    public func stringForAutoheightOfRow(_ row:Int) -> String { return "" }
    public func selectedRowChanged(row:Int) { }
    public func onItemClicked(row:Int, col:Int) {  }

    private var _columnForAutoHeightOfRow:Int = -1
    private var _selectedRow = -1
    private var _defaultRowHeight:CGFloat = 17 as CGFloat
    private var _tableView: NSTableView = NSTableView()
    public var _parent:CustomConfigDialog
}

class BPTableView:NSTableView {
    func setAdapter(adapter:BPTableViewAdapter) {
        _adapter = adapter
        _adapter.setTableView(self)
    }
    public var _adapter:BPTableViewAdapter!
}

struct CustomWord {
    var Word:String
    var WordType:Int
}

