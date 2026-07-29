//
//  SECS2BodyBuilder.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/03/08.
//

import Foundation

public protocol SECS2BodyBuildable {
    
    @discardableResult
    func build(list: [any SECS2Body]) -> any SECS2Body
    
    @discardableResult
    func build(binary: Data) -> any SECS2Body
    
    @discardableResult
    func build(boolean: [Bool]) -> any SECS2Body
    
    @discardableResult
    func build(ascii: String) -> any SECS2Body
    
    @discardableResult
    func build(int1: [Int8]) -> any SECS2Body
    
    @discardableResult
    func build(int2: [Int16]) -> any SECS2Body
    
    @discardableResult
    func build(int4: [Int32]) -> any SECS2Body
    
    @discardableResult
    func build(int8: [Int64]) -> any SECS2Body
    
    @discardableResult
    func build(uint1: [UInt8]) -> any SECS2Body
    
    @discardableResult
    func build(uint2: [UInt16]) -> any SECS2Body
    
    @discardableResult
    func build(uint4: [UInt32]) -> any SECS2Body
    
    @discardableResult
    func build(uint8: [UInt64]) -> any SECS2Body
    
    @discardableResult
    func build(float4: [Float]) -> any SECS2Body
    
    @discardableResult
    func build(float8: [Double]) -> any SECS2Body

}

public extension SECS2BodyBuildable {
    
    @discardableResult
    func build(list: [any SECS2Body]) -> any SECS2Body {
        return SECS2ListBody(values: (list as! [any SECS2BaseBody]), data: nil)
    }
    
    @discardableResult
    func build(binary: Data) -> any SECS2Body {
        return SECS2BinaryBody(values: binary, data: SECS2BodyEncoder.shared.encode(binary: binary))
    }
    
    @discardableResult
    func build(boolean: [Bool]) -> any SECS2Body {
        return SECS2BooleanBody(values: boolean, data: SECS2BodyEncoder.shared.encode(boolean: boolean))
    }
    
    @discardableResult
    func build(ascii: String) -> any SECS2Body {
        return SECS2AsciiBody(values: ascii, data: SECS2BodyEncoder.shared.encode(ascii: ascii))
    }
    
    @discardableResult
    func build(int1: [Int8]) -> any SECS2Body {
        return SECS2Int1Body(values: int1, data: SECS2BodyEncoder.shared.encode(int1: int1))
    }
    
    
    @discardableResult
    func build(int2: [Int16]) -> any SECS2Body {
        return SECS2Int2Body(values: int2, data: SECS2BodyEncoder.shared.encode(int2: int2))
    }
    
    @discardableResult
    func build(int4: [Int32]) -> any SECS2Body {
        return SECS2Int4Body(values: int4, data: SECS2BodyEncoder.shared.encode(int4: int4))
    }
    
    @discardableResult
    func build(int8: [Int64]) -> any SECS2Body {
        return SECS2Int8Body(values: int8, data: SECS2BodyEncoder.shared.encode(int8: int8))
    }
    
    @discardableResult
    func build(uint1: [UInt8]) -> any SECS2Body {
        return SECS2UInt1Body(values: uint1, data: SECS2BodyEncoder.shared.encode(uint1: uint1))
    }
    
    @discardableResult
    func build(uint2: [UInt16]) -> any SECS2Body {
        return SECS2UInt2Body(values: uint2, data: SECS2BodyEncoder.shared.encode(uint2: uint2))
    }
    
    @discardableResult
    func build(uint4: [UInt32]) -> any SECS2Body {
        return SECS2UInt4Body(values: uint4, data: SECS2BodyEncoder.shared.encode(uint4: uint4))
    }
    
    @discardableResult
    func build(uint8: [UInt64]) -> any SECS2Body {
        return SECS2UInt8Body(values: uint8, data: SECS2BodyEncoder.shared.encode(uint8: uint8))
    }
    
    @discardableResult
    func build(float4: [Float]) -> any SECS2Body {
        return SECS2Float4Body(values: float4, data: SECS2BodyEncoder.shared.encode(float4: float4))
    }
    
    @discardableResult
    func build(float8: [Double]) -> any SECS2Body {
        return SECS2Float8Body(values: float8, data: SECS2BodyEncoder.shared.encode(float8: float8))
    }
    
}

public final class SECS2BodyBuilder: SECS2BodyBuildable, Sendable {
    
    public static let shared = SECS2BodyBuilder()
    
    private init() {
        // Nothing
    }
    
}
