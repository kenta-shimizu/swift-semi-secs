//
//  HSMSSession+HSMSSS.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/07/12.
//

import Foundation
import os
import Network

extension HSMSSession {
    
    internal func receiveAsHSMSSSActive(message: HSMSMessage, connection: NWConnection) async {
        // check equal NWConnection
        guard let sessionConnection = await self.connectionAndState.connection else { return }
        guard connection === sessionConnection else { return }
        
        // check state
        let sessionState = await self.connectionAndState.hsmsConnectionStateUpdateNotifier.lastState
        guard sessionState != .notConnected else { return }
        
        do {
            switch message.messageType {
            case .data:
                self.receiveHSMSMessageCotinuation.yield(message)
                
            case .selectRequest:
                try await self.replySelectResponse(selectRequest: message, selectStatus: .actived)
                
            case .selectResponse:
                try await self.replyRejectRequest(referenceMessage: message, rejectReason: .transactionNotOpen, byte2: message.header10Bytes[5])
                
            case .deselectRequest:
                try await self.replyRejectRequest(referenceMessage: message, rejectReason: .notSupportTypeS, byte2: message.header10Bytes[5])
                
            case .deselectResponse:
                try await self.replyRejectRequest(referenceMessage: message, rejectReason: .transactionNotOpen, byte2: message.header10Bytes[5])
                
            case .linktestRequest:
                try await self.replyLinktestResponse(linktestRequest: message)
                
            case .linktestResponse:
                try await self.replyRejectRequest(referenceMessage: message, rejectReason: .transactionNotOpen, byte2: message.header10Bytes[5])
                
            case .rejectRequest:
                // ignore
                break
                
            case .separateRequest:
                await self.connectionAndState.unset()
                
            default:
                if HSMSMessage.MessageType.hasPType(hsmsMessage: message) {
                    try await self.replyRejectRequest(referenceMessage: message, rejectReason: .notSupportTypeS, byte2: message.header10Bytes[5])
                } else {
                    try await self.replyRejectRequest(referenceMessage: message, rejectReason: .notSupportTypeP, byte2: message.header10Bytes[4])
                }
            }
        }
        catch {
            Logger.communicator.error("\(error)")
        }
    }
    
    internal func receiveAsHSMSSSPassive(message: HSMSMessage, connection: NWConnection) async {
        // check equal NWConnection
        guard let sessionConnection = await self.connectionAndState.connection else { return }
        guard connection === sessionConnection else { return }
        
        // check state
        let sessionState = await self.connectionAndState.hsmsConnectionStateUpdateNotifier.lastState
        guard sessionState == .selected else { return }
        
        do {
            switch message.messageType {
            case .data:
                self.receiveHSMSMessageCotinuation.yield(message)
                
            case .selectRequest:
                try await self.replySelectResponse(selectRequest: message, selectStatus: .actived)
                
            case .selectResponse:
                try await self.replyRejectRequest(referenceMessage: message, rejectReason: .transactionNotOpen, byte2: message.header10Bytes[5])
                
            case .deselectRequest:
                try await self.replyRejectRequest(referenceMessage: message, rejectReason: .notSupportTypeS, byte2: message.header10Bytes[5])
                
            case .deselectResponse:
                try await self.replyRejectRequest(referenceMessage: message, rejectReason: .transactionNotOpen, byte2: message.header10Bytes[5])
                
            case .linktestRequest:
                try await self.replyLinktestResponse(linktestRequest: message)
                
            case .linktestResponse:
                try await self.replyRejectRequest(referenceMessage: message, rejectReason: .transactionNotOpen, byte2: message.header10Bytes[5])
                
            case .rejectRequest:
                // ignore
                break
                
            case .separateRequest:
                await self.connectionAndState.unset()
                
            default:
                if HSMSMessage.MessageType.hasPType(hsmsMessage: message) {
                    try await self.replyRejectRequest(referenceMessage: message, rejectReason: .notSupportTypeS, byte2: message.header10Bytes[5])
                } else {
                    try await self.replyRejectRequest(referenceMessage: message, rejectReason: .notSupportTypeP, byte2: message.header10Bytes[4])
                }
            }
        }
        catch {
            Logger.communicator.error("\(error)")
        }
    }
    
}
