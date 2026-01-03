//
//  SECS2Body.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Foundation

public struct SECS2Body: CustomStringConvertible, CustomDebugStringConvertible, Sendable {
    
    public enum ItemType: Sendable {
        
        case list
        case binary
        case boolean
        case ascii
        case int1
        case int2
        case int4
        case int8
        case uint1
        case uint2
        case uint4
        case uint8
        case floar4
        case floar8
        
        case empty
        case error
        case unknown
        
        
        private var itemProperty: (smlString: String, itemTypeByte: UInt8) {
            switch self {
            case .list:
                return (smlString: "L", itemTypeByte: 0x00)
            case .binary:
                return (smlString: "B", itemTypeByte: 0x20)
            case .boolean:
                return (smlString: "BOOLEAN", itemTypeByte: 0x24)
            case .ascii:
                return (smlString: "A", itemTypeByte: 0x40)
            case .int1:
                return (smlString: "I1", itemTypeByte: 0x64)
            case .int2:
                return (smlString: "I2", itemTypeByte: 0x68)
            case .int4:
                return (smlString: "I4", itemTypeByte: 0x70)
            case .int8:
                return (smlString: "I8", itemTypeByte: 0x60)
            case .uint1:
                return (smlString: "U1", itemTypeByte: 0xA4)
            case .uint2:
                return (smlString: "U2", itemTypeByte: 0xA8)
            case .uint4:
                return (smlString: "U4", itemTypeByte: 0xB0)
            case .uint8:
                return (smlString: "U8", itemTypeByte: 0xA0)
            case .floar4:
                return (smlString: "F4", itemTypeByte: 0x90)
            case .floar8:
                return (smlString: "F8", itemTypeByte: 0x80)
            case .empty:
                return (smlString: "EMPTY", itemTypeByte: 0xFF)
            case .error:
                return (smlString: "ERROR", itemTypeByte: 0xFF)
            case .unknown:
                return (smlString: "?", itemTypeByte: 0xFF)
            }
        }
        
        
        public var smlString: String {
            return self.itemProperty.smlString
        }
        
        public var itemTypeByte: UInt8 {
            return self.itemProperty.itemTypeByte
        }
        
        private static let itemSet: [ItemType] = [
            .list,
            .binary,
            .boolean,
            .ascii,
            .int1,
            .int2,
            .int4,
            .int8,
            .uint1,
            .uint2,
            .uint4,
            .uint8,
            .floar4,
            .floar8,
        ]
        
        public static func get(itemTypeByte: UInt8) -> Self {
            let ref: UInt8 = itemTypeByte & 0xFC
            for i in Self.itemSet {
                if i.itemTypeByte == ref {
                    return i
                }
            }
            return .unknown
        }
        
        public static func get(smlItemString: String) -> Self {
            for i in Self.itemSet {
                if i.smlString == smlItemString {
                    return i
                }
            }
            return .unknown
        }
        
    }
    
    
    private class ValueBase: @unchecked Sendable {
        
        public static let lineSeparator: String = "\n"
        public static let indent: String = "  "
        
        public init() {
            /* Nothing */
        }
        
        public var itemType: ItemType {
            return .unknown
        }
        
        public var value: Any? {
            return nil
        }
        
        public var count: Int {
            return -1
        }
        
        fileprivate func createHeadData(size: Int) -> Data {
            if size > 0xFFFF {
                return Data([
                    UInt8(self.itemType.itemTypeByte | 0x03),
                    UInt8((size >> 16) & 0xFF),
                    UInt8((size >> 8) & 0xFF),
                    UInt8(size & 0xFF),
                ])
            } else if size > 0xFF {
                return Data([
                    UInt8(self.itemType.itemTypeByte | 0x02),
                    UInt8((size >> 8) & 0xFF),
                    UInt8(size & 0xFF),
                ])
            } else {
                return Data([
                    UInt8(self.itemType.itemTypeByte | 0x01),
                    UInt8(size & 0xFF),
                ])
            }
        }
        
        public var data: Data {
            return Data()
        }
        
        public var smlString: String {
            return smlString(indent: "")
        }
        
        public func smlString(indent: String) -> String {
            return "\(indent)<\(self.itemType.smlString) [\(self.count)] \(self.smlValueString)>"
        }
        
        public var smlValueString: String {
            return ""
        }
        
        public subscript(index: Int) -> Any? {
            return nil
        }
        
        public func getSECS2Body(index: Int) -> SECS2Body? {
            return nil
        }
        
        public func getAscii() -> String? {
            return nil
        }
        
        public func getBool(index: Int) -> Bool? {
            return nil
        }
        
        public func getInt8(index: Int) -> Int8? {
            return nil
        }
        
        public func getInt16(index: Int) -> Int16? {
            return nil
        }
        
        public func getInt32(index: Int) -> Int32? {
            return nil
        }
        
        public func getInt64(index: Int) -> Int64? {
            return nil
        }
        
        public func getUInt8(index: Int) -> UInt8? {
            return nil
        }
        
        public func getUInt16(index: Int) -> UInt16? {
            return nil
        }
        
