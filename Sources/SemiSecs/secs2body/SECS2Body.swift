//
//  SECS2Body.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
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
    
    public static func get(itemTypeByte: UInt8) -> Self {
        let ref: UInt8 = itemTypeByte & 0xFC
        for i in Self.allCases {
            if i.itemTypeByte == ref {
                return i
            }
        }
        return .unknown
    }
    
    public static func get(smlItemString: String) -> Self {
        for i in Self.allCases {
            if i.smlString == smlItemString {
                return i
            }
        }
        return .unknown
    }
    
}

/// SECS-II-Body
public protocol SECS2Body: Equatable, Sequence, CustomStringConvertible, CustomDebugStringConvertible, Sendable {
    
    var type: SECS2BodyItemType { get }
    var count: Int { get }
    
    var data: Data { get }
    var smlString: String { get }
    var value: Any? { get }
    
    subscript(index: Int) -> Any? { get }
    
    @discardableResult
    func getSECS2Body(_ first: Int, _ indices: Int...) -> (any SECS2Body)?

    @discardableResult
    func getBool(_ first: Int, _ indices: Int...) -> Bool?
    
    @discardableResult
    func getString(_ indices: Int...) -> String?
    
    @discardableResult
    func getInt8(_ first: Int, _ indices: Int...) -> Int8?
    
    @discardableResult
    func getInt16(_ first: Int, _ indices: Int...) -> Int16?
    
    @discardableResult
    func getInt32(_ first: Int, _ indices: Int...) -> Int32?
    
    @discardableResult
    func getInt64(_ first: Int, _ indices: Int...) -> Int64?
    
    @discardableResult
    func getUInt8(_ first: Int, _ indices: Int...) -> UInt8?
    
    @discardableResult
    func getUInt16(_ first: Int, _ indices: Int...) -> UInt16?
    
    @discardableResult
    func getUInt32(_ first: Int, _ indices: Int...) -> UInt32?
    
    @discardableResult
    func getUInt64(_ first: Int, _ indices: Int...) -> UInt64?
    
    @discardableResult
    func getFloat(_ first: Int, _ indices: Int...) -> Float?
    
    @discardableResult
    func getDouble(_ first: Int, _ indices: Int...) -> Double?
    
    @discardableResult
    func getAny(_ indices: Int...) -> Any?
    
}

public extension SECS2Body {
    
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
    func getSECS2Body(_ first: Int, _ indices: Int...) -> (any SECS2Body)? {
        return nil
    }
    
    @discardableResult
    func getBool(_ first: Int, _ indices: Int...) -> Bool? {
        return nil
    }
    
    @discardableResult
    func getString(_ indices: Int...) -> String? {
        return nil
    }
    
    @discardableResult
    func getInt8(_ first: Int, _ indices: Int...) -> Int8? {
        return nil
    }
    
    @discardableResult
    func getInt16(_ first: Int, _ indices: Int...) -> Int16? {
        return nil
    }
    
    @discardableResult
    func getInt32(_ first: Int, _ indices: Int...) -> Int32? {
        return nil
    }
    
    @discardableResult
    func getInt64(_ first: Int, _ indices: Int...) -> Int64? {
        return nil
    }
    
    @discardableResult
    func getUInt8(_ first: Int, _ indices: Int...) -> UInt8? {
        return nil
    }
    
    @discardableResult
    func getUInt16(_ first: Int, _ indices: Int...) -> UInt16? {
        return nil
    }
    
    @discardableResult
    func getUInt32(_ first: Int, _ indices: Int...) -> UInt32? {
        return nil
    }
    
    @discardableResult
    func getUInt64(_ first: Int, _ indices: Int...) -> UInt64? {
        return nil
    }
    
    @discardableResult
    func getFloat(_ first: Int, _ indices: Int...) -> Float? {
        return nil
    }
    
    @discardableResult
    func getDouble(_ first: Int, _ indices: Int...) -> Double? {
        return nil
    }
    
