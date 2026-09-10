//
//  GEM+TerminalServices.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/09/06.
//

import Foundation

extension GEM {
    
    /// ACKC10
    public enum ACKC10: CaseIterable, CustomStringConvertible, CustomDebugStringConvertible, Sendable {
        
        /// Accepted for display, byte=0x00
        case accepted
        /// Message will not be displayed, byte=0x01
        case notDisplay
        /// Terminal not available, byte=0x02
        case notAvailable
        
        private var itemProperty: (byte: UInt8, description: String) {
            switch self {
            case .accepted:
                return (byte: 0x00, description: "Accepted for display")
            case .notDisplay:
                return (byte: 0x01, description: "Message will not be displayed")
            case .notAvailable:
                return (byte: 0x02, description: "Terminal not available")
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
    
    /// S10F2 Terminal Request Acknowledge
    ///
    /// Reply message from Host to Equipment.
    ///
    /// ```
    /// S10F2
    /// <B [1] ACKC10 >.
    /// ```
    ///
    /// - Parameters:
    ///   - primaryMessage: The primary message
    ///   - ackc10: ACKC10
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s10f2(primaryMessage: SECSMessage, ackc10: ACKC10) async throws {
        try await self.communicator?.reply(primaryMessage: primaryMessage, stream: 10, function: 2, wbit: false, secs2Body: SECS2Body(binary: Data([ackc10.uint8Value])))
    }
    
    /// S10F4 Terminal Display, Single Acknowledge
    ///
    /// Reply message from Equipment to Host.
    ///
    /// ```
    /// S10F4
    /// <B [1] ACKC10 >.
    /// ```
    ///
    /// - Parameters:
    ///   - primaryMessage: The primary message
    ///   - ackc10: ACKC10
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s10f4(primaryMessage: SECSMessage, ackc10: ACKC10) async throws {
        try await self.communicator?.reply(primaryMessage: primaryMessage, stream: 10, function: 4, wbit: false, secs2Body: SECS2Body(binary: Data([ackc10.uint8Value])))
    }
    
    /// S10F6 Terminal Display, Multi-block Acknowledge
    ///
    /// Reply message from Equipment to Host.
    ///
    /// ```
    /// S10F6
    /// <B [1] ACKC10 >.
    /// ```
    ///
    /// - Parameters:
    ///   - primaryMessage: The primary message
    ///   - ackc10: ACKC10
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s10f6(primaryMessage: SECSMessage, ackc10: ACKC10) async throws {
        try await self.communicator?.reply(primaryMessage: primaryMessage, stream: 10, function: 6, wbit: false, secs2Body: SECS2Body(binary: Data([ackc10.uint8Value])))
    }
    
}
