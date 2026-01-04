//
//  BlockingQueue.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/04.
//

import Foundation

internal final class BlockingQueue<T>: ShutdownableBase, @unchecked Sendable {
    
    private let condition = NSCondition()
    private var queue: [T] = []
    
    internal override init() {
        super.init()
    }
    
    internal override func shutdown() {
        self.condition.lock()
        if !self.shutdowned {
            self.queue.removeAll()
            super.shutdown()
            self.condition.broadcast()
        }
        self.condition.unlock()
    }
    
    @discardableResult
    internal func put(_ value: T) throws(ShutdownError) -> Bool {
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        self.queue.append(value)
        self.condition.signal()
        return true
    }
    
    @discardableResult
    internal func take() throws(ShutdownError) -> T {
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if !self.queue.isEmpty {
            return self.queue.removeFirst()
        }
        self.condition.wait()
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        return self.queue.removeFirst()
    }
    
    @discardableResult
    internal func poll() throws(ShutdownError) -> T? {
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if self.queue.isEmpty {
            return nil
        } else {
            return self.queue.removeFirst()
        }
    }
    
    @discardableResult
    internal func poll(timeout: Double) throws(ShutdownError) -> T? {
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if !self.queue.isEmpty {
            return self.queue.removeFirst()
        }
        let signaled = self.condition.wait(until: Date().addingTimeInterval(timeout))
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if signaled {
            return self.queue.removeFirst()
        } else {
            return nil
        }
    }
}