    @discardableResult
    func getAny(_ indices: Int...) -> Any? {
        return nil
    }
    
}

public protocol SECS2BaseBody: SECS2Body {
    
    var smlValueString: String { get }
    
    @discardableResult
    func smlString(indent: String) -> String
    
    func getSECS2Body(indices: [Int]) -> (any SECS2Body)?
    func getBool(indices: [Int]) -> Bool?
    func getString(indices: [Int]) -> String?
    func getInt8(indices: [Int]) -> Int8?
    func getInt16(indices: [Int]) -> Int16?
    func getInt32(indices: [Int]) -> Int32?
    func getInt64(indices: [Int]) -> Int64?
    func getUInt8(indices: [Int]) -> UInt8?
    func getUInt16(indices: [Int]) -> UInt16?
    func getUInt32(indices: [Int]) -> UInt32?
    func getUInt64(indices: [Int]) -> UInt64?
    func getFloat(indices: [Int]) -> Float?
    func getDouble(indices: [Int]) -> Double?
    func getAny(indices: [Int]) -> Any?
    
}

public extension SECS2BaseBody {

    var smlString: String {
        return self.smlString(indent: "")
    }
    
    @discardableResult
    func smlString(indent: String) -> String {
        return "\(indent)<\(self.type.smlString) [\(self.count)] \(self.smlValueString)>"
    }
    
    func getSECS2Body(indices: [Int]) -> (any SECS2Body)? {
        return nil
    }
    
    func getBool(indices: [Int]) -> Bool? {
        return nil
    }
    
    func getString(indices: [Int]) -> String? {
        return nil
    }
    
    func getInt8(indices: [Int]) -> Int8? {
        return nil
    }
    
    func getInt16(indices: [Int]) -> Int16? {
        return nil
    }
    
    func getInt32(indices: [Int]) -> Int32? {
        return nil
    }
    
    func getInt64(indices: [Int]) -> Int64? {
        return nil
    }
    
    func getUInt8(indices: [Int]) -> UInt8? {
        return nil
    }
    
    func getUInt16(indices: [Int]) -> UInt16? {
        return nil
    }
    
    func getUInt32(indices: [Int]) -> UInt32? {
        return nil
    }
    
    func getUInt64(indices: [Int]) -> UInt64? {
        return nil
    }
    
    func getFloat(indices: [Int]) -> Float? {
        return nil
    }
    
    func getDouble(indices: [Int]) -> Double? {
        return nil
    }
    
    func getAny(indices: [Int]) -> Any? {
        return nil
    }
    
    @discardableResult
    func getSECS2Body(_ first: Int, _ indices: Int...) -> (any SECS2Body)? {
        return self.getSECS2Body(indices: [first] + indices)
    }
    
    @discardableResult
    func getString(_ indices: Int...) -> String? {
        return self.getString(indices: indices)
    }
    
    @discardableResult
    func getBool(_ first: Int, _ indices: Int...) -> Bool? {
        return self.getBool(indices: [first] + indices)
    }
    
    @discardableResult
    func getInt8(_ first: Int, _ indices: Int...) -> Int8? {
        return self.getInt8(indices: [first] + indices)
    }
    
    @discardableResult
    func getInt16(_ first: Int, _ indices: Int...) -> Int16? {
        return self.getInt16(indices: [first] + indices)
    }
    
    @discardableResult
    func getInt32(_ first: Int, _ indices: Int...) -> Int32? {
        return self.getInt32(indices: [first] + indices)
    }
    
    @discardableResult
    func getInt64(_ first: Int, _ indices: Int...) -> Int64? {
        return self.getInt64(indices: [first] + indices)
    }
    
    @discardableResult
    func getUInt8(_ first: Int, _ indices: Int...) -> UInt8? {
        return self.getUInt8(indices: [first] + indices)
    }
    
    @discardableResult
    func getUInt16(_ first: Int, _ indices: Int...) -> UInt16? {
        return self.getUInt16(indices: [first] + indices)
    }
    