        public func getUInt32(index: Int) -> UInt32? {
            return nil
        }
        
        public func getUInt64(index: Int) -> UInt64? {
            return nil
        }
        
        public func getFloat(index: Int) -> Float? {
            return nil
        }
     
        public func getDouble(index: Int) -> Double? {
            return nil
        }
        
        public func deepSeek(indices: [Int]) -> ValueBase? {
            if (indices.isEmpty) {
                return self
            } else {
                return nil
            }
        }
        
    }
    
    private class EmptyValue: ValueBase, @unchecked Sendable {
        
        public override init() {
            super.init()
        }
        
        public override var itemType: ItemType {
            return .empty
        }
        
        public override var data: Data {
            return Data()
        }
        
        public override var smlString: String {
            return ""
        }
    }
    
    private class ListValue: ValueBase, @unchecked Sendable {
        
        private let listValue: [SECS2Body]
        
        public init(secs2Bodies: [SECS2Body]) {
            self.listValue = secs2Bodies
            super.init()
        }
        
        public override var itemType: ItemType {
            return .list
        }
        
        public override var value: Any? {
            return self.listValue
        }
        
        public override var count: Int {
            return self.listValue.count
        }
        
        public override var data: Data {
            var r = self.createHeadData(size: self.count)
            for i in self.listValue {
                r.append(i.data)
            }
            return r
        }
        
        public override func smlString(indent: String) -> String {
            var r: String = indent  + "<\(self.itemType.smlString) [\(self.count)]" + Self.lineSeparator
            for v in self.listValue {
                r += v.innerValue.smlString(indent: (indent + Self.indent))
                r += Self.lineSeparator
            }
            r += indent + ">"
            return r
        }
        
        public override subscript(index: Int) -> Any? {
            return self.listValue.indices.contains(index) ? self.listValue[index] : nil
        }
        
        public override func getSECS2Body(index: Int) -> SECS2Body? {
            return self.listValue.indices.contains(index) ? self.listValue[index] : nil
        }
        
        public override func deepSeek(indices: [Int]) -> ValueBase? {
            if (indices.isEmpty) {
                return self
            } else {
                var ll: [Int] = indices
                let index: Int = ll.removeFirst()
                return self.getSECS2Body(index: index)?.innerValue.deepSeek(indices: ll)
            }
        }
        
    }

    private class BinaryValue: ValueBase, @unchecked Sendable {
        
        private let binaryValue: [UInt8]
        
        public init(binary: [UInt8]) {
            self.binaryValue = binary
            super.init()
        }
        
        public override var itemType: ItemType {
            return .binary
        }
        
        public override var value: Any? {
            return self.binaryValue
        }
        
        public override var count: Int {
            return self.binaryValue.count
        }
        
        public override var data: Data {
            let v = Data(self.binaryValue)
            return self.createHeadData(size: v.count) + v
        }
        
        public override var smlValueString: String {
            return self.binaryValue.map { String(format: "0x%02X ", $0) }.joined()
        }
        
        public override subscript(index: Int) -> Any? {
            return self.binaryValue.indices.contains(index) ? self.binaryValue[index] : nil
        }
        
        public override func getUInt8(index: Int) -> UInt8? {
            return self.binaryValue.indices.contains(index) ? self.binaryValue[index] : nil
        }
        
    }

    private class BooleanValue: ValueBase, @unchecked Sendable {
        
        private let booleanValue: [Bool]
        
        public init(boolean: [Bool]) {
            self.booleanValue = boolean
            super.init()
        }
        
        public override var itemType: ItemType {
            return .boolean
        }
        
        public override var value: Any? {
            return self.booleanValue
        }
        
        public override var count: Int {
            return self.booleanValue.count
        }
        
        public override var data: Data {
            let v = Data(self.booleanValue.map( {UInt8($0 ? 0xFF : 0x00)}))
            return self.createHeadData(size: v.count) + v
        }
        
        public override var smlValueString: String {
            return self.booleanValue.map { $0 ? "TRUE " : "FALSE " }.joined()
        }
        
        public override subscript(index: Int) -> Any? {
            return self.booleanValue.indices.contains(index) ? self.booleanValue[index] : nil
        }
        
        public override func getBool(index: Int) -> Bool? {
            return self.booleanValue.indices.contains(index) ? self.booleanValue[index] : nil
        }
        
    }
    
    private class AsciiValue: ValueBase, @unchecked Sendable {
        
        private let asciiValue: String
        private let asciiData: Data
        
        public init(asciiString: String, asciiData: Data) {
            self.asciiValue = asciiString
            self.asciiData = asciiData
            super.init();
        }
        
        public override var itemType: ItemType {
            return .ascii
        }
        
        public override var value: Any? {
            return self.asciiValue
        }
        
        public override var count: Int {
            return self.asciiData.count
        }
        
        public override var data: Data {
            return self.createHeadData(size: self.asciiData.count) + self.asciiData
        }
        
        public override var smlValueString: String {
            return "\"\(self.asciiValue)\" "
        }
        
