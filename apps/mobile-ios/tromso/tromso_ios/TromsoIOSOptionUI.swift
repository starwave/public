//
//  TromsoIOSOptionUI.swift
//  tromso_ios
//
//  Created by Brad Park on 9/11/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import SwiftUI

struct CustomWord:Identifiable, Hashable {
	let id = UUID()
	var Word:String
	var WordType:Int
}

extension TromsoOptionUI {
    init(parent:ContentView, completion: @escaping (String?) -> Void) {
		_parent = parent
		_confirmCustomConfigStringCompletion = completion
    }
}

struct TromsoOptionUI: View {
	// UI
	@State private var _selectedThemeIndex = 0
	@State private var _themePickerVisible = false
	@State private var _typePickerVisible = false
	@State private var _interval = 7.0
	@State private var _showsNewWordAlert = false
	@State private var _showsNewLabelAlert = false
	@State private var _selectedType = 0
	@State private var _saver = true
    @State private var _offlineMode = false

	// Instance Var
	@State private var _themeLibsList = [ThemeLib]()
	@State private var _customWordsList = [CustomWord]()
	@State private var _reservedWordList = [ReservedWord]()
	@State private var _selectedThemeLib: ThemeLib?
	@State private var _selectedCustomWord: CustomWord?
	@State private var _customConfigString = ""
	private var _confirmCustomConfigStringCompletion: (String?) -> Void
	private var _parent:ContentView
	private let _themeLibraryInterface = ThemeLibraryInterface()