    @discardableResult
    func getUInt32(_ first: Int, _ indices: Int...) -> UInt32? {
        return self.getUInt32(indices: [first] + indices)
    }
    
    @discardableResult
    func getUInt64(_ first: Int, _ indices: Int...) -> UInt64? {
        return self.getUInt64(indices: [first] + indices)
    }
    
    @discardableResult
    func getFloat(_ first: Int, _ indices: Int...) -> Float? {
        return self.getFloat(indices: [first] + indices)
    }
    
    @discardableResult
    func getDouble(_ first: Int, _ indices: Int...) -> Double? {
        return self.getDouble(indices: [first] + indices)
    }
    
    @discardableResult
    func getAny(_ indices: Int...) -> Any? {
        return self.getAny(indices: indices)
    }
    
}

/// SECS2ListBody
internal final class SECS2ListBody: SECS2BaseBody {
    
    private let _value: [any SECS2BaseBody]
    private let _data: Data?
    
    internal init(values: [any SECS2BaseBody], data: Data?) {
        self._value = values
        self._data = data
    }
    
    var type: SECS2BodyItemType {
        return .list
    }
    
    var count: Int {
        return self._value.count
    }
    
    var data: Data {
        return self._data ?? SECS2BodyEncoder.shared.encode(list: self._value)
    }
    
    private static let lineSeparator = "\n"
    private static let indent = "  "
    
    @discardableResult
    func smlString(indent: String) -> String {
        var r = "\(indent)<\(self.type.smlString) [\(self.count)]\(Self.lineSeparator)"
        for v in self._value {
            r.append(v.smlString(indent: (indent + Self.indent)))
            r.append(Self.lineSeparator)
        }
        r.append("\(indent)>")
        return r
    }
    
    var smlValueString: String {
        return ""
    }
    
    var value: Any? {
        return self._value
    }
    
    subscript(index: Int) -> Any? {
        return self.getSECS2BaseBody(index: index)
    }
    
    func makeIterator() -> IndexingIterator<[any SECS2Body]> {
        return (self._value as [any SECS2Body]).makeIterator()
    }
    
    private func getSECS2BaseBody(index: Int) -> (any SECS2BaseBody)? {
        if self._value.indices.contains(index) {
            return self._value[index]
        }
        return nil
    }
    
    func getSECS2Body(indices: [Int]) -> (any SECS2Body)? {
        let r = self.getSECS2BaseBody(index: indices[0])
        if indices.count > 1 {
            return r?.getSECS2Body(indices: Array(indices.dropFirst()))
        } else {
            return r
        }
    }
    
    func getBool(indices: [Int]) -> Bool? {
        if indices.count > 1 {
            let r = self.getSECS2BaseBody(index: indices[0])
            return r?.getBool(indices: Array(indices.dropFirst()))
        }
        return nil
    }
    
    func getString(indices: [Int]) -> String? {
        if indices.count > 0 {
            let r = self.getSECS2BaseBody(index: indices[0])
            return r?.getString(indices: Array(indices.dropFirst()))
        }
        return nil
    }
    
    func getInt8(indices: [Int]) -> Int8? {
        if indices.count > 1 {
            let r = self.getSECS2BaseBody(index: indices[0])
            return r?.getInt8(indices: Array(indices.dropFirst()))
        }
        return nil
    }
    
    func getInt16(indices: [Int]) -> Int16? {
        if indices.count > 1 {
            let r = self.getSECS2BaseBody(index: indices[0])
            return r?.getInt16(indices: Array(indices.dropFirst()))
        }
        return nil
    }
    
    func getInt32(indices: [Int]) -> Int32? {
        if indices.count > 1 {
            let r = self.getSECS2BaseBody(index: indices[0])
            return r?.getInt32(indices: Array(indices.dropFirst()))
        }
        return nil
    }
    
