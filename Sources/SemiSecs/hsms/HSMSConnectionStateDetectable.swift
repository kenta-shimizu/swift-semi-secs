//
//  HSMSConnectionStateDetectable.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/05/05.
//

import Foundation

/// HSMS-Connection state detectable.
public protocol HSMSConnectionStateDetectable: SECSCommunicatableDetectable {
    
    /// HSMS-Connection update detect.
    var onDidUpdateHSMSConnectionState: ((HSMSSession.HSMSConnectionState) -> Void)? { get set }
    
    func until(connectionState: HSMSSession.HSMSConnectionState) async throws
    
    func untilNot(connectionState: HSMSSession.HSMSConnectionState) async throws
    
    func until(connectionState: HSMSSession.HSMSConnectionState, timeout: Duration) async throws -> Bool
    
    func untilNot(connectionState: HSMSSession.HSMSConnectionState, timeout: Duration) async throws -> Bool
    
}

extension HSMSConnectionStateDetectable {
    
    public func untilCommunicatable() async throws {
        try await self.until(connectionState: .selected)
    }
    
    public func untilNotCommunicatable() async throws {
        try await self.untilNot(connectionState: .selected)
    }
    
    @discardableResult
    public func untilCommunicatable(timeout: Duration) async throws -> Bool {
        return try await until(connectionState: .selected, timeout: timeout)
    }
    
    @discardableResult
    public func untilNotCommunicatable(timeout: Duration) async throws -> Bool {
        return try await untilNot(connectionState: .selected, timeout: timeout)
    }
    
}
