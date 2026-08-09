//
//  SECS2Body.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Foundation

public struct SECS2Body: SECS2BodyProvider {
    
    internal nonisolated(unsafe) let inner: SECS2BodyInnerBase
    
    public var count: Int {
        get {
            return self.inner.count
        }
    }
    
    public var type: SECS2BodyItemType {
        get {
            return self.inner.type
        }
    }
    
    public var data: Data {
        get {
            return self.inner.data
        }
    }
    
    public var smlString: String {
        get {
            return self.inner.smlString(indent: "")
        }
    }
    
    public subscript(index: Int) -> (any SECS2BodyProvider)? {
        return self.inner.secs2BodyValue(at: index)
    }
    
    public func makeIterator() -> IndexingIterator<[any SECS2BodyProvider]> {
        return self.inner.makeIterator()
    }
    
    // MARK: getter
    
    public var value: Any? {
        return self.inner.value
    }
    
    @discardableResult
    public func secs2BodyValue(at: Int, _ indices: Int...) -> (any SECS2BodyProvider)? {
        let array = [at] + indices
        return self.deepSecs2BodyValue(indices: array)
    }
    
    @discardableResult
    public func boolValue(at: Int, _ indices: Int...) -> Bool? {
        var array = [at] + indices
        let last = array.removeLast()
        guard let provider = self.deepSecs2BodyValue(indices: array) else {
            return nil
        }
        if let body = provider as? SECS2Body {
            return body.inner.boolValue(at: last)
        } else {
            return provider.boolValue(at: last)
        }
    }
    
    @discardableResult
    public func stringValue(at: Int...) -> String? {
        guard let provider = self.deepSecs2BodyValue(indices: at) else {
            return nil
        }
        if let body = provider as? SECS2Body {
            return body.inner.stringValue()
        } else {
            return provider.stringValue()
        }
    }
    
    @discardableResult
    public func int8Value(at: Int, _ indices: Int...) -> Int8? {
        var array = [at] + indices
        let last = array.removeLast()
        guard let provider = self.deepSecs2BodyValue(indices: array) else {
            return nil
        }
        if let body = provider as? SECS2Body {
            return body.inner.int8Value(at: last)
        } else {
            return provider.int8Value(at: last)
        }
    }
    
    @discardableResult
    public func int16Value(at: Int, _ indices: Int...) -> Int16? {
        var array = [at] + indices
        let last = array.removeLast()
        guard let provider = self.deepSecs2BodyValue(indices: array) else {
            return nil
        }
        if let body = provider as? SECS2Body {
            return body.inner.int16Value(at: last)
        } else {
            return provider.int16Value(at: last)
        }
    }
    
    @discardableResult
    public func int32Value(at: Int, _ indices: Int...) -> Int32? {
        var array = [at] + indices
        let last = array.removeLast()
        guard let provider = self.deepSecs2BodyValue(indices: array) else {
            return nil
        }
        if let body = provider as? SECS2Body {
            return body.inner.int32Value(at: last)
        } else {
            return provider.int32Value(at: last)
        }
    }
    
    @discardableResult
    public func int64Value(at: Int, _ indices: Int...) -> Int64? {
        var array = [at] + indices
        let last = array.removeLast()
        guard let provider = self.deepSecs2BodyValue(indices: array) else {
            return nil
        }
        if let body = provider as? SECS2Body {
            return body.inner.int64Value(at: last)
        } else {
            return provider.int64Value(at: last)
        }
    }
    
    @discardableResult
    public func uint8Value(at: Int, _ indices: Int...) -> UInt8? {
        var array = [at] + indices
        let last = array.removeLast()
        guard let provider = self.deepSecs2BodyValue(indices: array) else {
            return nil
        }
        if let body = provider as? SECS2Body {
            return body.inner.uint8Value(at: last)
        } else {
            return provider.uint8Value(at: last)
        }
    }
    
    @discardableResult
    public func uint16Value(at: Int, _ indices: Int...) -> UInt16? {
        var array = [at] + indices
        let last = array.removeLast()
        guard let provider = self.deepSecs2BodyValue(indices: array) else {
            return nil
        }
        if let body = provider as? SECS2Body {
            return body.inner.uint16Value(at: last)
        } else {
            return provider.uint16Value(at: last)
        }
    }
    
    @discardableResult
    public func uint32Value(at: Int, _ indices: Int...) -> UInt32? {
        var array = [at] + indices
        let last = array.removeLast()
        guard let provider = self.deepSecs2BodyValue(indices: array) else {
            return nil
        }
        if let body = provider as? SECS2Body {
            return body.inner.uint32Value(at: last)
        } else {
            return provider.uint32Value(at: last)
        }
    }
    
