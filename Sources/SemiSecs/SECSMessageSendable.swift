//
//  SECSMessageSendable.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/04/15.
//

/// Send SECS-Message
public protocol SECSMessageSendable {
    
    /// Send SECS message and await reponse message.
    ///
    /// If W-Bit is false, send message and wait until sended, returns nil.
    /// If W-Bit is true, send message, wait until sended and await response, returns response message.
    ///
    /// - Parameters:
    ///   - stream: the Stream number in the range 0...127
    ///   - function: the Function number in the range 0...255
    ///   - wbit: the W-Bit
    ///   - secs2Body: the SECS-II-Body
    /// - Returns: Response message if W-Bit is true, or nil if W-Bit is false.
    /// - Throws:
    ///   - SECSSendError: if send failed.
    ///   - SECSWaitReplyError: If receive response failed. (e.g. T3-Timeout)
    @discardableResult
    func send(stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2Body)?) async throws -> SECSMessage?
    
    /// Send SECS message and await reponse message.
    ///
    /// If W-Bit is false, send message and wait until sended, returns nil.
    /// If W-Bit is true, send message, wait until sended and await response, returns response message.
    ///
    /// - Parameters:
    ///   - smlMessage: the SML Message
    /// - Returns: Response message if W-Bit is true, or nil if W-Bit is false.
    /// - Throws:
    ///   - SECSSendError: if send failed.
    ///   - SECSWaitReplyError: If receive response failed. (e.g. T3-Timeout)
    @discardableResult
    func send(smlMessage: SMLMessage) async throws -> SECSMessage?
    
    /// Reply response SECS message and wait until sended.
    ///
    /// - Parameters:
    ///   - primaryMessage: the primary SECS Message
    ///   - stream: the Stream number in the range 0...127
    ///   - function: the Function number in the range 0...255
    ///   - wbit: the W-Bit
    ///   - secs2Body: the SECS-II-Body
    /// - Throws:
    ///   - SECSSendError: if send failed.
    func reply(primaryMessage: SECSMessage, stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2Body)?) async throws
    
    /// Reply response SECS message and wait until sended.
    ///
    /// - Parameters:
    ///   - primaryMessage: the primary SECS Message
    ///   - smlMessage: the SML Message
    /// - Throws:
    ///   - SECSSendError: if send failed.
    func reply(primaryMessage: SECSMessage, smlMessage: SMLMessage) async throws
    
}

public extension SECSMessageSendable {
    
    @discardableResult
    func send(stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2Body)? = nil) async throws -> SECSMessage? {
        let smlMessage = SMLMessage(stream: stream, function: function, wbit: wbit, secs2Body: secs2Body)
        return try await self.send(smlMessage: smlMessage)
    }
    
    func reply(primaryMessage: SECSMessage, stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2Body)? = nil) async throws {
        let smlMessage = SMLMessage(stream: stream, function: function, wbit: wbit, secs2Body: secs2Body)
        try await self.reply(primaryMessage: primaryMessage, smlMessage: smlMessage)
    }
    
}
