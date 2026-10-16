//
//  StartAndShutdown.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/10/10.
//

import Foundation
import Synchronization

public enum StartAndShutdownError: Error, CustomStringConvertible, CustomDebugStringConvertible {
    
    case alreadyStarted
    case alreadyShutdown
    
    public var description: String {
        let type = String(describing: type(of: self))
        
        switch self {
        case .alreadyStarted:
            return "\(type).alreadyStarted"
            
        case .alreadyShutdown:
            return "\(type).alreadyShutdown"
        }
    }
    
    public var debugDescription: String {
        return self.description;
    }
}

/// StartAndShutdonw marking.
internal final class StartAndShutdown: Sendable {
    
    private enum StartAndShutdownState {
        case standby
        case running
        case shutdown
    }
    
    private let state = Mutex<StartAndShutdownState>(.standby)
    
    internal init() {
        // Nothing
    }
    
    /// Mark running, throws if already started or shutdown.
    ///
    /// - Throws:
    ///   - `StartAndShutdownError.alreadyShutdowned`: if already shutdown.
    ///   - `StartAndShutdownError.alreadyStarted`:  if already started.
    internal func start() throws {
        try self.state.withLock {
            switch $0 {
            case .standby:
                $0 = .running
            case .running:
                throw StartAndShutdownError.alreadyStarted
            case .shutdown:
                throw StartAndShutdownError.alreadyShutdown
            }
        }
    }
    
    /// Mark shutdown, returns true if already shutdown, otherwise false.
    ///
    /// - Returns: true if already shutdown, otherwise false.
    @discardableResult
    internal func shutdown() -> Bool {
        self.state.withLock {
            switch $0 {
            case .standby, .running:
                $0 = .shutdown
                return false
            case .shutdown:
                return true
            }
        }
    }
    
    /// isRunning
    internal var isRunning: Bool {
        self.state.withLock {
            return $0 == .running
        }
    }
    
}