        public override subscript(index: Int) -> Any? {
            if let stringIndex = self.asciiValue.index(self.asciiValue.startIndex, offsetBy: index, limitedBy: self.asciiValue.endIndex) {
                return self.asciiValue[stringIndex]
            } else {
                return nil
            }
        }
        
        public override func getAscii() -> String? {
            return self.asciiValue
        }
        
    }
    
    private class Int1Value: ValueBase, @unchecked Sendable {
        
        private let int1Value: [Int8]
        private let int1Data: Data
        
        public init(int1: [Int8], data: Data) {
            self.int1Value = int1
            self.int1Data = data
            super.init()
        }
        
        public override var itemType: ItemType {
            return .int1
        }
        
        public override var value: Any? {
            return self.int1Value
        }
        
        public override var count: Int {
            return self.int1Value.count
        }
        
        public override var data: Data {
            return self.createHeadData(size: self.int1Data.count) + self.int1Data
        }
        
        public override var smlValueString: String {
            return self.int1Value.map { "\($0) " }.joined()
        }
        
        public override subscript(index: Int) -> Any? {
            return self.int1Value[index]
        }
        
        public override func getInt8(index: Int) -> Int8? {
            return self.int1Value.indices.contains(index) ? self.int1Value[index] : nil
        }
        
    }
    
    private class Int2Value: ValueBase, @unchecked Sendable {
        
        private let int2Value: [Int16]
        private let int2Data: Data
        
        public init(int2: [Int16], data: Data) {
            self.int2Value = int2
            self.int2Data = data
            super.init()
        }
        
        public override var itemType: ItemType {
            return .int2
        }
        
        public override var value: Any? {
            return self.int2Value
        }
        
        public override var count: Int {
            return self.int2Value.count
        }
        
        public override var data: Data {
            return self.createHeadData(size: self.int2Data.count) + self.int2Data
        }
        
        public override var smlValueString: String {
            return self.int2Value.map { "\($0) " }.joined()
        }
        
        public override subscript(index: Int) -> Any? {
            return self.int2Value[index]
        }
        
        public override func getInt16(index: Int) -> Int16? {
            return self.int2Value.indices.contains(index) ? self.int2Value[index] : nil
        }
        
    }
    
    private class Int4Value: ValueBase, @unchecked Sendable {
        
        private let int4Value: [Int32]
        private let int4Data: Data
        
        public init(int4: [Int32], data: Data) {
            self.int4Value = int4
            self.int4Data = data
            super.init()
        }
        
        public override var itemType: ItemType {
            return .int4
        }
        
        public override var value: Any? {
            return self.int4Value
        }
        
        public override var count: Int {
            return self.int4Value.count
        }
        
        public override var data: Data {
            return self.createHeadData(size: self.int4Data.count) + self.int4Data
        }
        
        public override var smlValueString: String {
            return self.int4Value.map { "\($0) " }.joined()
        }
        
        public override subscript(index: Int) -> Any? {
            return self.int4Value[index]
        }
        
        public override func getInt32(index: Int) -> Int32? {
            return self.int4Value.indices.contains(index) ? self.int4Value[index] : nil
        }
        
    }
    
    private class Int8Value: ValueBase, @unchecked Sendable {
        
        private let int8Value: [Int64]
        private let int8Data: Data
        
        public init(int8: [Int64], data: Data) {
            self.int8Value = int8
            self.int8Data = data
            super.init()
        }
        
        public override var itemType: ItemType {
            return .int8
        }
        
        public override var value: Any? {
            return self.int8Value
        }
        
        public override var count: Int {
            return self.int8Value.count
        }
        
        public override var data: Data {
            return self.createHeadData(size: self.int8Data.count) + self.int8Data
        }
        
        public override var smlValueString: String {
            return self.int8Value.map { "\($0) " }.joined()
        }
        
        public override subscript(index: Int) -> Any? {
            return self.int8Value[index]
        }
        
        public override func getInt64(index: Int) -> Int64? {
            return self.int8Value.indices.contains(index) ? self.int8Value[index] : nil
        }
        
    }
    
    private class UInt1Value: ValueBase, @unchecked Sendable {
        
        private let uint1Value: [UInt8]
        private let uint1Data: Data
        
        public init(uint1: [UInt8], data: Data) {
            self.uint1Value = uint1
            self.uint1Data = data
            super.init()
        }
        
        public override var itemType: ItemType {
            return .uint1
        }
        
        public override var value: Any? {
            return self.uint1Value
        }
        
        public override var count: Int {
            return self.uint1Value.count
        }
        
        public override var data: Data {
            return self.createHeadData(size: self.uint1Data.count) + self.uint1Data
        }
        
        public override var smlValueString: String {
            return self.uint1Value.map { "\($0) " }.joined()
        }
        
        public override subscript(index: Int) -> Any? {
            return self.uint1Value[index]
        }
        
        public override func getUInt8(index: Int) -> UInt8? {
            return self.uint1Value.indices.contains(index) ? self.uint1Value[index] : nil
        }
        
    }
    
    private class UInt2Value: ValueBase, @unchecked Sendable {
        
        private let uint2Value: [UInt16]
        private let uint2Data: Data
        
