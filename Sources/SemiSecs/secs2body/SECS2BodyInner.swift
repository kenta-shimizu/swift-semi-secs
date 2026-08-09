//
//  SECS2BodyInner.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/08/03.
//

import Foundation

internal class SECS2BodyInnerBase: Sequence {
    
    private static let emptyValues: [any SECS2BodyProvider] = []
    
    private let _data: Data
    internal let _secs2BodyItemType: SECS2BodyItemType
    
    internal init(data: Data, secs2BodyItemType: SECS2BodyItemType) {
        self._data = data
        self._secs2BodyItemType = secs2BodyItemType
    }
    
    internal var data: Data {
        get {
            return self._data
        }
    }
    
    /// SECS-II Item Type
    internal var type: SECS2BodyItemType {
        get {
            return self._secs2BodyItemType
        }
    }
    
    /// Count Item size
    internal var count: Int {
        get {
            fatalError("SECSBodyInnerBase count")
        }
    }
    
    internal func smlString(indent: String = "") -> String {
        let type = self._secs2BodyItemType.smlString
        let size = self.count
        let value = self.smlValueString()
        return "\(indent)<\(type) [\(size)] \(value)>"
    }
    
    internal func smlValueString() -> String {
        fatalError("SECSBodyInnerBase smlValueString")
    }
    
    /// value
    internal var value: Any? {
        get {
            fatalError("SECSBodyInnerBase value")
        }
    }
    
    internal func makeIterator() -> IndexingIterator<[any SECS2BodyProvider]> {
        return Self.emptyValues.makeIterator()
    }
    
    internal func secs2BodyValue(at: Int) -> (any SECS2BodyProvider)? {
        return nil
    }
    
    internal func boolValue(at: Int) -> Bool? {
        return nil
    }
    
    internal func stringValue() -> String? {
        return nil
    }
    
    internal func int8Value(at: Int) -> Int8? {
        return nil
    }
    
    internal func int16Value(at: Int) -> Int16? {
        return nil
    }
    
    internal func int32Value(at: Int) -> Int32? {
        return nil
    }
    
    internal func int64Value(at: Int) -> Int64? {
        return nil
    }
    
    internal func uint8Value(at: Int) -> UInt8? {
        return nil
    }
    
    internal func uint16Value(at: Int) -> UInt16? {
        return nil
    }
    
    internal func uint32Value(at: Int) -> UInt32? {
        return nil
    }
    
    internal func uint64Value(at: Int) -> UInt64? {
        return nil
    }
    
    internal func floatValue(at: Int) -> Float? {
        return nil
    }
    
    internal func doubleValue(at: Int) -> Double? {
        return nil
    }
    
    internal func anyValue(indices: [Int]) -> Any? {
        return nil
    }
    
}

internal class SECS2BodyInnerArrayBase<T: CustomStringConvertible>: SECS2BodyInnerBase{
    
    internal let _values: [T]
    
    internal init(values: [T], data: Data, secs2BodyItemType: SECS2BodyItemType) {
        self._values = values
        super.init(data: data, secs2BodyItemType: secs2BodyItemType)
    }
    
    internal override var count: Int {
        get {
            return self._values.count
        }
    }
    
    internal override func smlValueString() -> String {
        return self._values.map { $0.description + " " }.joined()
    }
    
    internal override var value: Any? {
        get {
            return self._values
        }
    }
    
    internal override func anyValue(indices: [Int]) -> Any? {
        if indices.count == 0 {
            return self._values
        }
        if indices.count == 1 {
            let index = indices[0]
            if self._values.indices.contains(index) {
                return self._values[index]
            }
        }
        
        return nil
    }
    
}

internal class SECS2BodyInnerDataBase: SECS2BodyInnerBase{
    
    internal let _values: Data
    
    internal init(values: Data, data: Data, secs2BodyItemType: SECS2BodyItemType) {
        self._values = values
        super.init(data: data, secs2BodyItemType: secs2BodyItemType)
    }
    
    internal override var count: Int {
        get {
            return self._values.count
        }
    }
    
    internal override var value: Any? {
        get {
            return self._values
        }
    }

}

internal final class SECS2BodyInnerList: SECS2BodyInnerBase {
    
    private static let lineSeparator = "\n"
    private static let indent = "  "
    
    private let _values: [any SECS2BodyProvider]
    
    internal init(list: [any SECS2BodyProvider], data: Data) {
        self._values = list
        super.init(data: data, secs2BodyItemType: .list)
    }
    
    internal override var count: Int {
        get {
            return self._values.count
        }
    }
    
