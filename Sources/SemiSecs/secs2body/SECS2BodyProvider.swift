//
//  File.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/07/04.
//

import Foundation

/// SECS-II-Body Item Type.
public enum SECS2BodyItemType: CaseIterable, Sendable {
    
    /// LIST, "L", 0x01, 0x02, 0x03.
    case list
    /// BINARY, "B", 0x21, 0x22, 0x23.
    case binary
    /// BOOLEAN, "BOOLEAN", 0x25, 0x26, 0x27.
    case boolean
    /// ASCII, "A", 0x41, 0x42, 0x43.
    case ascii
    /// JIS8, NOT_SUPPORT, "JIS8", 0x45, 0x46, 0x47.
    case jis8
    /// Character-2-bytes, NOT_SUPPORT, "C2", 0x49,. 0x4A, 0x4B
    case character2bytes
    /// Signed-Int-1, "I1", 0x65, 0x66, 0x67.
    case int1
    /// Signed-Int-2, "I2", 0x69, 0x6A, 0x6B.
    case int2
    /// Signed-Int-4, "I4", 0x71, 0x72, 0x73.
    case int4
    /// Signed-Int-8, "I8", 0x61, 0x62, 0x63.
    case int8
    /// Unsigned-Int-1, "U1", 0xA5, 0xA6, 0xA7.
    case uint1
    /// Unsigned-Int-2, "U2", 0xA9, 0xAA, 0xAB.
    case uint2
    /// Unsigned-Int-4, "U4", 0xB1, 0xB2, 0xB3.
    case uint4
    /// Unsigned-Int-8, "U8", 0xA1, 0xA2, 0xA3.
    case uint8
    /// Float-4, "F4", 0x91, 0x92, 0x93.
    case float4
    /// Float-8, "F8", 0x81, 0x82, 0x83.
    case float8
    /// Unknown-Type, "?".
    case unknown
    /// Decode-Error.
    case error
    
    private var itemProperty: (smlString: String, itemTypeByte: UInt8, support: Bool) {
        switch self {
        case .list:
            return (smlString: "L", itemTypeByte: 0x00, support: true)
        case .binary:
            return (smlString: "B", itemTypeByte: 0x20, support: true)
        case .boolean:
            return (smlString: "BOOLEAN", itemTypeByte: 0x24, support: true)
        case .ascii:
            return (smlString: "A", itemTypeByte: 0x40, support: true)
        case .jis8:
            return (smlString: "JIS8", itemTypeByte: 0x44, support: false)
        case .character2bytes:
            return (smlString: "C2", itemTypeByte: 0x48, support: false)
        case .int1:
            return (smlString: "I1", itemTypeByte: 0x64, support: true)
        case .int2:
            return (smlString: "I2", itemTypeByte: 0x68, support: true)
        case .int4:
            return (smlString: "I4", itemTypeByte: 0x70, support: true)
        case .int8:
            return (smlString: "I8", itemTypeByte: 0x60, support: true)
        case .uint1:
            return (smlString: "U1", itemTypeByte: 0xA4, support: true)
        case .uint2:
            return (smlString: "U2", itemTypeByte: 0xA8, support: true)
        case .uint4:
            return (smlString: "U4", itemTypeByte: 0xB0, support: true)
        case .uint8:
            return (smlString: "U8", itemTypeByte: 0xA0, support: true)
        case .float4:
            return (smlString: "F4", itemTypeByte: 0x90, support: true)
        case .float8:
            return (smlString: "F8", itemTypeByte: 0x80, support: true)
        case .unknown:
            return (smlString: "?", itemTypeByte: 0xFF, support: false)
        case .error:
            return (smlString: "ERROR", itemTypeByte: 0xFF, support: false)
        }
    }
    
    internal var smlString: String {
        return self.itemProperty.smlString
    }
    
    internal var itemTypeByte: UInt8 {
        return self.itemProperty.itemTypeByte
    }
    
    internal var support: Bool {
        return self.itemProperty.support
    }
    
