//
//  SECS2BodyEncoder.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/03/07.
//

import Foundation

internal final class SECS2BodyEncoder: Sendable {
    
    internal static let shared = SECS2BodyEncoder()
    
    private init() {
        // Nothing
    }
    
    private static func createHeadData(itemType: SECS2BodyItemType, count: Int) -> Data {
        if count > 0xFFFF {
            return Data([
                UInt8(itemType.itemTypeByte | 0x03),
                UInt8((count >> 16) & 0xFF),
                UInt8((count >> 8) & 0xFF),
                UInt8(count & 0xFF),
            ])
        } else if count > 0xFF {
            return Data([
                UInt8(itemType.itemTypeByte | 0x02),
                UInt8((count >> 8) & 0xFF),
                UInt8(count & 0xFF),
            ])
        } else {
            return Data([
                UInt8(itemType.itemTypeByte | 0x01),
                UInt8(count & 0xFF),
            ])
        }
    }
    
    internal func encode(list: [any SECS2BaseBody]) -> Data {
        var data = Self.createHeadData(itemType: .list, count: list.count)
        for value in list {
            data.append(value.data)
        }
        return data
    }
    
    internal func encode(binary: Data) -> Data {
        var data = Self.createHeadData(itemType: .binary, count: binary.count)
        data.append(binary)
        return data
    }
    
    internal func encode(boolean: [Bool]) -> Data {
        let data = Data(boolean.map { UInt8($0 ? 0xFF : 0x00) })
        return Self.createHeadData(itemType: .boolean, count: data.count) + data
    }
    
    internal func encode(ascii: String) -> Data {
        guard let data = ascii.data(using: .ascii) else {
            fatalError("ASCII encode error: \"\(ascii)\"")
        }
        guard data.count <= 0x00FFFFFF else {
            fatalError("Item size error. size:\(data.count)")
        }
        return Self.createHeadData(itemType: .ascii, count: data.count) + data
    }
    
    internal func encode(int1: [Int8]) -> Data {
        let data = int1.withUnsafeBufferPointer { Data(buffer: $0) }
        return Self.createHeadData(itemType: .int1, count: data.count) + data
    }
    
    internal func encode(int2: [Int16]) -> Data {
        let data = int2.map { $0.bigEndian }.withUnsafeBufferPointer { Data(buffer: $0) }
        return Self.createHeadData(itemType: .int2, count: data.count) + data
    }
    
    internal func encode(int4: [Int32]) -> Data {
        let data = int4.map { $0.bigEndian }.withUnsafeBufferPointer { Data(buffer: $0) }
        return Self.createHeadData(itemType: .int4, count: data.count) + data
    }
    
    internal func encode(int8: [Int64]) -> Data {
        let data = int8.map { $0.bigEndian }.withUnsafeBufferPointer { Data(buffer: $0) }
        return Self.createHeadData(itemType: .int8, count: data.count) + data
    }
    
    internal func encode(uint1: [UInt8]) -> Data {
        let data = uint1.withUnsafeBufferPointer { Data(buffer: $0) }
        return Self.createHeadData(itemType: .uint1, count: data.count) + data
    }
    
    internal func encode(uint2: [UInt16]) -> Data {
        let data = uint2.map { $0.bigEndian }.withUnsafeBufferPointer { Data(buffer: $0) }
        return Self.createHeadData(itemType: .uint2, count: data.count) + data
    }
    
    internal func encode(uint4: [UInt32]) -> Data {
        let data = uint4.map { $0.bigEndian }.withUnsafeBufferPointer { Data(buffer: $0) }
        return Self.createHeadData(itemType: .uint4, count: data.count) + data
    }
    
    internal func encode(uint8: [UInt64]) -> Data {
        let data = uint8.map { $0.bigEndian }.withUnsafeBufferPointer { Data(buffer: $0) }
        return Self.createHeadData(itemType: .uint8, count: data.count) + data
    }
    
    internal func encode(float4: [Float]) -> Data {
        let data = float4.map { $0.bitPattern.bigEndian }.withUnsafeBufferPointer { Data(buffer: $0) }
        return Self.createHeadData(itemType: .float4, count: data.count) + data
    }
    
    internal func encode(float8: [Double]) -> Data {
        let data = float8.map { $0.bitPattern.bigEndian }.withUnsafeBufferPointer { Data(buffer: $0) }
        return Self.createHeadData(itemType: .float8, count: data.count) + data
    }
    
}
