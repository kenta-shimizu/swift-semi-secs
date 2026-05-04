//
//  HSMSMessageBuilder.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/26.
//

import Foundation

public protocol HSMSMessageBuildable {
    
    /// Build HSMSMessage
    ///
    /// Parameter header10Bytes: the Header10Bytes
    /// Parameter secs2Body: the SECS2Body
    /// Returns: HSMSMessage
    func build(header10Bytes: Data, secs2Body: (any SECS2Body)?) -> HSMSMessage
    
    /// Build primary-Data-HSMSMessage.
    ///
    /// - Parameter sessionId: the Session-ID
    /// - Parameter stream: the stream number
    /// - Parameter function: the function number
    /// - Parameter wbit: the wbit
    /// - Parameter secs2Body: SECS-II-Body
    /// - Returns: Primary HSMSMessage
    func buildPrimaryData(sessionId: UInt16, stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2Body)?) -> HSMSMessage
    
    /// Build primary-Data-HSMSMessage.
    ///
    /// - Parameter sessionId: the the Session-ID
    /// - Parameter smlMessage: the SMLMessage
    /// - Returns: Primary HSMSMessage
    func buildPrimaryData(sessionId: UInt16, smlMessage: SMLMessage) -> HSMSMessage
    
    /// Build response--HSMSMessage.
    ///
    /// - Parameter primaryMessage: the  primary-SECSMessage
    /// - Parameter stream: the stream number
    /// - Parameter function: the function number
    /// - Parameter wbit: the wbit
    /// - Parameter secs2Body: SECS-II-Body
    /// - Returns: Response HSMSMessage
    func buildResponseData(primaryMessage: SECSMessage, stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2Body)?) -> HSMSMessage
    
    /// Build response-message.
    ///
    /// - Parameter primaryMessage: the  primary-SECSMessage
    /// - Parameter smlMessage: the SMLMessage
    /// - Returns: Response HSMSMessage
    func buildResponseData(primaryMessage: SECSMessage, smlMessage: SMLMessage) -> HSMSMessage
    
    /// Build SELECT.REQ
    ///
    /// - Parameter sessionId: the Session-ID
    /// - Returns: SELECT.REQ
    func buildSelectRequest(sessionId: UInt16) -> HSMSMessage
    
    /// Build SELECT.RSP
    ///
    /// - Parameter selectRequest: SELECT.REQ
    /// - Parameter selectStatus: the SELECT Status
    /// - Returns: SELECT.RSP
    func buildSelectResponse(selectRequest: HSMSMessage, selectStatus: HSMSMessage.SelectStatus) -> HSMSMessage
    
    /// Build DESELECT.REQ
    ///
    /// - Parameter sessionId: the Session-ID
    /// - Returns: DESELECT.REQ
    func buildDeselectRequest(sessionId: UInt16) -> HSMSMessage
    
    /// Build DESELECT.RSP
    ///
    /// - Parameter deselectRequest: DESELECT.REQ
    /// - Parameter deselectStatus: the DESELECT Status
    /// - Returns: DESELECT.RSP
    func buildDeselectResponse(deselectRequest: HSMSMessage, deselectStatus: HSMSMessage.DeselectStatus) -> HSMSMessage
    
    /// Build LINKTEST.REQ
    ///
    /// - Parameter sessionId: the Session-ID
    /// - Returns: LINKTEST.REQ
    func buildLinktestRequest(sessionId: UInt16) -> HSMSMessage
    
    /// Build LINKTEST.RSP
    ///
    /// - Parameter linktestRequest: LINKTEST.REQ
    /// - Returns: LINKTEST.RSP
    func buildLinktestResponse(linktestRequest: HSMSMessage) -> HSMSMessage
    
    /// Build REJECT.REQ
    ///
    /// - Parameter referenceMessage: the reference message
    /// - Parameter rejectReason: the REJECT reason
    /// - Parameter byte2: headere[2] Number of P or S type
    /// - Returns: REJECT.REQ
    func buildRejectRequest(referenceMessage: HSMSMessage, rejectReason: HSMSMessage.RejectReason, byte2: UInt8) -> HSMSMessage
    
    /// Build SEPARATE.REQ
    ///
    /// - Parameter sessionId: the Session-ID
    /// - Returns: SEPARATE.REQ
    func buildSeparateRequest(sessionId: UInt16) -> HSMSMessage
    
}

