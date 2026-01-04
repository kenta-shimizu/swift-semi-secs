//
//  BlockingDataQueue.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/04.
//

import Foundation

internal final class BlockingDataQueue: ShutdownableBase, @unchecked Sendable {
    
    private let condition = NSCondition()
    private var data = Data()
    
    internal override init() {
        super.init()
    }
    
    internal override func shutdown() {
        self.condition.lock()
        if !self.shutdowned {
            super.shutdown()
            self.condition.broadcast()
        }
        self.condition.unlock()
    }
    
    internal func put(_ data: Data) throws(ShutdownError) {
        guard !data.isEmpty else {
            return
        }
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        self.data.append(data)
        self.condition.signal()
    }
    
    @discardableResult
    internal func take() throws(ShutdownError) -> UInt8 {
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if !self.data.isEmpty {
            return self.data.removeFirst()
        }
        self.condition.wait()
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        return self.data.removeFirst()
    }
    
    @discardableResult
    internal func take(_ maxLength: Int) throws(ShutdownError) -> Data {
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if !self.data.isEmpty {
            if self.data.count > maxLength {
                let r = self.data.prefix(maxLength)
                self.data.removeFirst(maxLength)
                return r
            } else {
                let r = self.data
                self.data.removeAll()
                return r
            }
        }
        self.condition.wait()
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if self.data.count > maxLength {
            let r = self.data.prefix(maxLength)
            self.data.removeFirst(maxLength)
            return r
        } else {
            let r = self.data
            self.data.removeAll()
            return r
        }
    }
    
    @discardableResult
    internal func poll(timeout: Double) throws(ShutdownError) -> UInt8? {
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if !self.data.isEmpty {
            return self.data.removeFirst()
        }
        let signaled = self.condition.wait(until: Date().addingTimeInterval(timeout))
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if signaled {
            return self.data.removeFirst()
        }
        return nil
    }
    
    @discardableResult
    internal func poll(_ maxLength: Int, timeout: Double) throws(ShutdownError) -> Data? {
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if !self.data.isEmpty {
            if self.data.count > maxLength {
                let r = self.data.prefix(maxLength)
                self.data.removeFirst(maxLength)
                return r
            } else {
                let r = self.data
                self.data.removeAll()
                return r
            }
        }
        let signaled = self.condition.wait(until: Date().addingTimeInterval(timeout))
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if signaled {
            if self.data.count > maxLength {
                let r = self.data.prefix(maxLength)
                self.data.removeFirst(maxLength)
                return r
            } else {
                let r = self.data
                self.data.removeAll()
                return r
            }
        }
        return nil
    }
    
}
