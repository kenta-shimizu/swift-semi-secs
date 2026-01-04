//
//  Shutdownable.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/04.
//

import Foundation

public protocol Shutdownable {
    func shutdown()
}

public class ShutdownableBase: Shutdownable {
    
    internal enum ShutdownError: Error, Sendable {
        case alreadyShutdowned
    }
    
    internal var shutdowned: Bool
    internal var shutdownables: [Shutdownable]
    
    internal init() {
        self.shutdowned = false
        self.shutdownables = []
    }
    
    deinit {
        self.shutdown()
    }
    
    internal func append(shutdownable: Shutdownable) {
        self.shutdownables.append(shutdownable)
    }
    
    public func shutdown() {
        for shutdownable in self.shutdownables {
            shutdownable.shutdown()
        }
        self.shutdownables.removeAll()
        self.shutdowned = true
    }
}