        public init(uint2: [UInt16], data: Data) {
            self.uint2Value = uint2
            self.uint2Data = data
            super.init()
        }
        
        public override var itemType: ItemType {
            return .uint2
        }
        
        public override var value: Any? {
            return self.uint2Value
        }
        
        public override var count: Int {
            return self.uint2Value.count
        }
        
        public override var data: Data {
            return self.createHeadData(size: self.uint2Data.count) + self.uint2Data
        }
        
        public override var smlValueString: String {
            return self.uint2Value.map { "\($0) " }.joined()
        }
        
        public override subscript(index: Int) -> Any? {
            return self.uint2Value[index]
        }
        
        public override func getUInt16(index: Int) -> UInt16? {
            return self.uint2Value.indices.contains(index) ? self.uint2Value[index] : nil
        }
        
    }
    
    private class UInt4Value: ValueBase, @unchecked Sendable {
        
        private let uint4Value: [UInt32]
        private let uint4Data: Data
        
        public init(uint4: [UInt32], data: Data) {
            self.uint4Value = uint4
            self.uint4Data = data
            super.init()
        }
        
        public override var itemType: ItemType {
            return .uint4
        }
        
        public override var value: Any? {
            return self.uint4Value
        }
        
        public override var count: Int {
            return self.uint4Value.count
        }
        
        public override var data: Data {
            return self.createHeadData(size: self.uint4Data.count) + self.uint4Data
        }
        
        public override var smlValueString: String {
            return self.uint4Value.map { "\($0) " }.joined()
        }
        
        public override subscript(index: Int) -> Any? {
            return self.uint4Value[index]
        }
        
        public override func getUInt32(index: Int) -> UInt32? {
            return self.uint4Value.indices.contains(index) ? self.uint4Value[index] : nil
        }
        
    }
    
    private class UInt8Value: ValueBase, @unchecked Sendable {
        
        private let uint8Value: [UInt64]
        private let uint8Data: Data
        
        public init(uint8: [UInt64], data: Data) {
            self.uint8Value = uint8
            self.uint8Data = data
            super.init()
        }
        
        public override var itemType: ItemType {
            return .uint8
        }
        
        public override var value: Any? {
            return self.uint8Value
        }
        
        public override var count: Int {
            return self.uint8Value.count
        }
        
        public override var data: Data {
            return self.createHeadData(size: self.uint8Data.count) + self.uint8Data
        }
        
        public override var smlValueString: String {
            return self.uint8Value.map { "\($0) " }.joined()
        }
        
        public override subscript(index: Int) -> Any? {
            return self.uint8Value[index]
        }
        
        public override func getUInt64(index: Int) -> UInt64? {
            return self.uint8Value.indices.contains(index) ? self.uint8Value[index] : nil
        }
        
    }
    
    private class Float4Value: ValueBase, @unchecked Sendable {
        
        private let float4Value: [Float]
        private let float4Data: Data
        
        public init(float4: [Float], data: Data) {
            self.float4Value = float4
            self.float4Data = data
            super.init()
        }
        
        public override var itemType: ItemType {
            return .floar4
        }
        
        public override var value: Any? {
            return self.float4Value
        }
        
        public override var count: Int {
            return self.float4Value.count
        }
        
        public override var data: Data {
            return self.createHeadData(size: self.float4Data.count) + self.float4Data
        }
        
        public override var smlValueString: String {
            return self.float4Value.map { "\($0) " }.joined()
        }
        
        public override subscript(index: Int) -> Any? {
            return self.float4Value[index]
        }
        
        public override func getFloat(index: Int) -> Float? {
            return self.float4Value.indices.contains(index) ? self.float4Value[index] : nil
        }
        
    }
    
    private class Float8Value: ValueBase, @unchecked Sendable {
        
        private let float8Value: [Double]
        private let float8Data: Data
        
        public init(float8: [Double], data: Data) {
            self.float8Value = float8
            self.float8Data = data
            super.init()
        }
        
        public override var itemType: ItemType {
            return .floar8
        }
        
        public override var value: Any? {
            return self.float8Value
        }
        
        public override var count: Int {
            return self.float8Value.count
        }
        
        public override var data: Data {
            return self.createHeadData(size: self.float8Data.count) + self.float8Data
        }
        
        public override var smlValueString: String {
            return self.float8Value.map { "\($0) " }.joined()
        }
        
        public override subscript(index: Int) -> Any? {
            return self.float8Value[index]
        }
        
        public override func getDouble(index: Int) -> Double? {
            return self.float8Value.indices.contains(index) ? self.float8Value[index] : nil
        }
        
    }
    
    private class UnknownValue: ValueBase, @unchecked Sendable {
        
        private let unknownData: Data
        
        public init(data: Data) {
            self.unknownData = data
            super.init()
        }
        
        public override var itemType: ItemType {
            return .unknown
        }
        
        public override var data: Data {
            return self.unknownData
        }
        
        public override func smlString(indent: String) -> String {
            return "\(indent)<\(self.itemType.smlString) [?] >"
        }
        
    }
    
    private class ErrorValue: ValueBase, @unchecked Sendable {
        
        private let errorData: Data
        