    public init(itemTypeByte: UInt8) {
        let ref: UInt8 = itemTypeByte & 0xFC
        for i in Self.allCases {
            if i.itemTypeByte == ref {
                self = i
                return
            }
        }
        self = .unknown
    }
    
    public init(smlItemString: String) {
        for i in Self.allCases {
            if i.smlString == smlItemString {
                self = i
                return
            }
        }
        self = .unknown
    }
}

/// SECS-II-Body Provider
public protocol SECS2BodyProvider: Equatable, Sequence, CustomStringConvertible, CustomDebugStringConvertible, Sendable {
    
    /// SECS2ItemType
    var type: SECS2BodyItemType { get }
    
    /// values count
    var count: Int { get }
    
    /// Data
    var data: Data { get }
    
    /// SML String
    var smlString: String { get }
    
    /// value
    var value: Any? { get }
    
    subscript(index: Int) -> Any? { get }
    
    @discardableResult
    func secs2BodyValue(at: Int, _ indices: Int...) -> (any SECS2BodyProvider)?
    
    @discardableResult
    func boolValue(at: Int, _ indices: Int...) -> Bool?
    
    @discardableResult
    func stringValue(at: Int...) -> String?
    
    @discardableResult
    func int8Value(at: Int, _ indices: Int...) -> Int8?
    
    @discardableResult
    func int16Value(at: Int, _ indices: Int...) -> Int16?
    
    @discardableResult
    func int32Value(at: Int, _ indices: Int...) -> Int32?
    
    @discardableResult
    func int64Value(at: Int, _ indices: Int...) -> Int64?
    
    @discardableResult
    func uint8Value(at: Int, _ indices: Int...) -> UInt8?
    
    @discardableResult
    func uint16Value(at: Int, _ indices: Int...) -> UInt16?
    
    @discardableResult
    func uint32Value(at: Int, _ indices: Int...) -> UInt32?
    
    @discardableResult
    func uint64Value(at: Int, _ indices: Int...) -> UInt64?
    
    @discardableResult
    func floatValue(at: Int, _ indices: Int...) -> Float?
    
    @discardableResult
    func doubleValue(at: Int, _ indices: Int...) -> Double?
    
    @discardableResult
    func anyValue(at: Int...) -> Any?
    
}

public extension SECS2BodyProvider {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.data == rhs.data
    }
    
    var description: String {
        return self.smlString
    }

    var debugDescription: String {
        return self.smlString
    }
    
    var value: Any? {
        return nil
    }

    subscript(index: Int) -> Any? {
        return nil
    }
    
    @discardableResult
    func secs2BodyValue(at: Int, _ indices: Int...) -> (any SECS2BodyProvider)? {
        return nil
    }
    
    @discardableResult
    func boolValue(at: Int, _ indices: Int...) -> Bool? {
        return nil
    }
    
    @discardableResult
    func stringValue(at: Int...) -> String? {
        return nil
    }
    
    @discardableResult
    func int8Value(at: Int, _ indices: Int...) -> Int8? {
        return nil
    }
    
    @discardableResult
    func int16Value(at: Int, _ indices: Int...) -> Int16? {
        return nil
    }
    
    @discardableResult
    func int32Value(at: Int, _ indices: Int...) -> Int32? {
        return nil
    }
    
    @discardableResult
    func int64Value(at: Int, _ indices: Int...) -> Int64? {
        return nil
    }
    
    @discardableResult
    func uint8Value(at: Int, _ indices: Int...) -> UInt8? {
        return nil
    }
    
    @discardableResult
    func uint16Value(at: Int, _ indices: Int...) -> UInt16? {
        return nil
    }
    
    @discardableResult
    func uint32Value(at: Int, _ indices: Int...) -> UInt32? {
        return nil
    }
    
    @discardableResult
    func uint64Value(at: Int, _ indices: Int...) -> UInt64? {
        return nil
    }
    
    @discardableResult
    func floatValue(at: Int, _ indices: Int...) -> Float? {
        return nil
    }
    
    @discardableResult
    func doubleValue(at: Int, _ indices: Int...) -> Double? {
        return nil
    }
    
    @discardableResult
    func anyValue(at: Int...) -> Any? {
        return nil
    }
    
}
