//
//  HSMSConnectionStateDetectable.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/05/05.
//

import Foundation

/// HSMS-Connection state detectable.
public protocol HSMSConnectionStateDetectable: SECSCommunicatingDetectable {
    
    /// HSMS-Connection update detect.
    var didUpdateHSMSConnectionState: ((HSMSSession.HSMSConnectionState) -> Void)? { get set }
    
    /// Wait until the state updates to target state. If already target state, it returns immediately without waiting.
    ///
    /// - Parameters:
    ///   - connectionState: the target state
    /// - Throws:
    ///   - `CancellationError`: If cancelled.
    func until(connectionState: HSMSSession.HSMSConnectionState) async throws
    
    /// Wait until the state updates to NOT target state. If already NOT target state, it returns immediately without waiting.
    ///
    /// - Parameters:
    ///   - connectionState: the target state
    /// - Throws:
    ///   - `CancellationError`: If cancelled.
    func untilNot(connectionState: HSMSSession.HSMSConnectionState) async throws
    
    /// Wait until the state updates to target state. If already target state, it returns immediately without waiting.
    ///
    /// - Parameters:
    ///   - connectionState: the target state
    ///   - timeout: the timeout duration
    /// - Returns: true if updated to target state, false if timeout.
    /// - Throws:
    ///   - `CancellationError`: If cancelled.
    func until(connectionState: HSMSSession.HSMSConnectionState, timeout: Duration) async throws -> Bool
    
    /// Wait until the state updates to NOT target state. If already NOT target state, it returns immediately without waiting.
    ///
    /// - Parameters:
    ///   - connectionState: the target state
    ///   - timeout: the timeout duration
    /// - Returns: true if updated to NOT target state, false if timeout.
    /// - Throws:
    ///   - `CancellationError`: If cancelled.
    func untilNot(connectionState: HSMSSession.HSMSConnectionState, timeout: Duration) async throws -> Bool
    
}

extension HSMSConnectionStateDetectable {
    
    public func untilCommunicating() async throws {
        try await self.until(connectionState: .selected)
    }
    
    public func untilNotCommunicating() async throws {
        try await self.untilNot(connectionState: .selected)
    }
    
    @discardableResult
    public func untilCommunicating(timeout: Duration) async throws -> Bool {
        return try await until(connectionState: .selected, timeout: timeout)
    }
    
    @discardableResult
    public func untilNotCommunicating(timeout: Duration) async throws -> Bool {
        return try await untilNot(connectionState: .selected, timeout: timeout)
    }
    
}