    func getInt64(indices: [Int]) -> Int64? {
        if indices.count > 1 {
            let r = self.getSECS2BaseBody(index: indices[0])
            return r?.getInt64(indices: Array(indices.dropFirst()))
        }
        return nil
    }
    
    func getUInt8(indices: [Int]) -> UInt8? {
        if indices.count > 1 {
            let r = self.getSECS2BaseBody(index: indices[0])
            return r?.getUInt8(indices: Array(indices.dropFirst()))
        }
        return nil
    }
    
    func getUInt16(indices: [Int]) -> UInt16? {
        if indices.count > 1 {
            let r = self.getSECS2BaseBody(index: indices[0])
            return r?.getUInt16(indices: Array(indices.dropFirst()))
        }
        return nil
    }
    
    func getUInt32(indices: [Int]) -> UInt32? {
        if indices.count > 1 {
            let r = self.getSECS2BaseBody(index: indices[0])
            return r?.getUInt32(indices: Array(indices.dropFirst()))
        }
        return nil
    }
    
    func getUInt64(indices: [Int]) -> UInt64? {
        if indices.count > 1 {
            let r = self.getSECS2BaseBody(index: indices[0])
            return r?.getUInt64(indices: Array(indices.dropFirst()))
        }
        return nil
    }
    
    func getFloat(indices: [Int]) -> Float? {
        if indices.count > 1 {
            let r = self.getSECS2BaseBody(index: indices[0])
            return r?.getFloat(indices: Array(indices.dropFirst()))
        }
        return nil
    }
    
    func getDouble(indices: [Int]) -> Double? {
        if indices.count > 1 {
            let r = self.getSECS2BaseBody(index: indices[0])
            return r?.getDouble(indices: Array(indices.dropFirst()))
        }
        return nil
    }
    
    func getAny(indices: [Int]) -> Any? {
        if indices.isEmpty {
            return self.value
        } else {
            let r = self.getSECS2BaseBody(index: indices[0])
            return r?.getAny(indices: Array(indices.dropFirst()))
        }
    }
    
}

internal struct SECS2BinaryBody: SECS2BaseBody {
    
    private let _value: Data
    private let _data: Data
    
    internal init(values: Data, data: Data) {
        self._value = values
        self._data = data
    }
    
    var type: SECS2BodyItemType {
        return .binary
    }
    
    var count: Int {
        return self._value.count
    }
    
    var data: Data {
        return self._data
    }
    
    var smlValueString: String {
        return self._value.map { String(format: "0x%02X ", $0) }.joined()
    }
    
    var value: Any? {
        return self._value
    }
    
    subscript(index: Int) -> Any? {
        if self._value.indices.contains(index) {
            return self._value[index]
        }
        return nil
    }
    
    func makeIterator() -> Data.Iterator {
        return self._value.makeIterator()
    }
    
    func getUInt8(indices: [Int]) -> UInt8? {
        if indices.count == 1 {
            let index = indices[0]
            if self._value.indices.contains(index) {
                return self._value[index]
            }
        }
        return nil
    }
    
    func getAny(indices: [Int]) -> Any? {
        if indices.isEmpty {
            return self._value
        }
        return self.getUInt8(indices: indices)
    }
    
}

internal struct SECS2BooleanBody: SECS2BaseBody {
    
    private let _value: [Bool]
    private let _data: Data
    
    internal init(values: [Bool], data: Data) {
        self._value = values
        self._data = data
    }
    
    var type: SECS2BodyItemType {
        return .boolean
    }
    
    var count: Int {
        return self._value.count
    }
    
    var data: Data {
        return self._data
    }
    
    var smlValueString: String {
        return self._value.map { "\($0 ? "TRUE" : "FALSE") " }.joined()
    }
    
    var value: Any? {
        return self._value
    }
    
    subscript(index: Int) -> Any? {
        if self._value.indices.contains(index) {
            return self._value[index]
        }
        return nil
    }
    
    func makeIterator() -> IndexingIterator<[Bool]> {
        return self._value.makeIterator()
    }
    