	var body: some View {
		ZStack() {
			VStack {
				HStack {
					Button(_themeLables[_selectedThemeIndex]) {
						self._themePickerVisible.toggle()
					}
				}
				.font(.system(size: CGFloat(22)))
				.frame(height:CGFloat(60))
				if self._themePickerVisible {
					Spacer()
					Picker(selection: $_selectedThemeIndex.onChange(onThemeChange), label: Text("  Theme")) {
                        ForEach(0 ..< _themeLables.count, id: \.self) { index in
                            Text(self._themeLables[index])
                        }
					}
					.onTapGesture {
						self._themePickerVisible.toggle()
					}
					Spacer()
				}
				HStack {
                    VStack {
                        Button (action: {
                            self._offlineMode.toggle()
                            self._parent._serviceConnection?.sendMessageToService(command:MSG.SET_OFFLINE_MODE, intOption: (self._offlineMode) ? 1 : 0)
                        }){
                            HStack(spacing: 20) {
                                Image(systemName: self._offlineMode ? "checkmark.square.fill" : "square")
                                    .foregroundColor(self._offlineMode ? Color(UIColor.systemBlue) : Color.secondary)
                                Text("Offline")
                            }
                        }
                        .background(Color.clear)
                        .buttonStyle(PlainButtonStyle())
                        Button (action: {
                            self._saver.toggle()
                            self._parent._serviceConnection?.sendMessageToService(command:MSG.SET_SAVER, intOption: (self._saver) ? 1 : 0)
                        }){
                            HStack(spacing: 20) {
                                Image(systemName: self._saver ? "checkmark.square.fill" : "square")
                                    .foregroundColor(self._saver ? Color(UIColor.systemBlue) : Color.secondary)
                                Text("Saver")
                            }
                        }
                        .background(Color.clear)
                        .buttonStyle(PlainButtonStyle())
                    }.padding()
                    Slider(value: $_interval, in: 5...20, step: 1, onEditingChanged: {_ in
                        self._parent._serviceConnection?.sendMessageToService(command:MSG.SET_INTERVAL, intOption: Int(self._interval))
                    })
                    .padding()
				}
				MultilineTextView(text: self.$_customConfigString, onTextEdited:{(newText) in
					self._selectedThemeLib = nil
					self.updateListFromCustomConfigString(customConfigString: newText)
					self.updateCustomConfigStringFromList()
					self._confirmCustomConfigStringCompletion(self._customConfigString)
				})
				.foregroundColor(Color.blue)
				.font(.callout)
				.frame(minWidth: CGFloat(0), maxWidth: .infinity, minHeight: CGFloat(0), maxHeight: CGFloat(100), alignment: .topLeading)
				HStack {
					Button(action: {
						if (self._selectedThemeLib == nil || self._selectedThemeLib!.Label == "Current") {
							self._showsNewLabelAlert = true
						} else {
							if (self.requestUpdateThemeLibrary(label: self._selectedThemeLib!.Label, config: self._customConfigString)) {
								self._selectedThemeLib!.Config = self._customConfigString
							} else {
								self.errorAlert(title: "Error", message: "Can't update selected theme to the library.")
							}
						}
					}) {
						HStack {
						Text("Save to Library")
						}
						.frame(width: 130, height:12)
						.padding()
						.foregroundColor(.white)
						.background(LinearGradient(gradient: Gradient(colors: [Color.init(red: 0.0, green: 0.2, blue: 0.2),
																			   Color.init(red: 0.0, green: 0.7, blue: 0.7)]), startPoint: .leading, endPoint: .trailing))
						.cornerRadius(15)
						.padding(.horizontal, 3)
					}
					Button(action: {
						self._showsNewWordAlert = true
					}) {
						HStack {
						Text("Add")
						}
						.frame(width: 65, height:12)
						.padding()
						.foregroundColor(.white)
						.background(LinearGradient(gradient: Gradient(colors: [Color.init(red: 0.0, green: 0.2, blue: 0.2),
																			   Color.init(red: 0.0, green: 0.7, blue: 0.7)]), startPoint: .leading, endPoint: .trailing))
						.cornerRadius(15)
						.padding(.horizontal, 3)
					}
					Button(action: {
						self._customConfigString = self._defaultCustomConfigString
						self.updateListFromCustomConfigString(customConfigString: self._customConfigString)
						self._selectedThemeLib = nil
					}) {
						HStack {
						Text("Clear")
						}
						.frame(width: 65, height:12)
						.padding()
						.foregroundColor(.white)
						.background(LinearGradient(gradient: Gradient(colors: [Color.init(red: 0.0, green: 0.2, blue: 0.2),
																			   Color.init(red: 0.0, green: 0.7, blue: 0.7)]), startPoint: .leading, endPoint: .trailing))
						.cornerRadius(15)
						.padding(.horizontal, 3)
					}
				}
				HStack {
					List {
						ForEach(_themeLibsList, id: \.self) { themeLib in
							HStack {
								Text("\(themeLib.Label)")
									.frame(minWidth: 80.0)
									.font(.system(size: CGFloat(12)))
									.background((themeLib.Label == self._selectedThemeLib?.Label) ? self._selectedRowColor : Color(UIColor.systemBackground))
									.gesture(TapGesture()
								  	.onEnded({ _ in
										self._customConfigString = themeLib.Config
										self._selectedThemeLib = themeLib
										self.updateListFromCustomConfigString(customConfigString: self._customConfigString)
										self._confirmCustomConfigStringCompletion(self._customConfigString)
									}))
								Spacer()
								if (themeLib.Label != "Current") {
									Image(uiImage: UIImage(named: "trash")!)
										.frame(width: 20.0)
										.gesture(TapGesture()
										.onEnded({ _ in
											if (self.requestUpdateThemeLibrary(label: themeLib.Label, config: "")) {
												if (self._selectedThemeLib?.Label == themeLib.Label) {
													self._selectedThemeLib = nil
												}
												if let index = self._themeLibsList.firstIndex(of: themeLib) {
													self._themeLibsList.remove(at: index)
												}
											}
										}))
								}
							}
						}
						.onDelete { (indexSet) in
							if (indexSet.first! == 0) {
								return
							}
							if (self.requestUpdateThemeLibrary(label: self._themeLibsList[indexSet.first!].Label, config: "")) {
								if (self._selectedThemeLib?.Label == self._themeLibsList[indexSet.first!].Label) {
									self._selectedThemeLib = nil
								}
								self._themeLibsList.remove(atOffsets: indexSet)
							}
						}
					}
					.frame(minWidth:100.0)
					.background(
						Color(UIColor.init(red: 0.7, green: 0.7, blue: 0.7, alpha: 0.1))
						.shadow(radius: 5)
					)
					if self._typePickerVisible {
						Picker(selection: self.$_selectedType, label: Text("")) {
                            ForEach(0 ..< self._icon_array.count, id: \.self) { i in
                                HStack {
                                    Image(uiImage: UIImage(named: self._icon_array[i])!)
                                    Text(self._icon_label[i])
                                        .font(.system(size: 14.0))
                                        .foregroundColor(self._color_array[i])
                                }
                                .tag(i)
                            }
						}
						.onTapGesture {
							self.onTypeChange(self._selectedType)
							self._typePickerVisible.toggle()
							self._selectedCustomWord =  self._typePickerVisible ? self._selectedCustomWord : nil
						}
						.frame(width: 120.0)
					}
					List {
						ForEach(_customWordsList, id: \.self) { customWord in
							HStack {
								Image(uiImage: UIImage(named: self._icon_array[customWord.WordType])!)
									.frame(width: 20.0)
									.gesture(TapGesture()
									.onEnded({ _ in
										self._selectedType = customWord.WordType
										self._typePickerVisible.toggle()
										self._selectedCustomWord =  self._typePickerVisible ? customWord : nil
									}))
								Text("\(customWord.Word)")
									.frame(minWidth: 100.0)
									.font(.system(size: 12.0))
									.foregroundColor(self._color_array[customWord.WordType])
									.background((customWord.Word == self._selectedCustomWord?.Word) ? self._selectedRowColor : Color(UIColor.systemBackground))
								Spacer()
								if (customWord.WordType != 3 || self._reservedWordList.firstIndex(where: { $0.Word == customWord.Word }) == nil) {
									Image(uiImage: UIImage(named: "trash")!)
										.frame(width: 20.0)
										.gesture(TapGesture()
										.onEnded({ _ in
											if let index = self._customWordsList.firstIndex(of: customWord) {
												self.removeCustomWord(index: index)
											}
										}))
								}
							}
						}
						.onDelete { (indexSet) in
							if let index = indexSet.first {
								self.removeCustomWord(index: index)
							}
						}
					}
					.frame(minWidth: 120.0)
					.background(
						Color(UIColor.init(red: 0.7, green: 0.7, blue: 0.7, alpha: 0.1))
						.shadow(radius: 5)
					)

				}
			}
		}
		.onAppear() {
			let wpsi = WallpaperServiceInfo.getInstance()
			self._themeLibsList.removeAll()
			let currentThemeLib = ThemeLib(Label: "Current", Config: wpsi.getCustomConfigString())
			self._selectedThemeLib = currentThemeLib
			self.getReservedWords()
			self._customConfigString = currentThemeLib.Config
			self.updateListFromCustomConfigString(customConfigString: currentThemeLib.Config)
			self.getThemeLibrary()
			self._selectedThemeIndex = wpsi.getTheme().intValue
			self._saver = wpsi.getSaver()
            self._offlineMode = wpsi.getOfflineMode()
			self._interval = Double(wpsi.getInterval())
		}
		.alert(isPresented: $_showsNewWordAlert, TextAlert(title: "New Word", action: {
			if let newWordFromAlertDialog = $0 {
				if (newWordFromAlertDialog != "" && self.addCustomWord(newCustomWord: newWordFromAlertDialog, customType: 1)) {
					self.sortCustomWordList()
					self.updateCustomConfigStringFromList()
					self._confirmCustomConfigStringCompletion(self._customConfigString)
				}
			}
		}))
		.alert(isPresented: $_showsNewLabelAlert, TextAlert(title: "New Theme Label", action: {
			if let newLabelFromAlertDialog = $0 {
				let themeLibItem = ThemeLib(Label: newLabelFromAlertDialog, Config: self._customConfigString)
				if (self.requestUpdateThemeLibrary(label: newLabelFromAlertDialog, config: self._customConfigString)) {
					self._selectedThemeLib = themeLibItem
					self._themeLibsList.append(themeLibItem)
					self.updateThemeLibLocalFileFromList()
				} else {
					self.errorAlert(title: "Error", message: "Can't add new theme to the library.")
				}
			}
		}))
		.alert(isPresented: $_showsErrorAlert) {
			Alert(title: Text(self._errorTitle), message: Text(self._errorMessage), dismissButton: .default(Text("OK")))
		}
	}
	
