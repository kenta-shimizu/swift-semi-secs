//
//  MutexClosureWrapper.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/10/16.
//

import Foundation
import Synchronization

internal final class MutexConsumerWrapper<T>: Sendable {
    
    internal struct Inner: @unchecked Sendable {
        internal var closure: ((T) -> Void)?
        
        internal init() {
            self.closure = nil
        }
    }
    
    internal init() {
        // Nothing
    }
    
    private let mutex = Mutex<Inner>(Inner())
    
    internal var consumer: ((T) -> Void)? {
        get { self.mutex.withLock { $0.closure } }
        set { self.mutex.withLock { $0.closure = newValue } }
    }
    
    internal func accept(_ value: T) {
        self.consumer?(value)
    }
    
}

internal final class MutexBiConsumerWrapper<T, U>: Sendable {
    
    internal struct Inner: @unchecked Sendable {
        internal var closure: ((T, U) -> Void)?
        
        internal init() {
            self.closure = nil
        }
    }
    
    internal init() {
        // Nothing
    }
    
    private let mutex = Mutex<Inner>(Inner())
    
    internal var biConsumer: ((T, U) -> Void)? {
        get { self.mutex.withLock { $0.closure } }
        set { self.mutex.withLock { $0.closure = newValue } }
    }
    
    internal func accept(_ first: T, _ second: U) {
        self.biConsumer?(first, second)
    }
    
}