    func getBool(indices: [Int]) -> Bool? {
        if indices.count == 1 {
            let index = indices[0]
            if self._value.indices.contains(index) {
                return self._value[index]
            }
        }
        return nil
    }
    
    func getAny(indices: [Int]) -> Any? {
        if indices.isEmpty {
            return self._value
        }
        return self.getBool(indices: indices)
    }
    
}

internal struct SECS2AsciiBody: SECS2BaseBody {
    
    private let _value: String
    private let _data: Data
    
    internal init(values: String, data: Data) {
        self._value = values
        self._data = data
    }
    
    var type: SECS2BodyItemType {
        return .ascii
    }
    
    var count: Int {
        return self._value.count
    }
    
    var data: Data {
        return self._data
    }
    
    var smlValueString: String {
        return "\"\(self._value)\" "
    }
    
    var value: Any? {
        return self._value
    }
    
    subscript(index: Int) -> Any? {
        let chars = Array(self._value)
        return chars.indices.contains(index) ? chars[index] : nil
    }
    
    func makeIterator() -> String.Iterator {
        return self._value.makeIterator()
    }
    
    func getString(indices: [Int]) -> String? {
        if indices.isEmpty {
            return self._value
        }
        return nil
    }
    
    func getAny(indices: [Int]) -> Any? {
        if indices.count == 0 {
            return self._value
        } else if indices.count == 1 {
            let chars = Array(self._value)
            let index = indices[0]
            if chars.indices.contains(index) {
                return chars[index]
            }
            return nil
        }
        return nil
    }

}

internal struct SECS2JIS8Body: SECS2BaseBody {
    
    private let _value: Data
    private let _data: Data
    
    internal init(values: Data, data: Data) {
        self._value = values
        self._data = data
    }
    
    var type: SECS2BodyItemType {
        return .jis8
    }
    
    var count: Int {
        return self._data.count
    }
    
    var data: Data {
        return self._data
    }
    
    var smlValueString: String {
        return "UNSUPPORT "
    }
    
    subscript(index: Int) -> Any? {
        return nil
    }
    
    var value: Any? {
        return self._value
    }
    
    func makeIterator() -> Data.Iterator {
        return self._value.makeIterator()
    }
    
}

internal struct SECS2Character2BytesBody: SECS2BaseBody {
    
    private let _value: Data
    private let _data: Data
    
    internal init(values: Data, data: Data) {
        self._value = values
        self._data = data
    }
    
    var type: SECS2BodyItemType {
        return .character2bytes
    }
    
    var count: Int {
        return self._data.count
    }
    
    var data: Data {
        return self._data
    }
    
    var smlValueString: String {
        return "UNSUPPORT "
    }
    
    subscript(index: Int) -> Any? {
        return nil
    }
    
    var value: Any? {
        return self._value
    }
    
    func makeIterator() -> Data.Iterator {
        return self._value.makeIterator()
    }
    
}

internal struct SECS2Int1Body: SECS2BaseBody {
    
    private let _value: [Int8]
    private let _data: Data
    
    internal init(values: [Int8], data: Data) {
        self._value = values
        self._data = data
    }
    
    var type: SECS2BodyItemType {
        return .int1
    }
    
    var count: Int {
        return self._value.count
    }
    
    var data: Data {
        return self._data
    }
    
    var smlValueString: String {
        return self._value.map { "\($0) " }.joined()
    }
    
    var value: Any? {
        return self._value
    }
    
    subscript(index: Int) -> Any? {
        if self._value.indices.contains(index) {
            return self._value[index]
        }
        return nil
    }
    
    func makeIterator() -> IndexingIterator<[Int8]> {
        return self._value.makeIterator()
    }
    
    func getInt8(indices: [Int]) -> Int8? {
        if indices.count == 1 {
            let index = indices[0]
            if self._value.indices.contains(index) {
                return self._value[index]
            }
        }
        return nil
    }
    
    func getAny(indices: [Int]) -> Any? {
        if indices.isEmpty {
            return self._value
        }
        return self.getInt8(indices: indices)
    }

}

