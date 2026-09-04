//
//  GEM+SystemErrors.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/08/12.
//

import Foundation

extension GEM {
    
    /// S9F1 Unrecognized Device ID
    ///
    /// Send message.
    ///
    /// ```
    /// S9F1
    /// <B [10] MHEAD >.
    /// ```
    ///
    /// - Parameters:
    ///   - referenceMessage: The reference message
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s9f1(referenceMessage: any SECSMessage) async throws {
        try await self.s9fy(referenceMessage: referenceMessage, function: 1)
    }
    
    /// S9F3 Unrecognized Stream Type
    ///
    /// Send message.
    ///
    /// ```
    /// S9F3
    /// <B [10] MHEAD >.
    /// ```
    ///
    /// - Parameters:
    ///   - referenceMessage: The reference message
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s9f3(referenceMessage: any SECSMessage) async throws {
        try await self.s9fy(referenceMessage: referenceMessage, function: 3)
    }
    
    /// S9F5 Unrecognized Function Type
    ///
    /// Send message.
    ///
    /// ```
    /// S9F5
    /// <B [10] MHEAD >.
    /// ```
    ///
    /// - Parameters:
    ///   - referenceMessage: The reference message
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s9f5(referenceMessage: any SECSMessage) async throws {
        try await self.s9fy(referenceMessage: referenceMessage, function: 5)
    }
    
    /// S9F7 Illegal Data
    ///
    /// Send message.
    ///
    /// ```
    /// S9F7
    /// <B [10] MHEAD >.
    /// ```
    ///
    /// - Parameters:
    ///   - referenceMessage: The reference message
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s9f7(referenceMessage: any SECSMessage) async throws {
        try await self.s9fy(referenceMessage: referenceMessage, function: 7)
    }
    
    /// S9F9 Transaction Timer Timeout
    ///
    /// Send message.
    ///
    /// ```
    /// S9F9
    /// <B [10] MHEAD >.
    /// ```
    ///
    /// - Parameters:
    ///   - referenceMessage: The reference message
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s9f9(referenceMessage: any SECSMessage) async throws {
        try await self.s9fy(referenceMessage: referenceMessage, function: 9)
    }
    
    /// S9F11 Data Too Long
    ///
    /// Send message.
    ///
    /// ```
    /// S9F11
    /// <B [10] MHEAD >.
    /// ```
    ///
    /// - Parameters:
    ///   - referenceMessage: The reference message
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s9f11(referenceMessage: any SECSMessage) async throws {
        try await self.s9fy(referenceMessage: referenceMessage, function: 11)
    }
    
    private func s9fy(referenceMessage: any SECSMessage, function: UInt8) async throws {
        try await self.communicator?.send(stream: 9, function: function, wbit: false, secs2Body: SECS2Body(binary: referenceMessage.header10Bytes))
    }
    
}
