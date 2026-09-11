//
//  GEM+DynamicEventReportConfiguration.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/09/06.
//

import Foundation

extension GEM {
    
    /// DRACK
    public enum DRACK: CaseIterable, CustomStringConvertible, CustomDebugStringConvertible, Sendable {
        
        /// Accept, byte=0x00
        case accept
        /// Denied. Insufficient space, byte=0x01
        case deniedInsufficientSpace
        /// Denied. Invalid format, byte0x02
        case deniedInvalidFormat
        /// Denied. At least one RPTID already defined, byte=0x03
        case deniedAlreadyDefinedRPTID
        /// Denied. At least VID does not exist, byte0x04
        case deniedNotExistVID
        
        private var itemProperty: (byte: UInt8, description: String) {
            switch self {
            case .accept:
                return (byte: 0x00, description: "Accept")
            case .deniedInsufficientSpace:
                return (byte: 0x01, description: "Denied. Insufficient space")
            case .deniedInvalidFormat:
                return (byte: 0x02, description: "Denied. Invalid format")
            case .deniedAlreadyDefinedRPTID:
                return (byte: 0x03, description: "Denied. At least one RPTID already defined")
            case .deniedNotExistVID:
                return (byte: 0x04, description: "Denied. At least VID does not exist")
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
    
    /// LRACK
    public enum LRACK: CaseIterable, CustomStringConvertible, CustomDebugStringConvertible, Sendable {
        
        /// Accepted, byte=0x00
        case accepted
        /// Denied. Insufficient space, byte=0x01
        case deniedInsufficientSpace
        /// Denied. Invalid format, byte=0x02
        case deniedInvalidFormat
        /// Denied. At least one CEID link already defined, byte=0x03
        case deniedAlreadyDefinedCEIDLink
        /// Denied. At least one CEID does not exist, byte=0x04
        case deniedNotExistCEID
        /// Denied. At least one RPTID does not exist, byte=0x05
        case deniedNotExistRPTID
        
        private var itemProperty: (byte: UInt8, description: String) {
            switch self {
            case .accepted:
                return (byte: 0x00, description: "Accepted")
            case .deniedInsufficientSpace:
                return (byte: 0x01, description: "Denied. Insufficient space")
            case .deniedInvalidFormat:
                return (byte: 0x02, description: "Denied. Invalid format")
            case .deniedAlreadyDefinedCEIDLink:
                return (byte: 0x03, description: "Denied. At least one CEID link already defined")
            case .deniedNotExistCEID:
                return (byte: 0x04, description: "Denied. At least one CEID does not exist")
            case .deniedNotExistRPTID:
                return (byte: 0x05, description: "Denied. At least one RPTID does not exist")
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
    
    /// ERACK
    public enum ERACK: CaseIterable, CustomStringConvertible, CustomDebugStringConvertible, Sendable {
        
        /// Accepted, byte=0x00
        case accepted
        /// Denied. At least one CEID does not exist, byte=0x01
        case denied
        
        private var itemProperty: (byte: UInt8, description: String) {
            switch self {
            case .accepted:
                return (byte: 0x00, description: "Accepted")
            case .denied:
                return (byte: 0x01, description: "Denied. At least one CEID does not exist")
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
    
    /// S2F34 Define Report Acknowledge
    ///
    /// Reply message from Equipment to Host.
    ///
    /// ```
    /// S2F34
    /// <B [1] DRACK >.
    /// ```
    ///
    /// - Parameters:
    ///   - primaryMessage: The primary message
    ///   - drack: DRACK
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s2f34(primaryMessage: SECSMessage, drack: DRACK) async throws {
        try await self.communicator?.reply(primaryMessage: primaryMessage, stream: 2, function: 34, wbit: false, secs2Body: SECS2Body(binary: Data([drack.uint8Value])))
    }
    
    /// S2F36 Link Event Report Acknowledge
    ///
    /// Reply message from Equipment to Host.
    ///
    /// ```
    /// S2F36
    /// <B [1] LRACK >.
    /// ```
    ///
    /// - Parameters:
    ///   - primaryMessage: The primary message
    ///   - drack: LRACK
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s2f36(primaryMessage: SECSMessage, lrack: LRACK) async throws {
        try await self.communicator?.reply(primaryMessage: primaryMessage, stream: 2, function: 36, wbit: false, secs2Body: SECS2Body(binary: Data([lrack.uint8Value])))
    }
    
    /// S2F38 Enable/Disable Event Report Acknowledge
    ///
    /// Reply message from Equipment to Host.
    ///
    /// ```
    /// S2F38
    /// <B [1] ERACK >.
    /// ```
    ///
    /// - Parameters:
    ///   - primaryMessage: The primary message
    ///   - erack: ERACK
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s2f38(primaryMessage: SECSMessage, erack: ERACK) async throws {
        try await self.communicator?.reply(primaryMessage: primaryMessage, stream: 2, function: 38, wbit: false, secs2Body: SECS2Body(binary: Data([erack.uint8Value])))
    }

}