        public init(data: Data) {
            self.errorData = data
            super.init()
        }
        
        public override var itemType: ItemType {
            return .error
        }
        
        public override var data: Data {
            return self.errorData
        }
        
        public override func smlString(indent: String) -> String {
            return "\(indent)<\(self.itemType.smlString) [?] >"
        }

    }
    
    private class DataValue: ValueBase, @unchecked Sendable {
        
        private let refValue: ValueBase
        private let refData: Data
        
        public init(data: Data, value: ValueBase) {
            self.refValue = value
            self.refData = data
            super.init()
        }
        
        public override var itemType: ItemType {
            return self.refValue.itemType
        }
        
        public override var value: Any? {
            return self.refValue.value
        }
        
        public override var count: Int {
            return self.refValue.count
        }
        
        public override var data: Data {
            return self.refData
        }
        
        public override var smlString: String {
            return self.refValue.smlString
        }
        
        public override func smlString(indent: String) -> String {
            return self.refValue.smlString(indent: indent)
        }
        
        public override var smlValueString: String {
            return self.refValue.smlValueString
        }
        
        public override subscript(index: Int) -> Any? {
            return self.refValue[index]
        }
        
        public override func getSECS2Body(index: Int) -> SECS2Body? {
            return self.refValue.getSECS2Body(index: index)
        }
        
        public override func getAscii() -> String? {
            return self.refValue.getAscii()
        }
        
        public override func getBool(index: Int) -> Bool? {
            return self.refValue.getBool(index: index)
        }
        
        public override func getInt8(index: Int) -> Int8? {
            return self.refValue.getInt8(index: index)
        }
        
        public override func getInt16(index: Int) -> Int16? {
            return self.refValue.getInt16(index: index)
        }
        
        public override func getInt32(index: Int) -> Int32? {
            return self.refValue.getInt32(index: index)

        }
        
        public override func getInt64(index: Int) -> Int64? {
            return self.refValue.getInt64(index: index)
        }
        
        public override func getUInt8(index: Int) -> UInt8? {
            return self.refValue.getUInt8(index: index)
        }
        
        public override func getUInt16(index: Int) -> UInt16? {
            return self.refValue.getUInt16(index: index)
        }
        
        public override func getUInt32(index: Int) -> UInt32? {
            return self.refValue.getUInt32(index: index)
        }
        
        public override func getUInt64(index: Int) -> UInt64? {
            return self.refValue.getUInt64(index: index)
        }
        
        public override func getFloat(index: Int) -> Float? {
            return self.refValue.getFloat(index: index)
        }
     
        public override func getDouble(index: Int) -> Double? {
            return self.refValue.getDouble(index: index)
        }
        
    }
    
    
    private static let sizeLimit: Int = 0x00FFFFFF
    
    private let innerValue: ValueBase
    
    public init() {
        self.innerValue = EmptyValue()
    }
    
    public init(list: [SECS2Body]) {
        guard list.count <= Self.sizeLimit else {
            fatalError("Item size error. size:\(list.count)")
        }
        self.innerValue = ListValue(secs2Bodies: list)
    }
    
    public init(binary: [UInt8]) {
        guard binary.count <= Self.sizeLimit else {
            fatalError("Item size error. size:\(binary.count)")
        }
        self.innerValue = BinaryValue(binary: binary)
    }
    
    public init(boolean: [Bool]) {
        guard boolean.count <= Self.sizeLimit else {
            fatalError("Item size error. size:\(boolean.count)")
        }
        self.innerValue = BooleanValue(boolean: boolean)
    }
    
    public init(ascii: String) {
        guard let data = ascii.data(using: .ascii) else {
            fatalError("ASCII encode error: \"\(ascii)\"")
        }
        guard data.count <= Self.sizeLimit else {
            fatalError("Item size error. size:\(data.count)")
        }
        self.innerValue = AsciiValue(asciiString: ascii, asciiData: data)
    }
    
    public init(int1: [Int8]) {
        let data: Data = int1.withUnsafeBufferPointer { p in Data(buffer: p) }
        guard data.count <= Self.sizeLimit else {
            fatalError("Item size error. size:\(data.count)")
        }
        self.innerValue = Int1Value(int1: int1, data: data)
    }
    
    public init(int2: [Int16]) {
        let data: Data = int2.map { $0.bigEndian }.withUnsafeBufferPointer { p in Data(buffer: p) }
        guard data.count <= Self.sizeLimit else {
            fatalError("Item size error. size:\(data.count)")
        }
        self.innerValue = Int2Value(int2: int2, data: data)
    }
    
    public init(int4: [Int32]) {
        let data: Data = int4.map { $0.bigEndian }.withUnsafeBufferPointer { p in Data(buffer: p) }
        guard data.count <= Self.sizeLimit else {
            fatalError("Item size error. size:\(data.count)")
        }
        self.innerValue = Int4Value(int4: int4, data: data)
    }

    public init(int8: [Int64]) {
        let data: Data = int8.map { $0.bigEndian }.withUnsafeBufferPointer { p in Data(buffer: p) }
        guard data.count <= Self.sizeLimit else {
            fatalError("Item size error. size:\(data.count)")
        }
        self.innerValue = Int8Value(int8: int8, data: data)
    }
    
