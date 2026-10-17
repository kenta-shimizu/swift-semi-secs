//
//  HSMSMessageBuilder.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/02/28.
//

import Foundation
import Synchronization

/// HSMS-SS Message Builder.
public final class HSMSSSMessageBuilder: HSMSMessageBuildable, Sendable {
    
    private let systemLower2BytesCounter = Atomic<UInt16>(0)
    
    public init() {
        // Nothing
    }
    
    private let _isEquipment = Mutex<(@Sendable () -> Bool)?>(nil)
    
    public var isEquipment: (@Sendable () -> Bool)? {
        get { self._isEquipment.withLock { $0 } }
        set { self._isEquipment.withLock { $0 = newValue } }
    }
    
    public func buildPrimaryData(sessionId: UInt16, smlMessage: SMLMessage) -> HSMSMessage {
        let ids = sessionId.toBytes()
        let isEquipment = self.isEquipment!()
        let systemLower2Bytes = self.systemLower2BytesCounter.incrementAndToBytes()
        let header10Bytes = Data([
            ids[0],
            ids[1],
            (smlMessage.stream | (smlMessage.wbit ? 0x80 : 0x00)),
            smlMessage.function,
            HSMSMessage.MessageType.data.pType,
            HSMSMessage.MessageType.data.sType,
            (isEquipment ? ids[0] : 0),
            (isEquipment ? ids[1] : 0),
            systemLower2Bytes[0],
            systemLower2Bytes[1]
        ])
        return self.build(header10Bytes: header10Bytes, secs2Body: smlMessage.secs2Body)
    }
    
    public func buildSelectRequest(sessionId: UInt16) -> HSMSMessage {
        let ids = sessionId.toBytes()
        let isEquipment = self.isEquipment!()
        let systemLower2Bytes = self.systemLower2BytesCounter.incrementAndToBytes()
        let header10Bytes = Data([
            0xFF,
            0xFF,
            0x00,
            0x00,
            HSMSMessage.MessageType.selectRequest.pType,
            HSMSMessage.MessageType.selectRequest.sType,
            (isEquipment ? ids[0] : 0),
            (isEquipment ? ids[1] : 0),
            systemLower2Bytes[0],
            systemLower2Bytes[1]
        ])
        return self.build(header10Bytes: header10Bytes)
    }
    
    public func buildDeselectRequest(sessionId: UInt16) -> HSMSMessage {
        let ids = sessionId.toBytes()
        let isEquipment = self.isEquipment!()
        let systemLower2Bytes = self.systemLower2BytesCounter.incrementAndToBytes()
        let header10Bytes = Data([
            0xFF,
            0xFF,
            0x00,
            0x00,
            HSMSMessage.MessageType.deselectRequest.pType,
            HSMSMessage.MessageType.deselectRequest.sType,
            (isEquipment ? ids[0] : 0),
            (isEquipment ? ids[1] : 0),
            systemLower2Bytes[0],
            systemLower2Bytes[1]
        ])
        return self.build(header10Bytes: header10Bytes)
    }
    
    public func buildLinktestRequest(sessionId: UInt16) -> HSMSMessage {
        let ids = sessionId.toBytes()
        let isEquipment = self.isEquipment!()
        let systemLower2Bytes = self.systemLower2BytesCounter.incrementAndToBytes()
        let header10Bytes = Data([
            0xFF,
            0xFF,
            0x00,
            0x00,
            HSMSMessage.MessageType.linktestRequest.pType,
            HSMSMessage.MessageType.linktestRequest.sType,
            (isEquipment ? ids[0] : 0),
            (isEquipment ? ids[1] : 0),
            systemLower2Bytes[0],
            systemLower2Bytes[1]
        ])
        return self.build(header10Bytes: header10Bytes)
    }
    
    public func buildSeparateRequest(sessionId: UInt16) -> HSMSMessage {
        let ids = sessionId.toBytes()
        let isEquipment = self.isEquipment!()
        let systemLower2Bytes = self.systemLower2BytesCounter.incrementAndToBytes()
        let header10Bytes = Data([
            0xFF,
            0xFF,
            0x00,
            0x00,
            HSMSMessage.MessageType.separateRequest.pType,
            HSMSMessage.MessageType.separateRequest.sType,
            (isEquipment ? ids[0] : 0),
            (isEquipment ? ids[1] : 0),
            systemLower2Bytes[0],
            systemLower2Bytes[1]
        ])
        return self.build(header10Bytes: header10Bytes)
    }
    
}