internal struct SECS2Int2Body: SECS2BaseBody {
    
    private let _value: [Int16]
    private let _data: Data
    
    internal init(values: [Int16], data: Data) {
        self._value = values
        self._data = data
    }
    
    var type: SECS2BodyItemType {
        return .int2
    }
    
    var count: Int {
        return self._value.count
    }
    
    var data: Data {
        return self._data
    }
    
    var smlValueString: String {
        return self._value.map { "\($0) " }.joined()
    }
    
    var value: Any? {
        return self._value
    }
    
    subscript(index: Int) -> Any? {
        if self._value.indices.contains(index) {
            return self._value[index]
        }
        return nil
    }
    
    func makeIterator() -> IndexingIterator<[Int16]> {
        return self._value.makeIterator()
    }
    
    func getInt16(indices: [Int]) -> Int16? {
        if indices.count == 1 {
            let index = indices[0]
            if self._value.indices.contains(index) {
                return self._value[index]
            }
        }
        return nil
    }
    
    func getAny(indices: [Int]) -> Any? {
        if indices.isEmpty {
            return self._value
        }
        return self.getInt16(indices: indices)
    }

}

internal struct SECS2Int4Body: SECS2BaseBody {
    
    private let _value: [Int32]
    private let _data: Data
    
    internal init(values: [Int32], data: Data) {
        self._value = values
        self._data = data
    }
    
    var type: SECS2BodyItemType {
        return .int4
    }
    
    var count: Int {
        return self._value.count
    }
    
    var data: Data {
        return self._data
    }
    
    var smlValueString: String {
        return self._value.map { "\($0) " }.joined()
    }
    
    var value: Any? {
        return self._value
    }
    
    subscript(index: Int) -> Any? {
        if self._value.indices.contains(index) {
            return self._value[index]
        }
        return nil
    }
    
    func makeIterator() -> IndexingIterator<[Int32]> {
        return self._value.makeIterator()
    }
    
    func getInt32(indices: [Int]) -> Int32? {
        if indices.count == 1 {
            let index = indices[0]
            if self._value.indices.contains(index) {
                return self._value[index]
            }
        }
        return nil
    }
    
    func getAny(indices: [Int]) -> Any? {
        if indices.isEmpty {
            return self._value
        }
        return self.getInt32(indices: indices)
    }

}

internal struct SECS2Int8Body: SECS2BaseBody {
    
    private let _value: [Int64]
    private let _data: Data
    
    internal init(values: [Int64], data: Data) {
        self._value = values
        self._data = data
    }
    
    var type: SECS2BodyItemType {
        return .int8
    }
    
    var count: Int {
        return self._value.count
    }
    
    var data: Data {
        return self._data
    }
    
    var smlValueString: String {
        return self._value.map { "\($0) " }.joined()
    }
    
    var value: Any? {
        return self._value
    }
    
    subscript(index: Int) -> Any? {
        if self._value.indices.contains(index) {
            return self._value[index]
        }
        return nil
    }
    
    func makeIterator() -> IndexingIterator<[Int64]> {
        return self._value.makeIterator()
    }
    
    func getInt64(indices: [Int]) -> Int64? {
        if indices.count == 1 {
            let index = indices[0]
            if self._value.indices.contains(index) {
                return self._value[index]
            }
        }
        return nil
    }
    
    func getAny(indices: [Int]) -> Any? {
        if indices.isEmpty {
            return self._value
        }
        return self.getInt64(indices: indices)
    }

}

internal struct SECS2UInt1Body: SECS2BaseBody {
    
    private let _value: [UInt8]
    private let _data: Data
    
    internal init(values: [UInt8], data: Data) {
        self._value = values
        self._data = data
    }
    
    var type: SECS2BodyItemType {
        return .uint1
    }
    
    var count: Int {
        return self._value.count
    }
    
    var data: Data {
        return self._data
    }
    
