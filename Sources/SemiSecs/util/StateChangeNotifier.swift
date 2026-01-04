//
//  StateChangeNotifier.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/04.
//

import Foundation

internal class StateChangeNotifier<T: Equatable>: ShutdownableBase, @unchecked Sendable {
    
    internal let condition = NSCondition()
    private var observers: [(T) -> Void] = []
    internal var state: T
    
    private var boolNoifiers: [BoolChangeNotifier] = []
    
    internal init(_ state: T) {
        self.state = state
        super.init()
    }
    
    internal override func shutdown() {
        self.condition.lock()
        if !self.shutdowned {
            self.observers.removeAll()
            for notifier in self.boolNoifiers {
                notifier.shutdown()
            }
            self.boolNoifiers.removeAll()
            super.shutdown()
        }
        self.condition.unlock()
    }
    
    internal func append(observer: @escaping (T) -> Void) {
        self.condition.lock()
        if !self.shutdowned {
            observer(self.state)
            self.observers.append(observer)
        }
        self.condition.unlock()
    }
    
    internal func set(_ state: T) {
        self.condition.lock()
        if !self.shutdowned {
            if state != self.state {
                self.state = state
                self.condition.broadcast()
                for observer in self.observers {
                    observer(state)
                }
            }
        }
        self.condition.unlock()
    }
    
    @discardableResult
    internal func waitUntil(_ state: T) throws(ShutdownError) -> Bool {
        let boolNotifier = BoolChangeNotifier(false)
        self.boolNoifiers.append(boolNotifier)
        defer {
            boolNotifier.shutdown()
            self.boolNoifiers.removeAll { $0 === boolNotifier }
        }
        do {
            self.condition.lock()
            defer {
                self.condition.unlock()
            }
            guard !self.shutdowned else {
                throw .alreadyShutdowned
            }
            boolNotifier.set(state == self.state)
            self.observers.append { boolNotifier.set($0 == state) }
        }
        return try boolNotifier.waitUntil(true)
    }
    
    @discardableResult
    internal func waitUntilNot(_ state: T) throws(ShutdownError) -> Bool {
        let boolNotifier = BoolChangeNotifier(true)
        self.boolNoifiers.append(boolNotifier)
        defer {
            boolNotifier.shutdown()
            self.boolNoifiers.removeAll { $0 === boolNotifier }
        }
        do {
            self.condition.lock()
            defer {
                self.condition.unlock()
            }
            guard !self.shutdowned else {
                throw .alreadyShutdowned
            }
            boolNotifier.set(state == self.state)
            self.observers.append { boolNotifier.set($0 == state) }
        }
        return try boolNotifier.waitUntilNot(true)
    }
    
    @discardableResult
    internal func waitUntil(_ state: T, timeout: Double) throws(ShutdownError) -> Bool {
        let boolNotifier = BoolChangeNotifier(false)
        self.boolNoifiers.append(boolNotifier)
        defer {
            boolNotifier.shutdown()
            self.boolNoifiers.removeAll { $0 === boolNotifier }
        }
        do {
            self.condition.lock()
            defer {
                self.condition.unlock()
            }
            guard !self.shutdowned else {
                throw .alreadyShutdowned
            }
            boolNotifier.set(state == self.state)
            self.observers.append { boolNotifier.set($0 == state) }
        }
        return try boolNotifier.waitUntil(true, timeout: timeout)
    }
    
    @discardableResult
    internal func waitUntilNot(_ state: T, timeout: Double) throws(ShutdownError) -> Bool {
        let boolNotifier = BoolChangeNotifier(true)
        self.boolNoifiers.append(boolNotifier)
        defer {
            boolNotifier.shutdown()
            self.boolNoifiers.removeAll { $0 === boolNotifier }
        }
        do {
            self.condition.lock()
            defer {
                self.condition.unlock()
            }
            guard !self.shutdowned else {
                throw .alreadyShutdowned
            }
            boolNotifier.set(state == self.state)
            self.observers.append { boolNotifier.set($0 == state) }
        }
        return try boolNotifier.waitUntilNot(true, timeout: timeout)
    }
    
}
