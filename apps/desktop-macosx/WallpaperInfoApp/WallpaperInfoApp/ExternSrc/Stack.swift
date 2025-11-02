//
//  Stack.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/12/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation

public struct Stack<T> {
    
    fileprivate var array = [T]()
  
    public var empty: Bool {
        return array.isEmpty
    }
  
    public var count: Int {
        return array.count
    }
  
    public mutating func push(_ element: T) {
        array.append(element)
    }
  
    public mutating func pop() -> T? {
        return array.popLast()
    }
  
    public var top: T? {
        return array.last
    }
}

extension Stack: Sequence {
    public func makeIterator() -> AnyIterator<T> {
        var curr = self
        return AnyIterator {
            return curr.pop()
        }
    }
}