    public init(uint1: [UInt8]) {
        let data: Data = uint1.withUnsafeBufferPointer { p in Data(buffer: p) }
        guard data.count <= Self.sizeLimit else {
            fatalError("Item size error. size:\(data.count)")
        }
        self.innerValue = UInt1Value(uint1: uint1, data: data)
    }
    
    public init(uint2: [UInt16]) {
        let data: Data = uint2.map { $0.bigEndian }.withUnsafeBufferPointer { p in Data(buffer: p) }
        guard data.count <= Self.sizeLimit else {
            fatalError("Item size error. size:\(data.count)")
        }
        self.innerValue = UInt2Value(uint2: uint2, data: data)
    }
    
    public init(uint4: [UInt32]) {
        let data: Data = uint4.map { $0.bigEndian }.withUnsafeBufferPointer { p in Data(buffer: p) }
        guard data.count <= Self.sizeLimit else {
            fatalError("Item size error. size:\(data.count)")
        }
        self.innerValue = UInt4Value(uint4: uint4, data: data)
    }

    public init(uint8: [UInt64]) {
        let data: Data = uint8.map { $0.bigEndian }.withUnsafeBufferPointer { p in Data(buffer: p) }
        guard data.count <= Self.sizeLimit else {
            fatalError("Item size error. size:\(data.count)")
        }
        self.innerValue = UInt8Value(uint8: uint8, data: data)
    }
    
    public init(float4: [Float]) {
        let data: Data = float4.withUnsafeBufferPointer { p in Data(buffer: p) }
        guard data.count <= Self.sizeLimit else {
            fatalError("Item size error. size:\(data.count)")
        }
        self.innerValue = Float4Value(float4: float4, data: data)
    }
    
    public init(float8: [Double]) {
        let data: Data = float8.withUnsafeBufferPointer { p in Data(buffer: p) }
        guard data.count <= Self.sizeLimit else {
            fatalError("Item size error. size:\(data.count)")
        }
        self.innerValue = Float8Value(float8: float8, data: data)
    }
    
    public init(data: Data) {
        if data.isEmpty {
            self.innerValue = EmptyValue()
        } else {
            if let r = Self.decode(data: data, startIndex: 0) {
                if r.endIndex == data.count {
                    self.innerValue = r.value
                } else {
                    self.innerValue = ErrorValue(data: data)
                }
            } else {
                self.innerValue = ErrorValue(data: data)
            }
        }
    }
    
    private init(data: Data, startIndex: Int) {
        if let r = Self.decode(data: data, startIndex: startIndex) {
            self.innerValue = r.value
        } else {
            self.innerValue = ErrorValue(data: data)
        }
    }
    
    public var value: Any? {
        return self.innerValue.value
    }
    
    public var count: Int {
        return self.innerValue.count
    }
    
    public var itemType: ItemType {
        return self.innerValue.itemType
    }
    
    public var data: Data {
        return self.innerValue.data
    }
    
    public var smlString: String {
        return self.innerValue.smlString
    }
    
    public var isEmpty: Bool {
        return self.data.isEmpty
    }

    public var description: String {
        return self.smlString
    }
    
    public var debugDescription: String {
        return self.smlString
    }
    
    public subscript(index: Int) -> Any? {
        return self.innerValue[index]
    }
    
    private static func removeLastIndex(_ indices: [Int]) -> (indices: [Int], index: Int) {
        var ll = indices
        let index = ll.removeLast()
        return (indices: ll, index: index)
    }
    
    public func getAscii(_ indices: Int...) -> String? {
        return self.innerValue.deepSeek(indices: indices)?.getAscii()
    }
    
    public func getBool(_ indices: Int...) -> Bool? {
        if (indices.isEmpty) {
            return nil
        } else {
            let r = Self.removeLastIndex(indices)
            return self.innerValue.deepSeek(indices: r.indices)?.getBool(index: r.index)
        }
    }
    
    public func getInt8(_ indices: Int...) -> Int8? {
        if (indices.isEmpty) {
            return nil
        } else {
            let r = Self.removeLastIndex(indices)
            return self.innerValue.deepSeek(indices: r.indices)?.getInt8(index: r.index)
        }
    }
    
    public func getInt16(_ indices: Int...) -> Int16? {
        if (indices.isEmpty) {
            return nil
        } else {
            let r = Self.removeLastIndex(indices)
            return self.innerValue.deepSeek(indices: r.indices)?.getInt16(index: r.index)
        }
    }
    
    public func getInt32(_ indices: Int...) -> Int32? {
        if (indices.isEmpty) {
            return nil
        } else {
            let r = Self.removeLastIndex(indices)
            return self.innerValue.deepSeek(indices: r.indices)?.getInt32(index: r.index)
        }
    }
    
    public func getInt64(_ indices: Int...) -> Int64? {
        if (indices.isEmpty) {
            return nil
        } else {
            let r = Self.removeLastIndex(indices)
            return self.innerValue.deepSeek(indices: r.indices)?.getInt64(index: r.index)
        }
    }
    
