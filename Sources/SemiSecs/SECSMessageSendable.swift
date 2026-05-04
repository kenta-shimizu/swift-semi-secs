//
//  SECSMessageSendable.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/04/15.
//

public protocol SECSMessageSendable {
    
    @discardableResult
    func send(stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2Body)?) async throws -> SECSMessage?
    
    @discardableResult
    func send(smlMessage: SMLMessage) async throws -> SECSMessage?
    
    func reply(primaryMessage: SECSMessage, stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2Body)?) async throws
    
    func reply(primaryMessage: SECSMessage, smlMessage: SMLMessage) async throws
    
}

public extension SECSMessageSendable {
    
    @discardableResult
    func send(stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2Body)?) async throws -> SECSMessage? {
        let smlMessage = SMLMessage(stream: stream, function: function, wbit: wbit, secs2Body: secs2Body)
        return try await self.send(smlMessage: smlMessage)
    }
    
    func reply(primaryMessage: SECSMessage, stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2Body)?) async throws {
        let smlMessage = SMLMessage(stream: stream, function: function, wbit: wbit, secs2Body: secs2Body)
        try await self.reply(primaryMessage: primaryMessage, smlMessage: smlMessage)
    }
    
}
