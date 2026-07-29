//
//  SECS2BodyDecoder.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/03/08.
//

import Foundation

public protocol SECS2BodyDecodable {
    
    @discardableResult
    func decode(_ data: Data) -> (any SECS2Body)?
    
}

public extension SECS2BodyDecodable {
    
    @discardableResult
    func decode(_ data: Data) -> (any SECS2Body)? {
        if data.isEmpty {
            return nil
        } else {
            if let r = self.decode(data: data, startIndex: 0) {
                if r.endIndex == data.endIndex {
                    return r.secs2Body
                } else {
                    return SECS2ErrorBody(data: data)
                }
            } else {
                return SECS2ErrorBody(data: data)
            }
        }
    }
    
    private func decode(data: Data, startIndex: Data.Index) -> (secs2Body: any SECS2Body, endIndex: Data.Index)? {
        
        guard let r = self.decodeItemTypeAndSize(data: data, startIndex: startIndex) else {
            return nil
        }
        
        if r.itemType == .list {
            
            var values: [any SECS2BaseBody] = []
            var endIndex = startIndex + r.skip
            for _ in 0..<r.size {
                guard let rr = self.decode(data: data, startIndex: endIndex) else {
                    return nil
                }
                values.append(rr.secs2Body as! (any SECS2BaseBody))
                endIndex = rr.endIndex
            }
            let dataData = data.subdata(in: startIndex..<endIndex)
            
            return (secs2Body: SECS2ListBody(values: values, data: dataData), endIndex: endIndex)
            
        } else {
            
            let endIndex = startIndex + r.skip + r.size
            guard endIndex <= data.endIndex else {
                return nil
            }
            let dataData = data.subdata(in: startIndex..<endIndex)
            let valueData = data.subdata(in: (startIndex + r.skip)..<endIndex)
            
            switch r.itemType {
            case .binary:
                return (secs2Body: SECS2BinaryBody(values: valueData, data: dataData), endIndex: endIndex)
                
            case .boolean:
                let values = valueData.map { $0 != 0x00 }
                return (secs2Body: SECS2BooleanBody(values: values, data: dataData), endIndex: endIndex)
                
            case .ascii:
                guard let asciiString = String(data: valueData, encoding: .ascii) else {
                    return nil
                }
                return (secs2Body: SECS2AsciiBody(values: asciiString, data: dataData), endIndex: endIndex)
                
            case .jis8:
                return (secs2Body: SECS2JIS8Body(values: valueData, data: dataData), endIndex: endIndex)
                
            case .character2bytes:
                return (secs2Body: SECS2Character2BytesBody(values: valueData, data: dataData), endIndex: endIndex)
                
            case .int1:
                let values = valueData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [Int8] in
                    return Array(ptr.bindMemory(to: Int8.self))
                }
                return (secs2Body: SECS2Int1Body(values: values, data: dataData), endIndex: endIndex)
                
            case .int2:
                guard valueData.count % MemoryLayout<Int16>.size == 0 else {
                    return nil
                }
                let values = valueData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [Int16] in
                    return ptr.bindMemory(to: Int16.self).map { $0.bigEndian }
                }
                return (secs2Body: SECS2Int2Body(values: values, data: dataData), endIndex: endIndex)
                
            case .int4:
                guard valueData.count % MemoryLayout<Int32>.size == 0 else {
                    return nil
                }
                let values = valueData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [Int32] in
                    return ptr.bindMemory(to: Int32.self).map { $0.bigEndian }
                }
                return (secs2Body: SECS2Int4Body(values: values, data: dataData), endIndex: endIndex)
                
            case .int8:
                guard valueData.count % MemoryLayout<Int64>.size == 0 else {
                    return nil
                }
                let values = valueData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [Int64] in
                    return ptr.bindMemory(to: Int64.self).map { $0.bigEndian }
                }
                return (secs2Body: SECS2Int8Body(values: values, data: dataData), endIndex: endIndex)
                
            case .uint1:
                let values = [UInt8](valueData)
                return (secs2Body: SECS2UInt1Body(values: values, data: dataData), endIndex: endIndex)
                
            case .uint2:
                guard valueData.count % MemoryLayout<UInt16>.size == 0 else {
                    return nil
                }
                let values = valueData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [UInt16] in
                    return ptr.bindMemory(to: UInt16.self).map { $0.bigEndian }
                }
                return (secs2Body: SECS2UInt2Body(values: values, data: dataData), endIndex: endIndex)
                
            case .uint4:
                guard valueData.count % MemoryLayout<UInt32>.size == 0 else {
                    return nil
                }
                let values = valueData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [UInt32] in
                    return ptr.bindMemory(to: UInt32.self).map { $0.bigEndian }
                }
                return (secs2Body: SECS2UInt4Body(values: values, data: dataData), endIndex: endIndex)
                
            case .uint8:
                guard valueData.count % MemoryLayout<UInt64>.size == 0 else {
                    return nil
                }
                let values = valueData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [UInt64] in
                    return ptr.bindMemory(to: UInt64.self).map { $0.bigEndian }
                }
                return (secs2Body: SECS2UInt8Body(values: values, data: dataData), endIndex: endIndex)
                
            case .float4:
                guard valueData.count % MemoryLayout<UInt32>.size == 0 else {
                    return nil
                }
                let values = valueData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [Float] in
                    return ptr.bindMemory(to: UInt32.self).map { $0.bigEndian }.map { Float(bitPattern: $0.littleEndian) }
                }
                return (secs2Body: SECS2Float4Body(values: values, data: dataData), endIndex: endIndex)
                
            case .float8:
                guard valueData.count % MemoryLayout<UInt64>.size == 0 else {
                    return nil
                }
                let values = valueData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [Double] in
                    return ptr.bindMemory(to: UInt64.self).map { $0.bigEndian }.map { Double(bitPattern: $0.littleEndian) }
                }
                return (secs2Body: SECS2Float8Body(values: values, data: dataData), endIndex: endIndex)
                
            case .unknown:
                return (secs2Body: SECS2UnknownBody(values: valueData, data: dataData), endIndex: endIndex)
                
            default:
                return nil
            }
        }
    }
    
    private func decodeItemTypeAndSize(data: Data, startIndex: Data.Index) -> (itemType: SECS2BodyItemType, size: Int, skip: Int)? {
        
        guard startIndex < data.endIndex else {
            return nil
        }
        
        let itemType = SECS2BodyItemType(itemTypeByte: data[startIndex])
        let lengthByte = data[startIndex] & 0x03
        
        guard (startIndex + Int(lengthByte)) < data.endIndex else {
            return nil
        }
        
        switch lengthByte {
        case 1:
            let size = Int(data[startIndex + 1])
            return (itemType: itemType, size: size, skip: 2)
        case 2:
            let size = (Int(data[startIndex + 1]) << 8) | Int(data[startIndex + 2])
            return (itemType: itemType, size: size, skip: 3)
        case 3:
            let size = (Int(data[startIndex + 1]) << 16) | (Int(data[startIndex + 2]) << 8) | Int(data[startIndex + 3])
            return (itemType: itemType, size: size, skip: 4)
        default:
            return nil
        }
    }
}

public final class SECS2BodyDecoder: SECS2BodyDecodable, Sendable {
    
    public static let shared = SECS2BodyDecoder()
    
    private init() {
        // Nothing
    }
    
}
