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
    ///   - message: The HSMS Message
    /// - Returns: Response HSMS Message
    /// - Throws:
    ///   - `HSMSSendError`: If send failed.
    ///   - `HSMSWaitReplyError`: If receive response failed.
    @discardableResult
    func send(message: HSMSMessage) async throws -> HSMSMessage?
    
    /// Send SELECT.req
    ///
    /// - Returns: SELECT.rsp
    /// - Throws:
    ///   - `HSMSSendError`: If send failed.
    ///   - `HSMSWaitReplyError`: If receive response failed. (e.g. T6-Timeout, Reject)
    @discardableResult
    func sendSelectRequest() async throws -> HSMSMessage?
    
    /// Reply SELECT.rsp
    /// - Parameters:
    ///   - selectRequest: The SELECT.req
    ///   - selectStatus: The SELECT Status
    /// - Throws:
    ///   - `HSMSSendError`: If send failed.
    func replySelectResponse(selectRequest: HSMSMessage, selectStatus: HSMSMessage.SelectStatus) async throws
    
    /// Send DESELECT.req
    ///
    /// - Returns: DESELECT.rsp
    /// - Throws:
    ///   - `HSMSSendError`: If send failed.
    ///   - `HSMSWaitReplyError`: If receive response failed. (e.g. T6-Timeout, Reject)
    @discardableResult
    func sendDeselectRequest() async throws -> HSMSMessage?
    
    /// Reply DESELECT.rsp
    /// - Parameters:
    ///   - deselectRequest: The DESELECT.req
    ///   - deselectStatus: The DESELECT Status
    /// - Throws:
    ///   - `HSMSSendError`: If send failed
    func replyDeselectResponse(deselectRequest: HSMSMessage, deselectStatus: HSMSMessage.DeselectStatus) async throws
    
    /// Send LINKTEST.req
    ///
    /// - Returns: LINKTEST.rsp
    /// - Throws:
    ///   - `HSMSSendError`: If send failed.
    ///   - `HSMSWaitReplyError`: If receive response failed. (e.g. T6-Timeout, Reject)
    @discardableResult
    func sendLinktestRequest() async throws -> HSMSMessage?
    
    /// Reply LINKTEST.rsp
    ///
    /// - Parameters:
    ///   - linktestRequest: The LINKTEST.req
    /// - Throws:
    ///   - `HSMSSendError`: If send failed.
    func replyLinktestResponse(linktestRequest: HSMSMessage) async throws
    
    /// Reply REJECT.req
    ///
    /// - Parameters:
    ///   - referenceMessage: The reference message
    ///   - rejectReason: The reject reason code
    ///   - byte2: P or S type number
    /// - Throws:
    ///   - `HSMSSendError`: If send failed.
    func replyRejectRequest(referenceMessage: HSMSMessage, rejectReason: HSMSMessage.RejectReason, byte2: UInt8) async throws
    
    /// Send SEPARATE.req
    ///
    /// - Throws:
    ///   - `HSMSSendError`: If send failed.
    func sendSeparateRequest() async throws
    
}
