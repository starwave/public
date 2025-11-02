//
//  LinkedHashMap.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/12/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation

// LinkedHashMap behaves like a Dictionary except that it maintains
// the insertion order of the keys, so iteration order matches insertion order.

struct LinkedHashMap<KeyType: Hashable, ValueType> : Sequence {
    private var _dictionary: Dictionary<KeyType, ValueType>
    private var _keys: Array<KeyType>

    init() {
        _dictionary = [:]
        _keys = []
    }
    init(minimumCapacity: Int) {
        _dictionary = Dictionary<KeyType, ValueType>(minimumCapacity: minimumCapacity)
        _keys = Array<KeyType>()
    }
    init(_ dictionary: Dictionary<KeyType, ValueType>) {
        _dictionary = dictionary
        _keys = dictionary.keys.map { $0 }
    }
    subscript(key: KeyType) -> ValueType? {
        get {
            _dictionary[key]
        }
        set {
            if newValue == nil {
                self.removeValueForKey(key: key)
            } else {
                _ = self.updateValue(value: newValue!, forKey: key)
            }
        }
    }
    mutating func updateValue(value: ValueType, forKey key: KeyType) -> ValueType? {
        let oldValue = _dictionary.updateValue(value, forKey: key)
        if oldValue == nil {
            _keys.append(key)
        }
        return oldValue
    }
    mutating func put(value: ValueType, forKey key: KeyType) {
        let oldValue = _dictionary.updateValue(value, forKey: key)
        if oldValue == nil {
            _keys.append(key)
        }
    }
    mutating func removeValueForKey(key: KeyType) {
        _keys = _keys.filter {
            $0 != key
        }
        _dictionary.removeValue(forKey: key)
    }
    mutating func removeAll(keepCapacity: Int) {
        _keys = []
        _dictionary = Dictionary<KeyType, ValueType>(minimumCapacity: keepCapacity)
    }
    var count: Int {
        get {
            _dictionary.count
        }
    }
    // keys isn't lazy evaluated because it's just an array anyway
    var keys: [KeyType] {
        get {
            _keys
        }
    }
    var values: Array<ValueType> {
        get {
            _keys.map { _dictionary[$0]! }
        }
    }
    static func ==<Key: Equatable, Value: Equatable>(lhs: LinkedHashMap<Key, Value>, rhs: LinkedHashMap<Key, Value>) -> Bool {
        lhs._keys == rhs._keys && lhs._dictionary == rhs._dictionary
    }
    static func !=<Key: Equatable, Value: Equatable>(lhs: LinkedHashMap<Key, Value>, rhs: LinkedHashMap<Key, Value>) -> Bool {
        lhs._keys != rhs._keys || lhs._dictionary != rhs._dictionary
    }
    public func makeIterator() -> LinkedHashMapIterator<KeyType, ValueType> {
        LinkedHashMapIterator<KeyType, ValueType>(sequence: _dictionary, keys: _keys, current: 0)
    }
	func firstIndex(of key:KeyType) -> Int? {
		return _keys.firstIndex(of: key)
	}
	mutating func remove(at index:Int) {
		let key = _keys[index]
		_keys.remove(at: index)
		_dictionary.removeValue(forKey: key)
	}
	mutating func insert(value: ValueType, forKey key: KeyType, at index: Int) {
        let oldValue = _dictionary.updateValue(value, forKey: key)
        if oldValue == nil {
            _keys.insert(key, at: index)
        }
    }
}

struct LinkedHashMapIterator<KeyType: Hashable, ValueType>: IteratorProtocol {
    let sequence: Dictionary<KeyType, ValueType>
    let keys: Array<KeyType>
    var current = 0

    mutating func next() -> (KeyType, ValueType)? {
        defer { current += 1 }
        guard sequence.count > current else {
            return nil
        }

        let key = keys[current]
        guard let value = sequence[key] else {
            return nil
        }
        return (key, value)
    }
}

