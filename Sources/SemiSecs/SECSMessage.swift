//
//  SECSMessage.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Foundation

/// SECS-Message Protocol
public protocol SECSMessage: CustomStringConvertible, CustomDebugStringConvertible, Sendable {
    
    /// Stream-Number, Return number if message-type is DATA. Readonly.
    var stream: UInt8 { get }
    
    /// Function-Number, Return number if message-type is DATA. Readonly.
    var function: UInt8 { get }
    
    /// W-Bit, Return Bool if message-type is DATA. Readonly.
    var wbit: Bool { get }
    
    /// SECS-II-Body, Readonly.
    var secs2Body: (any SECS2BodyProvider)? { get }
    
    /// Header-10-bytes. Readonly.
    var header10Bytes: Data { get }
    
    /// System-4-Bytes-32bit-unsigned-Number. Readonly.
    var system4BytesKeyValue: UInt32 { get }
    
    /// true if DATA message, otherwise false. Readonly.
    var isDataMessage: Bool { get }
    
}

public extension SECSMessage {
    
    var stream: UInt8 {
        return self.header10Bytes[2] & 0x7F
    }
    
    var function: UInt8 {
        return self.header10Bytes[3]
    }
    
    var wbit: Bool {
        return (self.header10Bytes[2] & 0x80) == 0x80
    }
    
    var system4BytesKeyValue: UInt32 {
        return (UInt32(self.header10Bytes[6]) << 24) | (UInt32(self.header10Bytes[7]) << 16) | (UInt32(self.header10Bytes[8]) << 8) | UInt32(self.header10Bytes[9])
    }
    
    var isDataMessage: Bool {
        return true
    }

}
