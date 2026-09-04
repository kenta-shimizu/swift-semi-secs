//
//  GEM+Clock.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/08/13.
//

import Foundation

extension GEM {
    
    public final class Clock {
        
        /// ClockType
        public enum ClockType: Sendable {
            
            /// ASCII 12
            case a12
            
            /// ASCII 16
            case a16
            
            fileprivate var dateFormatter: DateFormatter {
                switch self {
                case .a12:
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyMMddHHmmss"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    return formatter
                case .a16:
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyyMMddHHmmssSS"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    return formatter
                }
            }
            
        }
        
        private init() {
            // Nothing
        }
        
        public static func string(from: Date, clockType: Clock.ClockType) -> String {
            return clockType.dateFormatter.string(from: from)
        }
        
        public static func date(from: String) -> Date? {
            switch from.count {
            case 12:
                return Clock.ClockType.a12.dateFormatter.date(from: from)
            case 16:
                return Clock.ClockType.a16.dateFormatter.date(from: from)
            default:
                return nil
            }
        }

    }
    
    /// TIACK
    public enum TIACK: CaseIterable, CustomStringConvertible, CustomDebugStringConvertible, Sendable {
        
        /// OK, byte=0x00
        case ok
        /// Not accepted, byte=0x01
        case notAccepted
        
        private var itemProperty: (byte: UInt8, description: String) {
            switch self {
            case .ok:
                return (byte: 0x00, description: "OK")
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
    
    /// S2F17 Date and Time Request
    ///
    /// Send message from Equipment to Host.
    ///
    /// ```
    /// S2F17 W.
    /// ```
    ///
    /// - Returns:The Date
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    ///   - `SECSWaitReplyError`: if wait reply failed.
    ///   - `GEMError`: if unexpected response.
    @discardableResult
    public func s2f17() async throws -> Date {
        guard let s2f18 = try await self.communicator?.send(stream: 2, function: 17, wbit: true) else {
            throw GEMError.unknown
        }
        try self.checkGEMError(responseMessage: s2f18, stream: 2, function: 18)
        guard let datetime = s2f18.secs2Body?.stringValue(),
              let result = Clock.date(from: datetime) else {
            throw GEMError.illegalData(responseMesage: s2f18)
        }
        
        return result
    }
    
    /// S2F18 Date and Time Data
    ///
    /// Reply now date and time message from Host to Equipment.
    ///
    /// ```
    /// S2F18
    /// <A [12 or 16] TIME >.
    /// ```
    ///
    /// - Parameters:
    ///   - primaryMessage: The primary message
    ///   - clockType: The ClockType
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s2f18Now(primaryMessage: SECSMessage, clockType: Clock.ClockType) async throws {
        try await self.s2f18(primaryMessage: primaryMessage, date: Date(), clockType: clockType)
    }
    
    /// S2F18 Date and Time Data
    ///
    /// Reply message from Host to Equipment.
    ///
    /// ```
    /// S2F18
    /// <A [12 or 16] TIME >.
    /// ```
    ///
    /// - Parameters:
    ///   - primaryMessage: The primary message
    ///   - date: The Date
    ///   - clockType: The ClockType
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s2f18(primaryMessage: SECSMessage, date: Date, clockType: Clock.ClockType) async throws {
        try await self.s2f18(primaryMessage: primaryMessage, datetimeString: Clock.string(from: date, clockType: clockType))
    }
    
    /// S2F18 Date and Time Data
    ///
    /// Reply message from Host to Equipment.
    ///
    /// ```
    /// S2F18
    /// <A [12 or 16] TIME >.
    /// ```
    ///
    /// - Parameters:
    ///   - primaryMessage: The primary message
    ///   - datetimeString: The clock string
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s2f18(primaryMessage: SECSMessage, datetimeString: String) async throws {
        try await self.communicator?.reply(primaryMessage: primaryMessage, stream: 2, function: 18, wbit: false, secs2Body: SECS2Body(ascii: datetimeString))
    }
    
    /// S2F31 Date and Time Set Request
    ///
    /// Send now date and time message from Host to Equipment.
    ///
    /// ```
    /// S2F31 W
    /// <A [12 or 16] TIME >.
    /// ```
    ///
    /// - Parameters:
    ///   - clockType: The ClockType
    /// - Returns: TIACK
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    ///   - `SECSWaitReplyError`: if wait reply failed.
    ///   - `GEMError`: if unexpected response.
    @discardableResult
    public func s2f31Now(clockType: Clock.ClockType) async throws -> TIACK {
        return try await self.s2f31(date: Date(), clockType: clockType)
    }
    
    /// S2F31 Date and Time Set Request
    ///
    /// Send message from Host to Equipment.
    ///
    /// ```
    /// S2F31 W
    /// <A [12 or 16] TIME >.
    /// ```
    ///
    /// - Parameters:
    ///   - date: The Date
    ///   - clockType: The ClockType
    /// - Returns: TIACK
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    ///   - `SECSWaitReplyError`: if wait reply failed.
    ///   - `GEMError`: if unexpected response.
    @discardableResult
    public func s2f31(date: Date, clockType: Clock.ClockType) async throws -> TIACK {
        return try await self.s2f31(datetimeString: Clock.string(from: date, clockType: clockType))
    }
    
    /// S2F31 Date and Time Set Request
    ///
    /// Send message from Host to Equipment.
    ///
    /// ```
    /// S2F31 W
    /// <A [12 or 16] TIME >.
    /// ```
    ///
    /// - Parameters:
    ///   - datetimeString: The Date and time
    /// - Returns: TIACK
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    ///   - `SECSWaitReplyError`: if wait reply failed.
    ///   - `GEMError`: if unexpected response.
    @discardableResult
    public func s2f31(datetimeString: String) async throws -> TIACK {
        guard let s2f32 = try await self.communicator?.send(stream: 2, function: 31, wbit: true, secs2Body: SECS2Body(ascii: datetimeString)) else {
            throw GEMError.unknown
        }
        try self.checkGEMError(responseMessage: s2f32, stream: 2, function: 32)
        guard let b = s2f32.secs2Body?.uint8Value(at: 0),
              let tiack = TIACK(byte: b) else {
            throw GEMError.illegalData(responseMesage: s2f32)
        }
        
        return tiack
    }
    
    /// S2F32 Date and Time Set Acknowledge
    ///
    /// Reply message from Equipment to Host.
    ///
    /// ```
    /// S2F32
    /// <B [1] TIACK >.
    /// ```
    ///
    /// - Parameters:
    ///   - primaryMessage: The primary message
    ///   - tiack: TIACK
    /// - Throws:
    ///   - `SECSSendError`: if send failed.
    public func s2f32(primaryMessage: SECSMessage, tiack: TIACK) async throws {
        try await self.communicator?.reply(primaryMessage: primaryMessage, stream: 2, function: 32, wbit: false, secs2Body: SECS2Body(binary: Data([tiack.uint8Value])))
    }
    
}
