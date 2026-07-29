//
//  HSMSGSMessageBuilder.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/03/01.
//

import Foundation
import Synchronization

public final class HSMSGSMessageBuilder: HSMSMessageBuildable {
    
    public var isEquipment: (() -> Bool)?
    private let systemLower2BytesCounter: Atomic<UInt16>
    
    public init() {
        self.isEquipment = nil
        self.systemLower2BytesCounter = Atomic<UInt16>(0)
    }
    
    private func toSessionIds(_ sessionId: UInt16) -> [UInt8] {
        return [
            UInt8(sessionId >> 8),
            UInt8(sessionId & 0x00FF)
        ]
    }
    
    private func atomicIncrement2Bytes() -> [UInt8] {
        let (_, newValue) = self.systemLower2BytesCounter.add(1, ordering: .relaxed)
        return [
            UInt8(newValue >> 8),
            UInt8(newValue & 0x00FF)
        ]
    }
    
    public func buildPrimaryData(sessionId: UInt16, smlMessage: SMLMessage) -> HSMSMessage {
        let ids = self.toSessionIds(sessionId)
        let isEquipment = self.isEquipment!()
        let systemLower2Bytes = self.atomicIncrement2Bytes()
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
        let ids = self.toSessionIds(sessionId)
        let isEquipment = self.isEquipment!()
        let systemLower2Bytes = self.atomicIncrement2Bytes()
        let header10Bytes = Data([
            ids[0],
            ids[1],
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
        let ids = self.toSessionIds(sessionId)
        let isEquipment = self.isEquipment!()
        let systemLower2Bytes = self.atomicIncrement2Bytes()
        let header10Bytes = Data([
            ids[0],
            ids[1],
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
        let ids = self.toSessionIds(sessionId)
        let isEquipment = self.isEquipment!()
        let systemLower2Bytes = self.atomicIncrement2Bytes()
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
        let ids = self.toSessionIds(sessionId)
        let isEquipment = self.isEquipment!()
        let systemLower2Bytes = self.atomicIncrement2Bytes()
        let header10Bytes = Data([
            ids[0],
            ids[1],
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
