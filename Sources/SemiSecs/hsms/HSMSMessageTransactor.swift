//
//  HSMSMessageTransactor.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/04/04.
//

import Foundation
import Network

internal struct HSMSMessageAndNWConnection: Hashable {
    
    internal let hsmsMessage: HSMSMessage
    internal let nwConnection: NWConnection

    internal init(message: HSMSMessage, connection: NWConnection) {
        self.hsmsMessage = message
        self.nwConnection = connection
    }
    
    static func == (lhs: HSMSMessageAndNWConnection, rhs: HSMSMessageAndNWConnection) -> Bool {
        return lhs.hsmsMessage.system4BytesKeyValue == rhs.hsmsMessage.system4BytesKeyValue && lhs.nwConnection === rhs.nwConnection
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.hsmsMessage.system4BytesKeyValue)
    }
}

internal actor HSMSMessageTransactor: AsyncShutdownable {
    
    internal nonisolated(unsafe) var timeoutT3: (() -> TimeInterval)?
    internal nonisolated(unsafe) var timeoutT6: (() -> TimeInterval)?
    internal nonisolated(unsafe) var onDidReceiveMessage: ((HSMSMessage, NWConnection) async -> Void)?
    internal nonisolated(unsafe) var onWillSendMessage: ((HSMSMessage, NWConnection) async -> Void)?
    
    private var didSendMap: [HSMSMessageAndNWConnection: AsyncQueue<Result<HSMSMessage, Error>>]
    private var didReceiveMap: [HSMSMessageAndNWConnection: AsyncQueue<HSMSMessage>]
    
    internal init() {
        self.timeoutT3 = nil
        self.timeoutT6 = nil
        self.onDidReceiveMessage = nil
        self.onWillSendMessage = nil
        self.didSendMap = [:]
        self.didReceiveMap = [:]
    }
    
    internal func shutdown() async {
        self.timeoutT3 = nil
        self.timeoutT6 = nil
        self.onDidReceiveMessage = nil
        self.onWillSendMessage = nil
        
        for (_, value) in self.didSendMap {
            await value.shutdown()
        }
        self.didSendMap = [:]
        
        for (_, value) in self.didReceiveMap {
            await value.shutdown()
        }
        self.didReceiveMap = [:]
    }
    
    internal func send(message: HSMSMessage, connection: NWConnection) async throws -> HSMSMessage? {
        
        func timeoutTx(_ msg: HSMSMessage) -> TimeInterval? {
            switch msg.messageType {
            case .data:
                return msg.wbit ? self.timeoutT3?() : nil
            case .selectRequest, .deselectRequest, .linktestRequest:
                return self.timeoutT6?()
            default:
                return nil
            }
        }
        
        if let timeout = timeoutTx(message) {
            
            let pair = HSMSMessageAndNWConnection(message: message, connection: connection)
            
            let didReceiveQueue = AsyncQueue<HSMSMessage>()
            self.didReceiveMap[pair] = didReceiveQueue
            
            do {
                try await self.reply(message: message, connection: connection)
                
                do {
                    // wait until receive response message in timeout.
                    guard let responseMessage = try await didReceiveQueue.poll(timeout: timeout) else {
                        
                        if message.isDataMessage {
                            throw HSMSError.timeoutT3(primaryMessage: message, connection: connection)
                        } else {
                            throw HSMSError.timeoutT6(primaryMessage: message, connection: connection)
                        }
                    }
                    
                    // throw error if response is RejectRequest.
                    if responseMessage.messageType == .rejectRequest {
                        throw HSMSError.rejectRequest(primaryMessage: message, rejectRequestMessage: responseMessage, connection: connection)
                    }
                    
                    // finally-success
                    self.didReceiveMap[pair] = nil
                    await didReceiveQueue.shutdown()
                    
                    return responseMessage
                }
                catch _ as AsyncShutdownError {
                    throw HSMSError.waitReplyFailedByTransactionShutdown(primaryMessage: message, connection: connection)
                }
            }
            catch {
                // finally-error
                self.didReceiveMap[pair] = nil
                await didReceiveQueue.shutdown()
                
                throw error
            }
            
        } else {
            
            try await self.reply(message: message, connection: connection)
            return nil
        }
    }
    
    internal func reply(message: HSMSMessage, connection: NWConnection) async throws {
        
        let pair = HSMSMessageAndNWConnection(message: message, connection: connection)
        
        let didSendQueue = AsyncQueue<Result<HSMSMessage, Error>>()
        self.didSendMap[pair] = didSendQueue
        
        do {
            // send message
            guard let sender = self.onWillSendMessage else {
                throw HSMSError.sendFailedByCommunicatorShutdowned(message: message, connection: connection)
            }
            await sender(message, connection)
            
            // wait until did-send.
            let result = try await didSendQueue.take()
            
            switch result {
            case .success(_):
                // do nothing.
                break
            case .failure(_ as AsyncShutdownError):
                throw HSMSError.sendFailedByCommunicatorShutdowned(message: message, connection: connection)
            case .failure(let error as HSMSError):
                throw error
            case .failure(let error):
                throw HSMSError.sendFailed(message: message, connection: connection, cause: error)
            }
            
            // finally-success
            self.didSendMap[pair] = nil
            await didSendQueue.shutdown()
        }
        catch {
            // finally-error
            self.didSendMap[pair] = nil
            await didSendQueue.shutdown()
            
            throw error
        }
    }
    
    internal func putDidSend(message: HSMSMessage, connection: NWConnection, error: Error?) async throws {
        
        let pair = HSMSMessageAndNWConnection(message: message, connection: connection)
        
        if let queue = self.didSendMap[pair] {
            if let sendError = error {
                try await queue.put(Result.failure(sendError))
            } else {
                try await queue.put(Result.success(message))
            }
        }
    }
    
    internal func putDidReceive(message: HSMSMessage, connection: NWConnection) async throws {
        
        let pair = HSMSMessageAndNWConnection(message: message, connection: connection)
        
        if let queue = self.didReceiveMap[pair] {
            try await queue.put(message)
        } else {
            await self.onDidReceiveMessage?(message, connection)
        }
    }
    
}