    @discardableResult
    public func uint64Value(at: Int, _ indices: Int...) -> UInt64? {
        var array = [at] + indices
        let last = array.removeLast()
        guard let provider = self.deepSecs2BodyValue(indices: array) else {
            return nil
        }
        if let body = provider as? SECS2Body {
            return body.inner.uint64Value(at: last)
        } else {
            return provider.uint64Value(at: last)
        }
    }
    
    @discardableResult
    public func floatValue(at: Int, _ indices: Int...) -> Float? {
        var array = [at] + indices
        let last = array.removeLast()
        guard let provider = self.deepSecs2BodyValue(indices: array) else {
            return nil
        }
        if let body = provider as? SECS2Body {
            return body.inner.floatValue(at: last)
        } else {
            return provider.floatValue(at: last)
        }
    }
    
    @discardableResult
    public func doubleValue(at: Int, _ indices: Int...) -> Double? {
        var array = [at] + indices
        let last = array.removeLast()
        guard let provider = self.deepSecs2BodyValue(indices: array) else {
            return nil
        }
        if let body = provider as? SECS2Body {
            return body.inner.doubleValue(at: last)
        } else {
            return provider.doubleValue(at: last)
        }
    }
    
    @discardableResult
    public func anyValue(at: Int...) -> Any? {
        return self.deepAnyValue(indices: at)
    }
    
    private func deepAnyValue(indices: [Int]) -> Any? {
        if indices.isEmpty {
            return self.inner.anyValue(indices: indices)
        }
        if case .list = self.type {
            var array = indices
            let first = array.removeFirst()
            guard let provider = self.inner.secs2BodyValue(at: first) else {
                return nil
            }
            if let body = provider as? SECS2Body {
                return body.deepAnyValue(indices: array)
            } else {
                if array.count == 0 {
                    return provider.anyValue()
                } else if array.count == 1 {
                    return provider.anyValue(at: array[0])
                }
            }
        } else {
            return self.inner.anyValue(indices: indices)
        }
        
        return nil
    }
    
    private func deepSecs2BodyValue(indices: [Int]) -> (any SECS2BodyProvider)? {
        if indices.isEmpty {
            return self
        }
        var array = indices
        let first = array.removeFirst()
        guard let provider = self.inner.secs2BodyValue(at: first) else {
            return nil
        }
        guard let body = provider as? SECS2Body else {
            return nil
        }
        
        return body.deepSecs2BodyValue(indices: array)
    }
    
    // MARK: init
    
    /// Initializes a new SECS-II List Body instance
    ///
    /// - Parameters:
    ///   - list: The  SECS-II Body Array
    public init(list: [any SECS2BodyProvider]) {
        self.init(list: list, data: SECS2BodyEncoder.shared.encode(list: list))
    }
    
    internal init(list: [any SECS2BodyProvider], data: Data) {
        self.inner = SECS2BodyInnerList(list: list, data: data)
    }
    
    /// Initializes a new SECS-II Binary Body instance
    ///
    /// - Parameters:
    ///   - binary: The Data
    public init(binary: Data) {
        self.init(binary: binary, data: SECS2BodyEncoder.shared.encode(binary: binary))
    }
    
    internal init(binary: Data, data: Data) {
        self.inner = SECS2BodyInnerBinary(binary: binary, data: data)
    }
    
    /// Initializes a new SECS-II Boolean Body instance
    ///
    /// - Parameters:
    ///   - boolean: The Bool Array
    public init(boolean: [Bool]) {
        self.init(boolean: boolean, data: SECS2BodyEncoder.shared.encode(boolean: boolean))
    }
    
    internal init(boolean: [Bool], data: Data) {
        self.inner = SECS2BodyInnerBoolean(boolean: boolean, data: data)
    }
    
    /// Initializes a new SECS-II Ascii Body instance
    ///
    /// - Parameters:
    ///   - ascii: The String
    public init(ascii: String) {
        self.init(ascii: ascii, data: SECS2BodyEncoder.shared.encode(ascii: ascii))
    }
    
    internal init(ascii: String, data: Data) {
        self.inner = SECS2BodyInnerAscii(ascii: ascii, data: data)
    }
    
    internal init(jis8: Data, data: Data) {
        self.inner = SECS2BodyInnerJis8(jis8: jis8, data: data)
    }
    
    internal init(character2Bytes: Data, data: Data) {
        self.inner = SECS2BodyInnerCharacter2Bytes(character2Bytes: character2Bytes, data: data)
    }
    
