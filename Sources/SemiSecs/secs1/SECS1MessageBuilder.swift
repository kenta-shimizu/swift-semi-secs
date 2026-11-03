//
//  SECS1MessageBuilder.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/10/23.
//

import Foundation
import Synchronization

/// SECS-I Message buildable
public protocol SECS1MessageBuildable: AnyObject {
    
    /// Build SECS-I-Message
    ///
    /// - Parameters:
    ///   - header10Bytes: the Header10Bytes
    ///   - secs2Body: the SECS2Body
    /// - Returns: SECS-I-Message
    func build(header10Bytes: Data, secs2Body: (any SECS2BodyProvider)?) -> SECS1Message
    
    /// Build primary-SECS-I-Message.
    ///
    /// - Parameters:
    ///   - stream: the stream number
    ///   - function: the function number
    ///   - wbit: the wbit
    ///   - secs2Body: SECS-II-Body
    /// - Returns: Primary SECS-I-Message
    func buildPrimaryData(stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2BodyProvider)?) -> SECS1Message
    
    /// Build primary-Data-SECS-I-Message.
    ///
    /// - Parameters:
    ///   - smlMessage: the SMLMessage
    /// - Returns: Primary SECS-I-Message
    func buildPrimaryData(smlMessage: SMLMessage) -> SECS1Message
    
    /// Build response-SECS-I-Message.
    ///
    /// - Parameters:
    ///   - primaryMessage: the  primary-SECSMessage
    ///   - stream: the stream number
    ///   - function: the function number
    ///   - wbit: the wbit
    ///   - secs2Body: SECS-II-Body
    /// - Returns: Response SECS-I-Message
    func buildResponseData(primaryMessage: any SECSMessage, stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2BodyProvider)?) -> SECS1Message
    
    /// Build response-SECS-I-Message.
    ///
    /// - Parameters:
    ///   - primaryMessage: the  primary-SECSMessage
    ///   - smlMessage: the SMLMessage
    /// - Returns: Response SECS-I-Message
    func buildResponseData(primaryMessage: any SECSMessage, smlMessage: SMLMessage) -> SECS1Message
    
}

public extension SECS1MessageBuildable {
    
    func buildPrimaryData(stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2BodyProvider)? = nil) -> SECS1Message {
        return self.buildPrimaryData(smlMessage: SMLMessage(stream: stream, function: function, wbit: wbit, secs2Body: secs2Body))
    }
    
    func buildResponseData(primaryMessage: any SECSMessage, stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2BodyProvider)? = nil) -> SECS1Message {
        return self.buildResponseData(primaryMessage: primaryMessage, smlMessage: SMLMessage(stream: stream, function: function, wbit: wbit, secs2Body: secs2Body))
    }
    
}

/// SECS-I Message Builder.
public final class SECS1MessageBuilder: SECS1MessageBuildable, Sendable {
    
    private let systemLower2BytesCounter = Atomic<UInt16>(0)
    
    public init() {
        // Nothing
    }
    
    private let _isEquipment = Mutex<(@Sendable () -> Bool)?>(nil)
    
    /// Is-Equipment getter
    public var isEquipment: (@Sendable () -> Bool)? {
        get { self._isEquipment.withLock { $0 } }
        set { self._isEquipment.withLock { $0 = newValue } }
    }
    
    private let _deviceId = Mutex<(@Sendable () -> UInt16)?>(nil)
    
    /// Device-ID getter
    public var deviceId: (@Sendable () -> UInt16)? {
        get { self._deviceId.withLock { $0 } }
        set { self._deviceId.withLock { $0 = newValue } }
    }
    
    public func build(header10Bytes: Data, secs2Body: (any SECS2BodyProvider)?) -> SECS1Message {
        
        guard let blocks = self.buildBlockArray(header10Bytes: header10Bytes, secs2Body: secs2Body) else {
            fatalError("SECS1Message.block number overflow")
        }
        
        return SECS1Message(secs2Body: secs2Body, blocks: blocks)
    }
    
    public func buildPrimaryData(smlMessage: SMLMessage) -> SECS1Message {
        
        let ids = self.deviceId!().toBytes()
        let isEquipment = self.isEquipment!()
        let systemLower2Bytes = self.systemLower2BytesCounter.incrementAndToBytes()

        let header10Bytes = Data([
            (ids[0] | (isEquipment ? 0x80 : 0x00)), // R-Bit
            ids[1],
            (smlMessage.stream | (smlMessage.wbit ? 0x80 : 0x00)),  // W-Bit
            smlMessage.function,
            0,
            0,
            (isEquipment ? ids[0] : 0),
            (isEquipment ? ids[1] : 0),
            systemLower2Bytes[0],
            systemLower2Bytes[1]
        ])
        
        return self.build(header10Bytes: header10Bytes, secs2Body: smlMessage.secs2Body)
    }
    
    public func buildResponseData(primaryMessage: any SECSMessage, smlMessage: SMLMessage) -> SECS1Message {
        
        let ids = self.deviceId!().toBytes()
        let isEquipment = self.isEquipment!()
        let ref = primaryMessage.header10Bytes
        
        let header10Bytes = Data([
            (ids[0] | (isEquipment ? 0x80 : 0x00)), // R-Bit
            ids[1],
            (smlMessage.stream | (smlMessage.wbit ? 0x80 : 0x00)),  // W-Bit
            smlMessage.function,
            0,
            0,
            ref[6],
            ref[7],
            ref[8],
            ref[9]
        ])
        
        return self.build(header10Bytes: header10Bytes, secs2Body: smlMessage.secs2Body)
    }
    
    private func buildBlockArray(header10Bytes: Data, secs2Body: (any SECS2BodyProvider)?) -> [SECS1Message.Block]? {
        
        func strideSECS2Body() -> [Data] {
            guard let secs2Body = secs2Body else {
                return [Data()]
            }
            let data = secs2Body.data
            let count = data.count
            let size = 244
            return stride(from: 0, to: count, by: size).map { startIndex in
                let endIndex = Swift.min(startIndex + size, count)
                return data.subdata(in: startIndex..<endIndex)
            }
        }
        
        let secs2BodyDatas = strideSECS2Body()
        let endBlockNumber = secs2BodyDatas.count
        guard endBlockNumber <= 0x7FFF else {
            return nil
        }
        
        return secs2BodyDatas.enumerated().map { (index, body) in
            let blockNumber: Int = index + 1
            let blockNumberBytes = UInt16(blockNumber).toBytes()
            
            let blockHeader10Bytes = Data([
                header10Bytes[0],
                header10Bytes[1],
                header10Bytes[2],
                header10Bytes[3],
                (blockNumberBytes[0] | (blockNumber == endBlockNumber ? 0x80 : 0x00)),  // E-Bit
                blockNumberBytes[1],
                header10Bytes[6],
                header10Bytes[7],
                header10Bytes[8],
                header10Bytes[9]
            ])
            
            let sum: UInt16 = (blockHeader10Bytes + body).reduce(0) { $0 &+ UInt16($1) }
            
            let blockData = Data([
                Data([UInt8(blockHeader10Bytes.count + body.count)]), // length-1-byte
                blockHeader10Bytes, // header-10-bytes
                body,
                Data(sum.toBytes()) // sum-check-2-byte
            ].joined())
            
            return SECS1Message.Block(data: blockData)!
        }
    }
    
}