    public func getUInt8(_ indices: Int...) -> UInt8? {
        if (indices.isEmpty) {
            return nil
        } else {
            let r = Self.removeLastIndex(indices)
            return self.innerValue.deepSeek(indices: r.indices)?.getUInt8(index: r.index)
        }
    }
    
    public func getUInt16(_ indices: Int...) -> UInt16? {
        if (indices.isEmpty) {
            return nil
        } else {
            let r = Self.removeLastIndex(indices)
            return self.innerValue.deepSeek(indices: r.indices)?.getUInt16(index: r.index)
        }
    }

    public func getUInt32(_ indices: Int...) -> UInt32? {
        if (indices.isEmpty) {
            return nil
        } else {
            let r = Self.removeLastIndex(indices)
            return self.innerValue.deepSeek(indices: r.indices)?.getUInt32(index: r.index)
        }
    }
    
    public func getUInt64(_ indices: Int...) -> UInt64? {
        if (indices.isEmpty) {
            return nil
        } else {
            let r = Self.removeLastIndex(indices)
            return self.innerValue.deepSeek(indices: r.indices)?.getUInt64(index: r.index)
        }
    }
    
    public func getFloat(_ indices: Int...) -> Float? {
        if (indices.isEmpty) {
            return nil
        } else {
            let r = Self.removeLastIndex(indices)
            return self.innerValue.deepSeek(indices: r.indices)?.getFloat(index: r.index)
        }
    }
    
    public func getDouble(_ indices: Int...) -> Double? {
        if (indices.isEmpty) {
            return nil
        } else {
            let r = Self.removeLastIndex(indices)
            return self.innerValue.deepSeek(indices: r.indices)?.getDouble(index: r.index)
        }
    }
    
    public func getAny(_ indices: Int...) -> Any? {
        if (indices.isEmpty) {
            return nil
        } else {
            let r = Self.removeLastIndex(indices)
            return self.innerValue.deepSeek(indices: r.indices)?[r.index]
        }
    }
    