public extension HSMSMessageBuildable {
    
    func build(header10Bytes: Data, secs2Body: (any SECS2Body)? = nil) -> HSMSMessage {
        return HSMSMessage(header10Bytes: header10Bytes, secs2Body: secs2Body)
    }
    
    func buildPrimaryData(sessionId: UInt16, stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2Body)? = nil) -> HSMSMessage {
        let smlMessage = SMLMessage(stream: stream, function: function, wbit: wbit, secs2Body: secs2Body)
        return self.buildPrimaryData(sessionId: sessionId, smlMessage: smlMessage)
    }
    
    func buildResponseData(primaryMessage: SECSMessage, stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2Body)? = nil) -> HSMSMessage {
        let smlMessage = SMLMessage(stream: stream, function: function, wbit: wbit, secs2Body: secs2Body)
        return self.buildResponseData(primaryMessage: primaryMessage, smlMessage: smlMessage)
    }
    
    func buildResponseData(primaryMessage: SECSMessage, smlMessage: SMLMessage) -> HSMSMessage {
        let ref = primaryMessage.header10Bytes
        let header10Bytes = Data([
            ref[0],
            ref[1],
            (smlMessage.stream | (smlMessage.wbit ? 0x80 : 0x00)),
            smlMessage.function,
            HSMSMessage.MessageType.data.pType,
            HSMSMessage.MessageType.data.sType,
            ref[6],
            ref[7],
            ref[8],
            ref[9]
        ])
        return self.build(header10Bytes: header10Bytes, secs2Body: smlMessage.secs2Body)
    }
    
    func buildSelectResponse(selectRequest: HSMSMessage, selectStatus: HSMSMessage.SelectStatus) -> HSMSMessage {
        let ref = selectRequest.header10Bytes
        let header10Bytes = Data([
            ref[0],
            ref[1],
            0x00,
            selectStatus.statusByte,
            HSMSMessage.MessageType.selectResponse.pType,
            HSMSMessage.MessageType.selectResponse.sType,
            ref[6],
            ref[7],
            ref[8],
            ref[9]
        ])
        return self.build(header10Bytes: header10Bytes)
    }
    
    func buildDeselectResponse(deselectRequest: HSMSMessage, deselectStatus: HSMSMessage.DeselectStatus) -> HSMSMessage {
        let ref = deselectRequest.header10Bytes
        let header10Bytes = Data([
            ref[0],
            ref[1],
            0x00,
            deselectStatus.statusByte,
            HSMSMessage.MessageType.deselectResponse.pType,
            HSMSMessage.MessageType.deselectResponse.sType,
            ref[6],
            ref[7],
            ref[8],
            ref[9]
        ])
        return self.build(header10Bytes: header10Bytes)
    }
    
    func buildLinktestResponse(linktestRequest: HSMSMessage) -> HSMSMessage {
        let ref = linktestRequest.header10Bytes
        let header10Bytes = Data([
            ref[0],
            ref[1],
            0x00,
            0x00,
            HSMSMessage.MessageType.linktestResponse.pType,
            HSMSMessage.MessageType.linktestResponse.sType,
            ref[6],
            ref[7],
            ref[8],
            ref[9]
        ])
        return self.build(header10Bytes: header10Bytes)
    }
    
    func buildRejectRequest(referenceMessage: HSMSMessage, rejectReason: HSMSMessage.RejectReason, byte2: UInt8) -> HSMSMessage {
        let ref = referenceMessage.header10Bytes
        let header10Bytes = Data([
            ref[0],
            ref[1],
            byte2,
            rejectReason.reasonByte,
            HSMSMessage.MessageType.rejectRequest.pType,
            HSMSMessage.MessageType.rejectRequest.sType,
            ref[6],
            ref[7],
            ref[8],
            ref[9]
        ])
        return self.build(header10Bytes: header10Bytes)
    }
    
}
