//
//  GEM+EstablishCommunications.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/08/13.
//

import Foundation

extension GEM {
    
    /// COMMACK
    public enum COMMACK: CaseIterable, CustomStringConvertible, CustomDebugStringConvertible, Sendable {
        
        /// Accepted, byte=0x00
        case accepted
        /// Denied, byte=0x01
        case denied
        
        private var itemProperty: (byte: UInt8, description: String) {
            switch self {
            case .accepted:
                return (byte: 0x00, description: "Accepted")
            case .denied:
                return (byte: 0x01, description: "Denied")
            }
        }
        
        public init?(byte: UInt8) {
            for i in Self.allCases {
                if i.itemProperty.byte == byte {
                    self = i
                    return
                }
            }
            return nil
        }
        
        public var uint8Value: UInt8 {
            get {
                return self.itemProperty.byte
            }
        }
        
        public var description: String {
            return self.itemProperty.description
        }

        public var debugDescription: String {
            return self.description
        }
        
    }
    
    /// S1F13 Establish Communications Request
    ///
    /// Send message from Host to Equipment.
    ///
    /// ```
    /// S1F13 W
    /// <L [0]
    /// >.
    /// ```
    ///
    /// - Returns: COMMACK
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    ///   - `SECSWaitReplyError`: if wait reply failed.
    ///   - `GEMError`: if unexpected response.
    @discardableResult
    public func s1f13() async throws -> COMMACK {
        return try await self.s1f13Inner(secs2Body: SECS2Body(list: []))
    }
    
    /// S1F13 Establish Communications Request
    ///
    /// Send message from Equipment to Host.
    ///
    /// ```
    /// S1F13 W
    /// <L [2]
    ///   <A [?] MDLN >
    ///   <A [?] SOFTREV >
    /// >.
    /// ```
    ///
    /// - Parameters:
    ///   - mdln: MDLN
    ///   - softrev: SOFTREV
    /// - Returns: COMMACK
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    ///   - `SECSWaitReplyError`: if wait reply failed.
    ///   - `GEMError`: if unexpected response.
    @discardableResult
    public func s1f13(mdln: String, softrev: String) async throws -> COMMACK {
        return try await self.s1f13Inner(secs2Body: self.mdlnSoftrev(mdln: mdln, softrev: softrev))
    }
    
    private func s1f13Inner(secs2Body: SECS2Body) async throws -> COMMACK {
        guard let s1f14 = try await self.communicator?.send(stream: 1, function: 13, wbit: true) else {
            throw GEMError.unknown
        }
        try self.checkGEMError(responseMessage: s1f14, stream: 1, function: 14)
        guard let byte = s1f14.secs2Body?.uint8Value(at: 0, 0),
              let result = COMMACK(byte: byte) else {
            throw GEMError.illegalData(responseMesage: s1f14)
        }
        
        return result
    }
    
    /// S1F14 Establish Communications Acknowledge
    ///
    /// Reply message from Host to Equipment.
    ///
    /// ```
    /// S1F14
    /// <L [2]
    ///   <B [1] COMMACK >
    ///   <L [0]
    ///   >
    /// >.
    /// ```
    ///
    /// - Parameters:
    ///   - primaryMessage: The primary message
    ///   - commack: COMMACK
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    ///
    public func s1f14(primaryMessage: any SECSMessage, commack: COMMACK) async throws {
        try await self.s1f14Inner(primaryMessage: primaryMessage, commack: commack, secs2Body: SECS2Body(list: []))
    }
    
    /// S1F14 Establish Communications Acknowledge
    ///
    /// Reply message from Equipment to Host.
    ///
    /// ```
    /// S1F14
    /// <L [2]
    ///   <B [1] COMMACK >
    ///   <L [2]
    ///     <A [?] MDLN >
    ///     <A [?] SOFTREV >
    ///   >
    /// >.
    /// ```
    ///
    /// - Parameters:
    ///   - primaryMessage: The primary message
    ///   - commack: COMMACK
    ///   - mdln: MDLN
    ///   - softrev: SOFTREV
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s1f14(primaryMessage: any SECSMessage, commack: COMMACK, mdln: String, softrev: String) async throws {
        return try await self.s1f14Inner(primaryMessage: primaryMessage, commack: commack, secs2Body: self.mdlnSoftrev(mdln: mdln, softrev: softrev))
    }
    
    private func s1f14Inner(primaryMessage: any SECSMessage, commack: COMMACK, secs2Body: SECS2Body) async throws {
        try await self.communicator?.reply(primaryMessage: primaryMessage, stream: 1, function: 14, wbit: false, secs2Body: SECS2Body(list: [
            SECS2Body(binary: Data([commack.uint8Value])),
            secs2Body
        ]))
    }
    
    private func mdlnSoftrev(mdln: String, softrev: String) -> SECS2Body {
        return SECS2Body(list: [
            SECS2Body(ascii: mdln),
            SECS2Body(ascii: softrev)
        ])
    }
    
}