	func onThemeChange(_ tag:Int) {
		self._parent._serviceConnection?.sendMessageToService(command:MSG.SET_THEME, intOption: self._selectedThemeIndex)
	}
	
	func onTypeChange(_ tag:Int) {
		if let currentWord = _selectedCustomWord {
			print("Current Word = " + currentWord.Word + ", Index = " + String(tag))
			if let index = self._customWordsList.firstIndex(of: currentWord) {
				switch (tag) {
					case 0:
						if let reservedIndex = _reservedWordList.firstIndex(where: { $0.Word == _customWordsList[index].Word }) {
							if _reservedWordList[reservedIndex].WordPath != "" {
								let newCustomWordItem = CustomWord(Word: _reservedWordList[reservedIndex].WordPath, WordType: 0)
								_customWordsList.append(newCustomWordItem)
								break
							}
						} else if let _ = _reservedWordList.firstIndex(where: { $0.WordPath == _customWordsList[index].Word }) {
							_customWordsList[index].WordType = 0
							break
						}
						self.errorAlert(title: "Error", message: "Selected word is not path.")
						break;
					case 1:
						_customWordsList[index].WordType = 1
						break;
					case 2:
						_customWordsList[index].WordType = 2
						break;
					case 3:
						_customWordsList[index].WordType = 3
						break;
					default:
						break;
				}
				sortCustomWordList()
				updateCustomConfigStringFromList()
				self._confirmCustomConfigStringCompletion(self._customConfigString)
			}
		}
	}
	
