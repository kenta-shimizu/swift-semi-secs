//
//  SECSCommunicatingDetectable.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/05/05.
//

import Foundation

/// SECS-Communicatable detectable.
public protocol SECSCommunicatingDetectable {
    
    /// Communicating update handler.
    var didUpdateCommunicationState: ((Bool) -> Void)? { get set }
    
    /// Wait until the status updates to Communicating. If already communicating, it returns immediately without waiting.
    ///
    /// - Throws:
    ///   - `CancellationError`: If cancelled.
    func untilCommunicating() async throws
    
    /// Wait until the status updates to NOT Communicating. If already NOT communicating, it returns immediately without waiting.
    ///
    /// - Throws:
    ///   - `CancellationError`: If cancelled.
    func untilNotCommunicating() async throws
    
    /// Wait until the status updates to Communicating. If already communicating, it returns immediately without waiting.
    ///
    /// - Parameters:
    ///   - timeout: the timeout duration
    /// - Returns: true if updated to communicating, false if timeout.
    /// - Throws:
    ///   - `CancellationError`: If cancelled.
    @discardableResult
    func untilCommunicating(timeout: Duration) async throws -> Bool
    
    /// Wait until the status updates to NOT Communicating. If already NOT communicating, it returns immediately without waiting.
    ///
    /// - Parameters:
    ///   - timeout: the timeout duration
    /// - Returns: true if updated to NOT communicating, false if timeout.
    /// - Throws:
    ///   - `CancellationError`: If cancelled.
    @discardableResult
    func untilNotCommunicating(timeout: Duration) async throws -> Bool
    
}