    /// Initializes a new SECS-II 1-byte Signed Integer Body instance
    ///
    /// - Parameters:
    ///   - int1: The Int8 Array
    public init(int1: [Int8]) {
        self.init(int1: int1, data: SECS2BodyEncoder.shared.encode(int1: int1))
    }
    
    internal init(int1: [Int8], data: Data) {
        self.inner = SECS2BodyInnerInt1(int1: int1, data: data)
    }
    
    /// Initializes a new SECS-II 2-byte Signed Integer Body instance
    ///
    /// - Parameters:
    ///   - int2: The Int16 Array
    public init(int2: [Int16]) {
        self.init(int2: int2, data: SECS2BodyEncoder.shared.encode(int2: int2))
    }
    
    internal init(int2: [Int16], data: Data) {
        self.inner = SECS2BodyInnerInt2(int2: int2, data: data)
    }
    
    /// Initializes a new SECS-II 4-byte Signed Integer Body instance
    ///
    /// - Parameters:
    ///   - int4: The Int32 Array
    public init(int4: [Int32]) {
        self.init(int4: int4, data: SECS2BodyEncoder.shared.encode(int4: int4))
    }
    
    internal init(int4: [Int32], data: Data) {
        self.inner = SECS2BodyInnerInt4(int4: int4, data: data)
    }
    
    /// Initializes a new SECS-II 8-byte Signed Integer Body instance
    ///
    /// - Parameters:
    ///   - int8: The Int64 Array
    public init(int8: [Int64]) {
        self.init(int8: int8, data: SECS2BodyEncoder.shared.encode(int8: int8))
    }
    
    internal init(int8: [Int64], data: Data) {
        self.inner = SECS2BodyInnerInt8(int8: int8, data: data)
    }
    
    /// Initializes a new SECS-II 1-byte Unsigned Integer Body instance
    ///
    /// - Parameters:
    ///   - uint1: The UInt8 Array
    public init(uint1: [UInt8]) {
        self.init(uint1: uint1, data: SECS2BodyEncoder.shared.encode(uint1: uint1))
    }
    
    internal init(uint1: [UInt8], data: Data) {
        self.inner = SECS2BodyInnerUInt1(uint1: uint1, data: data)
    }
    
    /// Initializes a new SECS-II 2-byte Unsigned Integer Body instance
    ///
    /// - Parameters:
    ///   - uint2: The UInt16 Array
    public init(uint2: [UInt16]) {
        self.init(uint2: uint2, data: SECS2BodyEncoder.shared.encode(uint2: uint2))
    }
    
    internal init(uint2: [UInt16], data: Data) {
        self.inner = SECS2BodyInnerUInt2(uint2: uint2, data: data)
    }
    
    /// Initializes a new SECS-II 4-byte Unsigned Integer Body instance
    ///
    /// - Parameters:
    ///   - uint4: The UInt32 Array
    public init(uint4: [UInt32]) {
        self.init(uint4: uint4, data: SECS2BodyEncoder.shared.encode(uint4: uint4))
    }
    
    internal init(uint4: [UInt32], data: Data) {
        self.inner = SECS2BodyInnerUInt4(uint4: uint4, data: data)
    }
    
    /// Initializes a new SECS-II 8-byte Unsigned Integer Body instance
    ///
    /// - Parameters:
    ///   - uint8: The UInt64 Array
    public init(uint8: [UInt64]) {
        self.init(uint8: uint8, data: SECS2BodyEncoder.shared.encode(uint8: uint8))
    }
    
    internal init(uint8: [UInt64], data: Data) {
        self.inner = SECS2BodyInnerUInt8(uint8: uint8, data: data)
    }
    
    /// Initializes a new SECS-II 4-byte Floating-Point Body instance
    ///
    /// - Parameters:
    ///   - float4: The Float Array
    public init(float4: [Float]) {
        self.init(float4: float4, data: SECS2BodyEncoder.shared.encode(float4: float4))
    }
    
    internal init(float4: [Float], data: Data) {
        self.inner = SECS2BodyInnerFloat4(float4: float4, data: data)
    }
    
    /// Initializes a new SECS-II 8-byte Floating-Point Body instance
    ///
    /// - Parameters:
    ///   - float8: The Double Array
    public init(float8: [Double]) {
        self.init(float8: float8, data: SECS2BodyEncoder.shared.encode(float8: float8))
    }
    
    internal init(float8: [Double], data: Data) {
        self.inner = SECS2BodyInnerFloat8(float8: float8, data: data)
    }
    
    internal init(unknown: Data, data: Data) {
        self.inner = SECS2BodyInnerUnknown(unknown: unknown, data: data)
    }
    
    internal init(error: Data) {
        self.inner = SECS2BodyInnerError(error: error)
    }
    
}