    internal override func smlString(indent: String = "") -> String {
        let type = self._secs2BodyItemType.smlString
        let size = self.count
        var sml = indent
        sml.append("<\(type) [\(size)]")
        sml.append(Self.lineSeparator)
        for provider in self._values {
            if let body = provider as? SECS2Body {
                sml.append(body.inner.smlString(indent: indent + Self.indent))
            } else {
                sml.append(indent)
                sml.append(Self.indent)
                sml.append(provider.smlString)
            }
            sml.append(Self.lineSeparator)
        }
        sml.append(indent)
        sml.append(">")
        return sml
    }
    
    internal override var value: Any? {
        get {
            return self._values
        }
    }
    
    internal override func makeIterator() -> IndexingIterator<[any SECS2BodyProvider]> {
        return self._values.makeIterator()
    }
    
    internal override func secs2BodyValue(at: Int) -> (any SECS2BodyProvider)? {
        guard self._values.indices.contains(at) else {
            return nil
        }
        return self._values[at]
    }
    
    internal override func anyValue(indices: [Int]) -> Any? {
        if indices.count == 0 {
            return self._values
        }
        if indices.count == 1 {
            let index = indices[0]
            if self._values.indices.contains(index) {
                return self._values[index]
            }
        }
        
        return nil
    }
    
}

internal final class SECS2BodyInnerBinary: SECS2BodyInnerDataBase {
    
    internal init(binary: Data, data: Data) {
        super.init(values: binary, data: data, secs2BodyItemType: .binary)
    }
    
    internal override func smlValueString() -> String {
        return self._values.map { String(format: "0x%02X ", $0) }.joined()
    }
    
    internal override func uint8Value(at: Int) -> UInt8? {
        guard self._values.indices.contains(at) else {
            return nil
        }
        return self._values[at]
    }
    
    internal override func anyValue(indices: [Int]) -> Any? {
        if indices.count == 0 {
            return self._values
        }
        if indices.count == 1 {
            let index = indices[0]
            if self._values.indices.contains(index) {
                return self._values[index]
            }
        }
        
        return nil
    }
    
}

internal final class SECS2BodyInnerBoolean: SECS2BodyInnerArrayBase<Bool> {
    
    internal init(boolean: [Bool], data: Data) {
        super.init(values: boolean, data: data, secs2BodyItemType: .boolean)
    }
    
    internal override func smlValueString() -> String {
        return self._values.map { $0 ? "TRUE " : "FALSE " }.joined()
    }
    
    internal override func boolValue(at: Int) -> Bool? {
        guard self._values.indices.contains(at) else {
            return nil
        }
        return self._values[at]
    }
    
}

internal final class SECS2BodyInnerAscii: SECS2BodyInnerBase {
    
    private let _values: String
    
    internal init(ascii: String, data: Data) {
        self._values = ascii
        super.init(data: data, secs2BodyItemType: .ascii)
    }
    
    internal override var count: Int {
        get {
            return self._values.count
        }
    }
    
    internal override var value: Any? {
        get {
            return self._values
        }
    }
    
    internal override func smlValueString() -> String {
        return "\"\(self._values)\" "
    }
    
    internal override func stringValue() -> String? {
        return self._values
    }
    
    internal override func anyValue(indices: [Int]) -> Any? {
        if indices.count == 0 {
            return self._values
        }
        if indices.count == 1 {
            let chars = Array(self._values)
            let index = indices[0]
            if chars.indices.contains(index) {
                return chars[index]
            }
        }
        
        return nil
    }
    
}

internal final class SECS2BodyInnerJis8: SECS2BodyInnerDataBase {
    
    internal init(jis8: Data, data: Data) {
        super.init(values: jis8, data: data, secs2BodyItemType: .jis8)
    }
    
    internal override func smlString(indent: String = "") -> String {
        let type = self._secs2BodyItemType.smlString
        return "\(indent)<\(type) [?] >"
    }
    
}

internal final class SECS2BodyInnerCharacter2Bytes: SECS2BodyInnerDataBase {
    
    internal init(character2Bytes: Data, data: Data) {
        super.init(values: character2Bytes, data: data, secs2BodyItemType: .character2Bytes)
    }
    
    internal override func smlString(indent: String = "") -> String {
        let type = self._secs2BodyItemType.smlString
        return "\(indent)<\(type) [?] >"
    }
    
}

internal final class SECS2BodyInnerInt1: SECS2BodyInnerArrayBase<Int8> {
    
    internal init(int1: [Int8], data: Data) {
        super.init(values: int1, data: data, secs2BodyItemType: .int1)
    }
    