    var smlValueString: String {
        return self._value.map { "\($0) " }.joined()
    }
    
    var value: Any? {
        return self._value
    }
    
    subscript(index: Int) -> Any? {
        if self._value.indices.contains(index) {
            return self._value[index]
        }
        return nil
    }
    
    func makeIterator() -> IndexingIterator<[UInt8]> {
        return self._value.makeIterator()
    }
    
    func getUInt8(indices: [Int]) -> UInt8? {
        if indices.count == 1 {
            let index = indices[0]
            if self._value.indices.contains(index) {
                return self._value[index]
            }
        }
        return nil
    }
    
    func getAny(indices: [Int]) -> Any? {
        if indices.isEmpty {
            return self._value
        }
        return self.getUInt8(indices: indices)
    }

}

internal struct SECS2UInt2Body: SECS2BaseBody {
    
    private let _value: [UInt16]
    private let _data: Data
    
    internal init(values: [UInt16], data: Data) {
        self._value = values
        self._data = data
    }
    
    var type: SECS2BodyItemType {
        return .uint2
    }
    
    var count: Int {
        return self._value.count
    }
    
    var data: Data {
        return self._data
    }
    
    var smlValueString: String {
        return self._value.map { "\($0) " }.joined()
    }
    
    var value: Any? {
        return self._value
    }
    
    subscript(index: Int) -> Any? {
        if self._value.indices.contains(index) {
            return self._value[index]
        }
        return nil
    }
    
    func makeIterator() -> IndexingIterator<[UInt16]> {
        return self._value.makeIterator()
    }
    
    func getUInt16(indices: [Int]) -> UInt16? {
        if indices.count == 1 {
            let index = indices[0]
            if self._value.indices.contains(index) {
                return self._value[index]
            }
        }
        return nil
    }
    
    func getAny(indices: [Int]) -> Any? {
        if indices.isEmpty {
            return self._value
        }
        return self.getUInt16(indices: indices)
    }

}

internal struct SECS2UInt4Body: SECS2BaseBody {
    
    private let _value: [UInt32]
    private let _data: Data
    
    internal init(values: [UInt32], data: Data) {
        self._value = values
        self._data = data
    }
    
    var type: SECS2BodyItemType {
        return .uint4
    }
    
    var count: Int {
        return self._value.count
    }
    
    var data: Data {
        return self._data
    }
    
    var smlValueString: String {
        return self._value.map { "\($0) " }.joined()
    }
    
    var value: Any? {
        return self._value
    }
    
    subscript(index: Int) -> Any? {
        if self._value.indices.contains(index) {
            return self._value[index]
        }
        return nil
    }
    
    func makeIterator() -> IndexingIterator<[UInt32]> {
        return self._value.makeIterator()
    }
    
    func getUInt32(indices: [Int]) -> UInt32? {
        if indices.count == 1 {
            let index = indices[0]
            if self._value.indices.contains(index) {
                return self._value[index]
            }
        }
        return nil
    }
    
    func getAny(indices: [Int]) -> Any? {
        if indices.isEmpty {
            return self._value
        }
        return self.getUInt32(indices: indices)
    }

}

internal struct SECS2UInt8Body: SECS2BaseBody {
    
    private let _value: [UInt64]
    private let _data: Data
    
    internal init(values: [UInt64], data: Data) {
        self._value = values
        self._data = data
    }
    
    var type: SECS2BodyItemType {
        return .uint8
    }
    
    var count: Int {
        return self._value.count
    }
    
    var data: Data {
        return self._data
    }
    
    var smlValueString: String {
        return self._value.map { "\($0) " }.joined()
    }
    
    var value: Any? {
        return self._value
    }
    
    subscript(index: Int) -> Any? {
        if self._value.indices.contains(index) {
            return self._value[index]
        }
        return nil
    }
    
    func makeIterator() -> IndexingIterator<[UInt64]> {
        return self._value.makeIterator()
    }
    
