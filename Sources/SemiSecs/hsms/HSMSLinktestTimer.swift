//
//  HSMSLinktestTimer.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/07/18.
//

import Foundation
import Synchronization

internal final class HSMSLinktestTimer: Sendable {
    
    private let startAndShutdown = StartAndShutdown()
    private let resetFlag = StateUpdateNotifier<Bool>(state: false)
    
    internal init() {
        // Nothing
    }
    
    private let _autoLinktest = Mutex<(@Sendable () -> Bool)?>(nil)
    
    internal var autoLinktest : (@Sendable () -> Bool)? {
        get { self._autoLinktest.withLock { $0 } }
        set { self._autoLinktest.withLock { $0 = newValue } }
    }
    
    private let _linktestDuration = Mutex<(@Sendable () -> Duration)?>(nil)
    
    internal var linktestDuration: (@Sendable () -> Duration)? {
        get { self._linktestDuration.withLock { $0 } }
        set { self._linktestDuration.withLock { $0 = newValue } }
    }
    
    private let _linktest = Mutex<(@Sendable () -> Void)?>(nil)
    
    internal var linktest: (@Sendable () -> Void)? {
        get { self._linktest.withLock { $0 } }
        set { self._linktest.withLock { $0 = newValue } }
    }
    
    internal func start() {
        do {
            try self.startAndShutdown.start()
        }
        catch {
            fatalError("start error: \(error)")
        }
        
        Task.detached {
            do {
                while !Task.isCancelled {
                    self.resetFlag.yield(false)
                    if self.autoLinktest!() {
                        let result = try await self.resetFlag.until(true, timeout: self.linktestDuration!())
                        if result == false {
                            // timeout, do linktest.
                            self.linktest?()
                        }
                    } else {
                        // wait until reset
                        try await self.resetFlag.until(true)
                    }
                }
            }
            catch {
                // nothing
            }
        }
    }
    
    internal func reset() {
        guard self.startAndShutdown.isRunning else { return }
        self.resetFlag.yield(true)
    }
    
    internal func shutdown() {
        guard self.startAndShutdown.shutdown() == false else { return }
        self.resetFlag.shutdown()
    }
    
}