	func removeCustomWord(index: Int) {
		if let _ = _reservedWordList.firstIndex(where: { $0.Word == _customWordsList[index].Word }) {
			_customWordsList[index].WordType = 3
			sortCustomWordList()
		} else {
			_customWordsList.remove(at: index)
		}
		updateCustomConfigStringFromList()
		_confirmCustomConfigStringCompletion(self._customConfigString)
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
		let currentThemeLib = ThemeLib(Label: "Current", Config: self._customConfigString)
		_themeLibsList.insert(currentThemeLib, at: 0)
		for themeLibItem in _themeLibsList {
			if (previousSelectedThemeLib?.Label == themeLibItem.Label) {
				_selectedThemeLib = themeLibItem
				break
			}
		}
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
			self.errorAlert(title: "Error", message: "Word can't include the bar (|) or semi-colon (;) character.")
            return false;
        }
		_customWordsList.append(CustomWord(Word: newCustomWord, WordType: customType))
		return true;
    }
	
    ///////////////////////////////////////////////
    // Show Error Alert
    ///////////////////////////////////////////////
	@State private var _showsErrorAlert = false
	@State private var _errorTitle = ""
	@State private var _errorMessage = ""
	private func errorAlert(title:String, message:String) {
		_errorTitle = title
		_errorMessage = message
		_showsErrorAlert = true
	}
	
	///////////////////////////////////////////////
	// Properties
	///////////////////////////////////////////////
	private let _icon_array = [ "folder_mac", "green_light", "red_light", "gray_light" ]
	private let _icon_label = [ "Root", "Allow", "Filter", "Reserved" ]
	private let _color_array = [ Color.black,
						Color.init(red: 0.0, green: 0.5, blue: 0.0),
						Color.init(red: 0.5, green: 0.0, blue: 0.0),
						Color.init(red: 0.75, green: 0.75, blue: 0.75) ]
	private let _themeLables = ThemeInfo.getLabels()
    private let _selectedRowColor = Color.init(red: 255.0 / 255.0, green: 252.0 / 255.0, blue: 153.0 / 255.0)
	private let _defaultCustomConfigString =
					ThemeInfo._default_custom_root + ";" +
					ThemeInfo._default_custom_allow + ";" +
					ThemeInfo._default_custom_filter
}

