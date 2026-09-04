//
//  GEM+ControlState.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/08/14.
//

import Foundation

extension GEM {
    
    /// OFLACK
    public enum OFLACK: CaseIterable, CustomStringConvertible, CustomDebugStringConvertible, Sendable {
        
        /// Acknowledge, byte=0x00
        case acknowledge
        
        /// Not accepted, byte=0x01
        case notAccepted
        
        private var itemProperty: (byte: UInt8, description: String) {
            switch self {
            case .acknowledge:
                return (byte: 0x00, description: "Acknowledge")
            case .notAccepted:
                return (byte: 0x01, description: "Not accepted")
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
    
    /// ONLACK
    public enum ONLACK: CaseIterable, CustomStringConvertible, CustomDebugStringConvertible, Sendable {
        
        /// Accepted, byte=0x00
        case accepted
        
        /// Not accepted, byte=0x01
        case notAccepted
        
        /// Already ON-LINE, byte=0x02
        case alreadyOnline
        
        private var itemProperty: (byte: UInt8, description: String) {
            switch self {
            case .accepted:
                return (byte: 0x00, description: "Accepted")
            case .notAccepted:
                return (byte: 0x01, description: "Not accepted")
            case .alreadyOnline:
                return (byte: 0x02, description: "Already ON-LINE")
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
    
    /// S1F1 Are You There Request
    ///
    /// Send message.
    ///
    /// ```
    /// S1F1 W.
    /// ```
    ///
    /// - Returns: S1F2 SECSMessage
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    ///   - `SECSWaitReplyError`: if wait reply failed.
    ///   - `GEMError`: if unexpected response.
    @discardableResult
    public func s1f1() async throws -> any SECSMessage {
        guard let s1f2 = try await self.communicator?.send(stream: 1, function: 1, wbit: true) else {
            throw GEMError.unknown
        }
        try self.checkGEMError(responseMessage: s1f2, stream: 1, function: 2)
        
        return s1f2
    }
    
    /// S1F2 On Line Data
    ///
    /// Reply message from Host to Equipment.
    ///
    /// ```
    /// S1F2
    /// <L [0]
    /// >.
    /// ```
    ///
    /// - Parameters:
    ///   - primaryMessage: The primary message
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s1f2(primaryMessage: any SECSMessage) async throws {
        try await self.s1f2Inner(primaryMessage: primaryMessage, secs2Body: SECS2Body(list: []))
    }
    
    /// S1F2 On Line Data
    ///
    /// Reply message from Equipment to Host.
    ///
    /// ```
    /// S1F2
    /// <L [2]
    ///   <A [?] MDLN >
    ///   <A [?] SOFTREV >
    /// >.
    /// ```
    ///
    /// - Parameters:
    ///   - primaryMessage: The primary message
    ///   - mdln: MDLN
    ///   - softrev: SOFTREV
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s1f2(primaryMessage: any SECSMessage, mdln: String, softrev: String) async throws {
        try await self.s1f2Inner(primaryMessage: primaryMessage, secs2Body: SECS2Body(list: [
            SECS2Body(ascii: mdln),
            SECS2Body(ascii: softrev)
        ]))
    }
    
    private func s1f2Inner(primaryMessage: any SECSMessage, secs2Body: SECS2Body) async throws {
        try await self.communicator?.reply(primaryMessage: primaryMessage, stream: 1, function: 2, wbit: false, secs2Body: secs2Body)
    }
    
    /// S1F15 Request OFF-LINE
    ///
    /// Send message from Host to Equipment.
    ///
    /// ```
    /// S1F15 W.
    /// ```
    ///
    /// - Returns: OFLACK
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    ///   - `SECSWaitReplyError`: if wait reply failed.
    ///   - `GEMError`: if unexpected response.
    public func s1f15() async throws -> OFLACK {
        guard let s1f16 = try await self.communicator?.send(stream: 1, function: 15, wbit: true) else {
            throw GEMError.unknown
        }
        try self.checkGEMError(responseMessage: s1f16, stream: 1, function: 16)
        guard let b = s1f16.secs2Body?.uint8Value(at: 0),
              let oflack = OFLACK(byte: b) else {
            throw GEMError.illegalData(responseMesage: s1f16)
        }
        
        return oflack
    }
    
    /// S1F16 Offline Acknowledge
    ///
    /// Reply message from Equipment to Host.
    ///
    /// ```
    /// S1F16
    /// <B [1] OFLACK >.
    /// ```
    ///
    /// - Parameters:
    ///   - primaryMessage: The primary message
    ///   - oflack: OFLACK
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s1f16(primaryMessage: SECSMessage, oflack: OFLACK) async throws {
        try await self.communicator?.reply(primaryMessage: primaryMessage, stream: 1, function: 16, wbit: false, secs2Body: SECS2Body(binary: Data([oflack.uint8Value])))
    }
    
    /// S1F17 Request ON-LINE
    ///
    /// Send message from Host to Equipment.
    ///
    /// ```
    /// S1F17 W.
    /// ```
    ///
    /// - Returns: ONLACK
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    ///   - `SECSWaitReplyError`: if wait reply failed.
    ///   - `GEMError`: if unexpected response.
    public func s1f17() async throws -> ONLACK {
        guard let s1f18 = try await self.communicator?.send(stream: 1, function: 17, wbit: true) else {
            throw GEMError.unknown
        }
        try self.checkGEMError(responseMessage: s1f18, stream: 1, function: 18)
        guard let b = s1f18.secs2Body?.uint8Value(at: 0),
              let onlack = ONLACK(byte: b) else {
            throw GEMError.illegalData(responseMesage: s1f18)
        }
        
        return onlack
    }
    
    /// S1F18 Online Acknowledge
    ///
    /// Reply message from Equipment to Host.
    ///
    /// ```
    /// S1F18
    /// <B [1] ONLACK >.
    /// ```
    ///
    /// - Parameters:
    ///   - primaryMessage: The primary message
    ///   - onlack: ONLACK
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s1f18(primaryMessage: SECSMessage, onlack: ONLACK) async throws {
        try await self.communicator?.reply(primaryMessage: primaryMessage, stream: 1, function: 18, wbit: false, secs2Body: SECS2Body(binary: Data([onlack.uint8Value])))
    }
    
}
