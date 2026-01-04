//
//  BoolChangeNotifier.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/04.
//

import Foundation

internal final class BoolChangeNotifier: StateChangeNotifier<Bool>, @unchecked Sendable {
    
    internal override init(_ state: Bool) {
        super.init(state)
    }
    
    internal override func shutdown() {
        super.shutdown()
    }
    
    @discardableResult
    internal override func waitUntil(_ state: Bool) throws(ShutdownError) -> Bool{
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if state == self.state {
            return true
        }
        self.condition.wait()
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        return true
    }
    
    @discardableResult
    internal override func waitUntilNot(_ state: Bool) throws(ShutdownError) -> Bool{
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if state != self.state {
            return true
        }
        self.condition.wait()
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        return true
    }
    
    @discardableResult
    internal override func waitUntil(_ state: Bool, timeout: Double) throws(ShutdownError) -> Bool{
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned        }
        if state == self.state {
            return true
        }
        self.condition.wait(until: Date().addingTimeInterval(timeout))
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        return state == self.state
    }

    @discardableResult
    internal override func waitUntilNot(_ state: Bool, timeout: Double) throws(ShutdownError) -> Bool{
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if state != self.state {
            return true
        }
        self.condition.wait(until: Date().addingTimeInterval(timeout))
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        return state != self.state
    }

}