    private static func decode(data: Data, startIndex: Int) -> (value: ValueBase, endIndex: Int)? {
        
        guard let r = Self.decodeItemTypeAndSize(data: data, startIndex: startIndex) else {
            return nil
        }
        
        if r.itemType == .list {
            
            var secs2bodies: [SECS2Body] = []
            var presentIndex = startIndex + r.skip
            
            for _ in 0..<r.size {
                
                let ss = Self.init(data: data, startIndex: presentIndex)
                
                guard ss.itemType != .error else {
                    return nil
                }
                
                secs2bodies.append(ss)
            
                presentIndex += ss.data.count
            }
            
            let extractData = data.subdata(in: startIndex..<presentIndex)
            
            return (value: DataValue(data: extractData, value: ListValue(secs2Bodies: secs2bodies)), endIndex: presentIndex)
            
        } else {
            
            let endIndex = startIndex + r.skip + r.size
            guard endIndex <= data.count else {
                return  nil
            }
            
            let extractData = data.subdata(in: startIndex..<endIndex)
            let valueData = data.subdata(in: (startIndex + r.skip)..<endIndex)
            
            switch r.itemType {
            case .binary:
                let binaryValue = [UInt8](valueData)
                return (value: DataValue(data: extractData, value: BinaryValue(binary: binaryValue)), endIndex: endIndex)
                
            case .boolean:
                let booleanValue: [Bool] = [UInt8](valueData).map { ($0 == 0x00) ? false : true }
                return (value: DataValue(data: extractData, value: BooleanValue(boolean: booleanValue)), endIndex: endIndex)
                
            case .ascii:
                guard let asciiString: String = String(data: valueData, encoding: .ascii) else {
                    return nil
                }
                return (value: DataValue(data: extractData, value: AsciiValue(asciiString: asciiString, asciiData: valueData)), endIndex: endIndex)
                
            case .int1:
                let int1Value = valueData.withUnsafeBytes { (p: UnsafeRawBufferPointer) -> [Int8] in
                    let count = p.count / MemoryLayout<Int8>.size
                    return p.bindMemory(to: Int8.self).prefix(count).map { $0 }
                }
                return (value: DataValue(data: extractData, value: Int1Value(int1: int1Value, data: valueData)), endIndex: endIndex)
                
            case .int2:
                guard valueData.count % MemoryLayout<Int16>.size == 0 else {
                    return nil
                }
                let int2Value = valueData.withUnsafeBytes { (p: UnsafeRawBufferPointer) -> [Int16] in
                    let count = p.count / MemoryLayout<Int16>.size
                    return p.bindMemory(to: Int16.self).prefix(count).map { $0.bigEndian }
                }
                return (value: DataValue(data: extractData, value: Int2Value(int2: int2Value, data: valueData)), endIndex: endIndex)
                
            case .int4:
                guard valueData.count % MemoryLayout<Int32>.size == 0 else {
                    return nil
                }
                let int4Value = valueData.withUnsafeBytes { (p: UnsafeRawBufferPointer) -> [Int32] in
                    let count = p.count / MemoryLayout<Int32>.size
                    return p.bindMemory(to: Int32.self).prefix(count).map { $0.bigEndian }
                }
                return (value: DataValue(data: extractData, value: Int4Value(int4: int4Value, data: valueData)), endIndex: endIndex)
                
            case .int8:
                guard valueData.count % MemoryLayout<Int64>.size == 0 else {
                    return nil
                }
                let int8Value = valueData.withUnsafeBytes { (p: UnsafeRawBufferPointer) -> [Int64] in
                    let count = p.count / MemoryLayout<Int64>.size
                    return p.bindMemory(to: Int64.self).prefix(count).map { $0.bigEndian }
                }
                return (value: DataValue(data: extractData, value: Int8Value(int8: int8Value, data: valueData)), endIndex: endIndex)
                
            case .uint1:
                let uint1Value = valueData.withUnsafeBytes { (p: UnsafeRawBufferPointer) -> [UInt8] in
                    let count = p.count / MemoryLayout<UInt8>.size
                    return p.bindMemory(to: UInt8.self).prefix(count).map { $0 }
                }
                return (value: DataValue(data: extractData, value: UInt1Value(uint1: uint1Value, data: valueData)), endIndex: endIndex)
                
            case .uint2:
                guard valueData.count % MemoryLayout<UInt16>.size == 0 else {
                    return nil
                }
                let uint2Value = valueData.withUnsafeBytes { (p: UnsafeRawBufferPointer) -> [UInt16] in
                    let count = p.count / MemoryLayout<UInt16>.size
                    return p.bindMemory(to: UInt16.self).prefix(count).map { $0.bigEndian }
                }
                return (value: DataValue(data: extractData, value: UInt2Value(uint2: uint2Value, data: valueData)), endIndex: endIndex)
                
            case .uint4:
                guard valueData.count % MemoryLayout<UInt32>.size == 0 else {
                    return nil
                }
                let uint4Value = valueData.withUnsafeBytes { (p: UnsafeRawBufferPointer) -> [UInt32] in
                    let count = p.count / MemoryLayout<UInt32>.size
                    return p.bindMemory(to: UInt32.self).prefix(count).map { $0.bigEndian }
                }
                return (value: DataValue(data: extractData, value: UInt4Value(uint4: uint4Value, data: valueData)), endIndex: endIndex)
                
            case .uint8:
                guard valueData.count % MemoryLayout<UInt64>.size == 0 else {
                    return nil
                }
                let uint8Value = valueData.withUnsafeBytes { (p: UnsafeRawBufferPointer) -> [UInt64] in
                    let count = p.count / MemoryLayout<UInt64>.size
                    return p.bindMemory(to: UInt64.self).prefix(count).map { $0.bigEndian }
                }
                return (value: DataValue(data: extractData, value: UInt8Value(uint8: uint8Value, data: valueData)), endIndex: endIndex)
                
            case .floar4:
                guard valueData.count % MemoryLayout<Float>.size == 0 else {
                    return nil
                }
                let float4Value = valueData.withUnsafeBytes { (p: UnsafeRawBufferPointer) -> [Float] in
                    let count = p.count / MemoryLayout<Float>.size
                    return p.bindMemory(to: Float.self).prefix(count).map { $0 }
                }
                return (value: DataValue(data: extractData, value: Float4Value(float4: float4Value, data: valueData)), endIndex: endIndex)
                
            case .floar8:
                guard valueData.count % MemoryLayout<Double>.size == 0 else {
                    return nil
                }
                let float8Value = valueData.withUnsafeBytes { (p: UnsafeRawBufferPointer) -> [Double] in
                    let count = p.count / MemoryLayout<Double>.size
                    return p.bindMemory(to: Double.self).prefix(count).map { $0 }
                }
                return (value: DataValue(data: extractData, value: Float8Value(float8: float8Value, data: valueData)), endIndex: endIndex)
                
            case .unknown:
                return (value: DataValue(data: extractData, value: UnknownValue(data: extractData)), endIndex: endIndex)
                
            default:
                return nil
            }
        }
    }
    
    private static func decodeItemTypeAndSize(data: Data, startIndex: Int) -> (itemType: ItemType, size: Int, skip: Int)? {
        
        guard startIndex < data.count else {
            return nil
        }
        
        let itemType = ItemType.get(itemTypeByte: data[startIndex])
        let lengthByte = data[startIndex] & 0x03
        
        switch lengthByte {
        case 1:
            guard (startIndex + 1) < data.count else {
                return nil
            }
            let size = Int(data[startIndex + 1])
            return (itemType: itemType, size: size, skip: 2)
            
        case 2:
            guard (startIndex + 2) < data.count else {
                return nil
            }
            let size = (Int(data[startIndex + 1]) << 8) | Int(data[startIndex + 2])
            return (itemType: itemType, size: size, skip: 3)
            
        case 3:
            guard (startIndex + 3) < data.count else {
                return nil
            }
            let size = (Int(data[startIndex + 1]) << 16) | (Int(data[startIndex + 2]) << 8) | Int(data[startIndex + 3])
            return (itemType: itemType, size: size, skip: 4)
            
        default:
            return nil
        }
    }
    
}
