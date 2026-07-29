//
//  HSMSMessageSendable.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/04/04.
//

import Foundation

/// Send HSMS Control Message
public protocol HSMSMessageSendable: SECSMessageSendable {
    
    /// Send HSMS Message and await response HSMS Message.
    ///
    /// - Parameters:
    ///   - message: the HSMS Message
    /// - Returns: response HSMS Message
    /// - Throws:
    ///   - HSMSSendError: If send failed.
    ///   - HSMSWaitReplyError: If receive response failed.
    @discardableResult
    func send(message: HSMSMessage) async throws -> HSMSMessage?
    
    /// Send SELECT.req
    ///
    /// - Returns: SELECT.rsp
    /// - Throws:
    ///   - HSMSSendError: If send failed.
    ///   - HSMSWaitReplyError: If receive response failed. (e.g. T6-Timeout, Reject)
    @discardableResult
    func sendSelectRequest() async throws -> HSMSMessage?
    
    /// Reply SELECT.rsp
    /// - Parameters:
    ///   - selectRequest: the SELECT.req
    ///   - selectStatus: the SELECT Status
    /// - Throws:
    ///   - HSMSSendError: If send failed.
    func replySelectResponse(selectRequest: HSMSMessage, selectStatus: HSMSMessage.SelectStatus) async throws
    
    /// Send DESELECT.req
    ///
    /// - Returns: DESELECT.rsp
    /// - Throws:
    ///   - HSMSSendError: If send failed.
    ///   - HSMSWaitReplyError: If receive response failed. (e.g. T6-Timeout, Reject)
    @discardableResult
    func sendDeselectRequest() async throws -> HSMSMessage?
    
    /// Reply DESELECT.rsp
    /// - Parameters:
    ///   - deselectRequest: the DESELECT.req
    ///   - deselectStatus: the DESELECT Status
    /// - Throws:
    ///   - HSMSSendError: If send failed
    func replyDeselectResponse(deselectRequest: HSMSMessage, deselectStatus: HSMSMessage.DeselectStatus) async throws
    
    /// Send LINKTEST.req
    ///
    /// - Returns: LINKTEST.rsp
    /// - Throws:
    ///   - HSMSSendError: If send failed.
    ///   - HSMSWaitReplyError: If receive response failed. (e.g. T6-Timeout, Reject)
    @discardableResult
    func sendLinktestRequest() async throws -> HSMSMessage?
    
    /// Reply LINKTEST.rsp
    ///
    /// - Parameters:
    ///   - linktestRequest: the LINKTEST.req
    /// - Throws:
    ///   - HSMSSendError: If send failed.
    func replyLinktestResponse(linktestRequest: HSMSMessage) async throws
    
    /// Reply REJECT.req
    ///
    /// - Parameters:
    ///   - referenceMessage: the reference message
    ///   - rejectReason: the reject reason code
    ///   - byte2: P or S type number
    /// - Throws:
    ///   - HSMSSendError: If send failed.
    func replyRejectRequest(referenceMessage: HSMSMessage, rejectReason: HSMSMessage.RejectReason, byte2: UInt8) async throws
    
    /// Send SEPARATE.req
    ///
    /// - Throws:
    ///   - HSMSSendError: If send failed.
    func sendSeparateRequest() async throws
    
}