struct TromsoOptionUI_Previews: PreviewProvider {
    static var previews: some View {
		TromsoOptionUI(parent:ContentView(), completion: { _ in })
    }
}

///////////////////////////////////////////////
// onChange for Picker change monitor
///////////////////////////////////////////////
extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        return Binding(
            get: { self.wrappedValue },
            set: { selection in
                self.wrappedValue = selection
                handler(selection)
        })
    }
}

///////////////////////////////////////////////
// Multiline Text View
///////////////////////////////////////////////
struct MultilineTextView: UIViewRepresentable {
    @Binding var text: String
	var onTextEdited: ((String) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let myTextView = UITextView()
        myTextView.delegate = context.coordinator
        myTextView.font = UIFont(name: "HelveticaNeue", size: 15)
        myTextView.isScrollEnabled = true
        //myTextView.isEditable = true
        myTextView.isUserInteractionEnabled = true
        myTextView.backgroundColor = UIColor(white: 0.0, alpha: 0.05)
        return myTextView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }

    class Coordinator : NSObject, UITextViewDelegate {
        var parent: MultilineTextView

        init(_ uiTextView: MultilineTextView) {
            self.parent = uiTextView
        }

        func textViewDidChange(_ textView: UITextView) {
            self.parent.text = textView.text
        }
		
		func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
			if text == "\n" {
				textView.resignFirstResponder()
				return false
			}
			return true
		}
		
		func textViewDidEndEditing(_ textView: UITextView) {
			self.parent.onTextEdited?(textView.text)
		}
    }
}

///////////////////////////////////////////////
// Alert with TextField return
///////////////////////////////////////////////
extension UIAlertController {
    convenience init(alert: TextAlert) {
        self.init(title: alert.title, message: nil, preferredStyle: .alert)
        addTextField { $0.placeholder = alert.placeholder }
        addAction(UIAlertAction(title: alert.cancel, style: .cancel) { _ in
            alert.action(nil)
        })
        let textField = self.textFields?.first
        addAction(UIAlertAction(title: alert.accept, style: .default) { _ in
            alert.action(textField?.text)
        })
    }
}

struct AlertWrapper<Content: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let alert: TextAlert
    let content: Content
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<AlertWrapper>) -> UIHostingController<Content> {
        UIHostingController(rootView: content)
    }
    
    final class Coordinator {
        var alertController: UIAlertController?
        init(_ controller: UIAlertController? = nil) {
            self.alertController = controller
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: UIViewControllerRepresentableContext<AlertWrapper>) {
        uiViewController.rootView = content
        if isPresented && uiViewController.presentedViewController == nil {
            var alert = self.alert
            alert.action = {
                self.isPresented = false
                self.alert.action($0)
            }
            context.coordinator.alertController = UIAlertController(alert: alert)
            uiViewController.present(context.coordinator.alertController!, animated: true)
        }
		if !isPresented && uiViewController.presentedViewController == context.coordinator.alertController {
			// Commented out since it makes parent modal dismissed
			// uiViewController.presentedViewController?.dismiss(animated: true)
        }
    }
}

public struct TextAlert {
    public var title: String
    public var placeholder: String = ""
    public var accept: String = "OK"
    public var cancel: String = "Cancel"
    public var action: (String?) -> ()
}

extension View {
    public func alert(isPresented: Binding<Bool>, _ alert: TextAlert) -> some View {
        AlertWrapper(isPresented: isPresented, alert: alert, content: self)
    }
}
