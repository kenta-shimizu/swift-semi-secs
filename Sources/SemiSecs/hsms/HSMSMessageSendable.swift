//
//  HSMSMessageSendable.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/04/04.
//

import Foundation

public protocol HSMSMessageSendable: SECSMessageSendable {
    
    @discardableResult
    func send(message: HSMSMessage) async throws -> HSMSMessage?
    
    func reply(message: HSMSMessage) async throws
    
    @discardableResult
    func sendSelectRequest() async throws -> HSMSMessage?
    
    func replySelectResponse(selectRequest: HSMSMessage, selectStatus: HSMSMessage.SelectStatus) async throws
    
    @discardableResult
    func sendDeselectRequest() async throws -> HSMSMessage?
    
    func replyDeselectResponse(deselectRequest: HSMSMessage, deselectStatus: HSMSMessage.DeselectStatus) async throws
    
    @discardableResult
    func sendLinktestRequest() async throws -> HSMSMessage?
    
    func replyLinktestResponse(linktestRequest: HSMSMessage) async throws
    
    func replyRejectRequest(referenceMessage: HSMSMessage, rejectReason: HSMSMessage.RejectReason, byte2: UInt8) async throws
    
    func sendSeparateRequest() async throws
    
}
