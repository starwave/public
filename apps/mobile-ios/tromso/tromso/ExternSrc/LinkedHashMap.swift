//
//  LinkedHashMap.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/12/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation

struct LinkedHashMap<KeyType: Hashable, ValueType> : Sequence {
    private var _dictionary: Dictionary<KeyType, ValueType>
    private var _keys: Array<KeyType>
    private var _keyIndices: Dictionary<KeyType, Int>

    init() {
        _dictionary = [:]
        _keys = []
        _keyIndices = [:]
    }

    init(minimumCapacity: Int) {
        _dictionary = Dictionary<KeyType, ValueType>(minimumCapacity: minimumCapacity)
        _keys = Array<KeyType>()
        _keyIndices = Dictionary<KeyType, Int>(minimumCapacity: minimumCapacity)
    }

    init(_ dictionary: Dictionary<KeyType, ValueType>) {
        _dictionary = dictionary
        _keys = Array(dictionary.keys)
        _keyIndices = Dictionary(uniqueKeysWithValues: _keys.enumerated().map { ($1, $0) })
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
            _keyIndices[key] = _keys.count - 1
        }
        return oldValue
    }

    mutating func put(value: ValueType, forKey key: KeyType) {
        let oldValue = _dictionary.updateValue(value, forKey: key)
        if oldValue == nil {
            _keys.append(key)
            _keyIndices[key] = _keys.count - 1
        }
    }
    
    mutating func removeValueForKey(key: KeyType) {
        guard let index = _keyIndices[key] else {
            _dictionary.removeValue(forKey: key)
            return
        }
        _keys.swapAt(index, _keys.count - 1)
        _keys.removeLast()
        if index < _keys.count {
            _keyIndices[_keys[index]] = index
        }
        _keyIndices.removeValue(forKey: key)
        _dictionary.removeValue(forKey: key)
    }

    mutating func removeAll(keepCapacity: Int) {
        _keys.removeAll(keepingCapacity: (keepCapacity != 0))
        _dictionary.removeAll(keepingCapacity: (keepCapacity != 0))
        _keyIndices.removeAll(keepingCapacity: (keepCapacity != 0))
    }

    var count: Int {
        get {
            _dictionary.count
        }
    }

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

    func firstIndex(of key: KeyType) -> Int? {
        return _keyIndices[key]
    }

    mutating func remove(at index: Int) {
        let key = _keys[index]
        _keys.remove(at: index)
        _dictionary.removeValue(forKey: key)
        _keyIndices.removeValue(forKey: key)
        // Update indices for keys after the removed key
        for i in index..<_keys.count {
            _keyIndices[_keys[i]] = i
        }
    }

    mutating func insert(value: ValueType, forKey key: KeyType, at index: Int) {
        let oldValue = _dictionary.updateValue(value, forKey: key)
        if oldValue == nil {
            _keys.insert(key, at: index)
            // Update indices for the new key and keys after it
            for i in index..<_keys.count {
                _keyIndices[_keys[i]] = i
            }
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