    func getUInt64(indices: [Int]) -> UInt64? {
        if indices.count == 1 {
            let index = indices[0]
            if self._value.indices.contains(index) {
                return self._value[index]
            }
        }
        return nil
    }
    
    func getAny(indices: [Int]) -> Any? {
        if indices.isEmpty {
            return self._value
        }
        return self.getUInt64(indices: indices)
    }

}

internal struct SECS2Float4Body: SECS2BaseBody {
    
    private let _value: [Float]
    private let _data: Data
    
    internal init(values: [Float], data: Data) {
        self._value = values
        self._data = data
    }
    
    var type: SECS2BodyItemType {
        return .float4
    }
    
    var count: Int {
        return self._value.count
    }
    
    var data: Data {
        return self._data
    }
    
    var smlValueString: String {
        return self._value.map { "\($0) " }.joined()
    }
    
    var value: Any? {
        return self._value
    }
    
    subscript(index: Int) -> Any? {
        if self._value.indices.contains(index) {
            return self._value[index]
        }
        return nil
    }
    
    func makeIterator() -> IndexingIterator<[Float]> {
        return self._value.makeIterator()
    }
    
    func getFloat(indices: [Int]) -> Float? {
        if indices.count == 1 {
            let index = indices[0]
            if self._value.indices.contains(index) {
                return self._value[index]
            }
        }
        return nil
    }
    
    func getAny(indices: [Int]) -> Any? {
        if indices.isEmpty {
            return self._value
        }
        return self.getFloat(indices: indices)
    }

}

internal struct SECS2Float8Body: SECS2BaseBody {
    
    private let _value: [Double]
    private let _data: Data
    
    internal init(values: [Double], data: Data) {
        self._value = values
        self._data = data
    }
    
    var type: SECS2BodyItemType {
        return .float8
    }
    
    var count: Int {
        return self._value.count
    }
    
    var data: Data {
        return self._data
    }
    
    var smlValueString: String {
        return self._value.map { "\($0) " }.joined()
    }
    
    var value: Any? {
        return self._value
    }
    
    subscript(index: Int) -> Any? {
        if self._value.indices.contains(index) {
            return self._value[index]
        }
        return nil
    }
    
    func makeIterator() -> IndexingIterator<[Double]> {
        return self._value.makeIterator()
    }
    
    func getDouble(indices: [Int]) -> Double? {
        if indices.count == 1 {
            let index = indices[0]
            if self._value.indices.contains(index) {
                return self._value[index]
            }
        }
        return nil
    }
    
    func getAny(indices: [Int]) -> Any? {
        if indices.isEmpty {
            return self._value
        }
        return self.getDouble(indices: indices)
    }

}

internal struct SECS2UnknownBody: SECS2BaseBody {
    
    private let _value: Data
    private let _data: Data
    
    internal init(values: Data, data: Data) {
        self._value = values
        self._data = data
    }
    
    var type: SECS2BodyItemType {
        return .unknown
    }
    
    var count: Int {
        return self._data.count
    }
    
    var data: Data {
        return self._data
    }
    
    var smlValueString: String {
        return "UNKNOWN "
    }
    
    subscript(index: Int) -> Any? {
        return nil
    }
    
    var value: Any? {
        return self._value
    }
    
    func makeIterator() -> Data.Iterator {
        return self._value.makeIterator()
    }
    
}

internal struct SECS2ErrorBody: SECS2BaseBody {
    
    private let _data: Data
    
    internal init(data: Data) {
        self._data = data
    }
    
    var type: SECS2BodyItemType {
        return .error
    }
    
    var count: Int {
        return -1
    }
    
    var data: Data {
        return self._data
    }
    
    @discardableResult
    func smlString(indent: String) -> String {
        return "\(indent)<\(self.type.smlString) [?] >"
    }
    
    var smlValueString: String {
        return ""
    }
    
    subscript(index: Int) -> Any? {
        return nil
    }
    
    func makeIterator() -> Data.Iterator {
        return self._data.makeIterator()
    }
    
}
