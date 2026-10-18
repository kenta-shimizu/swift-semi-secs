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
    
    private let stateNotifier: Mutex<StateUpdateNotifier<StartAndShutdownState>>

    internal init() {
        self.stateNotifier = Mutex<StateUpdateNotifier<StartAndShutdownState>>(StateUpdateNotifier<StartAndShutdownState>(state: .standby))
    }
    
    /// Mark running, throws if already started or shutdown.
    ///
    /// - Throws:
    ///   - `StartAndShutdownError.alreadyShutdowned`: if already shutdown.
    ///   - `StartAndShutdownError.alreadyStarted`:  if already started.
    internal func start() throws {
        try self.stateNotifier.withLock {
            switch $0.lastState {
            case .standby:
                $0.yield(.running)
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
        self.stateNotifier.withLock {
            switch $0.lastState {
            case .standby, .running:
                $0.yield(.shutdown)
                $0.shutdown()
                return false
            case .shutdown:
                return true
            }
        }
    }
    
    /// isRunning
    internal var isRunning: Bool {
        self.stateNotifier.withLock {
            return $0.lastState == .running
        }
    }
    
    /// Await until shutdown.
    ///
    /// - Throws:
    ///   - `CancellationError`: if already shutdown.
    internal func untilShutdown() async throws {
        let notifier = self.stateNotifier.withLock { $0 }
        try await notifier.until(.shutdown)
    }
    
}
