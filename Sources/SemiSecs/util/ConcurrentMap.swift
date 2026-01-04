//
//  ConcurrentMap.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/04.
//

import Foundation

internal class ConcurrentMap<K: Hashable, V>: @unchecked Sendable {
    
    private let semaphore = DispatchSemaphore(value: 1)
    private var map: [K: V] = [:]
    
    internal init() {
        /* Nothing */
    }
    
    internal func object(_ value: V, forKey: K) {
        self.semaphore.wait()
        defer {
            self.semaphore.signal()
        }
        self.map[forKey] = value
    }
    
    @discardableResult
    internal func removeValue(forKey: K) -> V? {
        self.semaphore.wait()
        defer {
            self.semaphore.signal()
        }
        return self.map.removeValue(forKey: forKey)
    }
}