    internal override func int8Value(at: Int) -> Int8? {
        guard self._values.indices.contains(at) else {
            return nil
        }
        return self._values[at]
    }
}

internal final class SECS2BodyInnerInt2: SECS2BodyInnerArrayBase<Int16> {
    
    internal init(int2: [Int16], data: Data) {
        super.init(values: int2, data: data, secs2BodyItemType: .int2)
    }
    
    internal override func int16Value(at: Int) -> Int16? {
        guard self._values.indices.contains(at) else {
            return nil
        }
        return self._values[at]
    }
}

internal final class SECS2BodyInnerInt4: SECS2BodyInnerArrayBase<Int32> {
    
    internal init(int4: [Int32], data: Data) {
        super.init(values: int4, data: data, secs2BodyItemType: .int4)
    }
    
    internal override func int32Value(at: Int) -> Int32? {
        guard self._values.indices.contains(at) else {
            return nil
        }
        return self._values[at]
    }
}

internal final class SECS2BodyInnerInt8: SECS2BodyInnerArrayBase<Int64> {
    
    internal init(int8: [Int64], data: Data) {
        super.init(values: int8, data: data, secs2BodyItemType: .int8)
    }
    
    internal override func int64Value(at: Int) -> Int64? {
        guard self._values.indices.contains(at) else {
            return nil
        }
        return self._values[at]
    }
}

internal final class SECS2BodyInnerUInt1: SECS2BodyInnerArrayBase<UInt8> {
    
    internal init(uint1: [UInt8], data: Data) {
        super.init(values: uint1, data: data, secs2BodyItemType: .uint1)
    }
    
    internal override func uint8Value(at: Int) -> UInt8? {
        guard self._values.indices.contains(at) else {
            return nil
        }
        return self._values[at]
    }
}

internal final class SECS2BodyInnerUInt2: SECS2BodyInnerArrayBase<UInt16> {
    
    internal init(uint2: [UInt16], data: Data) {
        super.init(values: uint2, data: data, secs2BodyItemType: .uint2)
    }
    
    internal override func uint16Value(at: Int) -> UInt16? {
        guard self._values.indices.contains(at) else {
            return nil
        }
        return self._values[at]
    }
}

internal final class SECS2BodyInnerUInt4: SECS2BodyInnerArrayBase<UInt32> {
    
    internal init(uint4: [UInt32], data: Data) {
        super.init(values: uint4, data: data, secs2BodyItemType: .uint4)
    }
    
    internal override func uint32Value(at: Int) -> UInt32? {
        guard self._values.indices.contains(at) else {
            return nil
        }
        return self._values[at]
    }
}

internal final class SECS2BodyInnerUInt8: SECS2BodyInnerArrayBase<UInt64> {
    
    internal init(uint8: [UInt64], data: Data) {
        super.init(values: uint8, data: data, secs2BodyItemType: .uint8)
    }
    
    internal override func uint64Value(at: Int) -> UInt64? {
        guard self._values.indices.contains(at) else {
            return nil
        }
        return self._values[at]
    }
}

internal final class SECS2BodyInnerFloat4: SECS2BodyInnerArrayBase<Float> {
    
    internal init(float4: [Float], data: Data) {
        super.init(values: float4, data: data, secs2BodyItemType: .float4)
    }
    
    internal override func floatValue(at: Int) -> Float? {
        guard self._values.indices.contains(at) else {
            return nil
        }
        return self._values[at]
    }
}

internal final class SECS2BodyInnerFloat8: SECS2BodyInnerArrayBase<Double> {
    
    internal init(float8: [Double], data: Data) {
        super.init(values: float8, data: data, secs2BodyItemType: .float8)
    }
    
    internal override func doubleValue(at: Int) -> Double? {
        guard self._values.indices.contains(at) else {
            return nil
        }
        return self._values[at]
    }
}

internal final class SECS2BodyInnerUnknown: SECS2BodyInnerDataBase {
    
    internal init(unknown: Data, data: Data) {
        super.init(values: unknown, data: data, secs2BodyItemType: .unknown)
    }
    
    internal override func smlString(indent: String = "") -> String {
        let type = self._secs2BodyItemType.smlString
        return "\(indent)<\(type) [?] >"
    }
}

internal final class SECS2BodyInnerError: SECS2BodyInnerBase {
    
    internal init(error: Data) {
        super.init(data: error, secs2BodyItemType: .error)
    }
    
    internal override func smlString(indent: String = "") -> String {
        let type = self._secs2BodyItemType.smlString
        return "\(indent)<\(type) [?] >"
    }
}
