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
    var secs2Body: SECS2Body { get }
    
    var count: Int { get }
    var header10Bytes: [UInt8] { get }
    var system4BytesKeyValue: UInt32 { get }
    var isDataMessage: Bool { get }
    
}
