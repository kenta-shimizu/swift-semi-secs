//
//  HSMSMessageTransactor.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/04/04.
//

import Foundation
import Network

internal actor HSMSMessageTransactor {
    
    private let (willSendStream, willSendContinuation) = AsyncStream.makeStream(of: HSMSMessageAndNWConnection.self)
    private let (didReceiveStream, didReceiveContinuation) = AsyncStream.makeStream(of: HSMSMessageAndNWConnection.self)
    
    private var didSendMap: [HSMSMessageAndNWConnection: AsyncStream<Result<HSMSMessage, Error>>.Continuation]
    private var didReceiveMap: [HSMSMessageAndNWConnection: AsyncStream<HSMSMessage>.Continuation]
    
    internal nonisolated(unsafe) var timeoutT3: (@Sendable () -> Duration)?
    internal nonisolated(unsafe) var timeoutT6: (@Sendable () -> Duration)?
    
    internal init() {
        self.timeoutT3 = nil
        self.timeoutT6 = nil
        self.didSendMap = [:]
        self.didReceiveMap = [:]
    }
    
    internal func shutdown() async {
        self.willSendContinuation.finish()
        self.didReceiveContinuation.finish()
        
        for (_, continuation) in self.didSendMap {
            continuation.finish()
        }
        self.didSendMap = [:]
        
        for (_, continuation) in self.didReceiveMap {
            continuation.finish()
        }
        self.didReceiveMap = [:]
    }
    
    internal func willSendMessageStream() -> AsyncStream<HSMSMessageAndNWConnection> {
        return self.willSendStream
    }
    
    internal func didReceiveMessageStream() -> AsyncStream<HSMSMessageAndNWConnection> {
        return self.didReceiveStream
    }
    
    private func timeoutTx(_ message: HSMSMessage) -> Duration? {
        switch message.messageType {
        case .data:
            return message.wbit ? self.timeoutT3!() : nil
        case .selectRequest, .deselectRequest, .linktestRequest:
            return self.timeoutT6!()
        default:
            return nil
        }
    }
    
    internal func send(message: HSMSMessage, connection: NWConnection) async throws -> HSMSMessage? {
        
        if let timeout = timeoutTx(message) {
            
            let pair = HSMSMessageAndNWConnection(message: message, connection: connection)
            let (stream, continuation) = AsyncStream.makeStream(of: HSMSMessage.self)
            self.didReceiveMap[pair] = continuation
            
            do {
                try await self.reply(message: message, connection: connection)
                
                do {
                    // wait until receive response message in timeout.
                    guard let responseMessage = try await stream.poll(timeout: timeout) else {
                        
                        if message.isDataMessage {
                            throw HSMSWaitReplyError.timeoutT3(primaryMessage: message, connection: connection)
                        } else {
                            throw HSMSWaitReplyError.timeoutT6(primaryMessage: message, connection: connection)
                        }
                    }
                    
                    // throw error if response is RejectRequest.
                    if responseMessage.messageType == .rejectRequest {
                        throw HSMSWaitReplyError.rejectRequest(primaryMessage: message, rejectRequestMessage: responseMessage, connection: connection)
                    }
                    
                    // finally-success
                    self.didReceiveMap[pair] = nil
                    continuation.finish()
                    
                    return responseMessage
                }
                catch is CancellationError {
                    throw HSMSWaitReplyError.waitReplyFailedByTransactionShutdown(primaryMessage: message, connection: connection)
                }
            }
            catch {
                // finally-error
                self.didReceiveMap[pair] = nil
                continuation.finish()
                
                throw error
            }
            
        } else {
            
            try await self.reply(message: message, connection: connection)
            return nil
        }
    }
    
    internal func reply(message: HSMSMessage, connection: NWConnection) async throws {
        
        let pair = HSMSMessageAndNWConnection(message: message, connection: connection)
        
        let (stream, continuation) = AsyncStream.makeStream(of: Result<HSMSMessage, Error>.self)
        
        self.didSendMap[pair] = continuation
        
        do {
            let yieldResult = self.willSendContinuation.yield(pair)
            guard case .enqueued(_) = yieldResult else {
                throw HSMSSendError.sendFailedByCommunicatorShutdowned(message: message, connection: connection)
            }
            
            do {
                // await until did-send.
                let result = try await stream.take()
                
                switch result {
                case .success(_):
                    // do nothing.
                    break
                case .failure(_ as CancellationError):
                    throw HSMSSendError.sendFailedByCommunicatorShutdowned(message: message, connection: connection)
                case .failure(let error as HSMSError):
                    throw error
                case .failure(let error):
                    throw HSMSSendError.sendFailed(message: message, connection: connection, cause: error)
                }
            }
            catch is CancellationError {
                throw HSMSSendError.sendFailedByCommunicatorShutdowned(message: message, connection: connection)
            }
            
            // finally-success
            self.didSendMap[pair] = nil
            continuation.finish()
        }
        catch {
            // finally-error
            self.didSendMap[pair] = nil
            continuation.finish()
            
            throw error
        }
    }
    
    internal func yield(sendedMessage: HSMSMessage, connection: NWConnection, error: Error?) async {
        
        let pair = HSMSMessageAndNWConnection(message: sendedMessage, connection: connection)
        
        if let continuation = self.didSendMap[pair] {
            if let sendError = error {
                continuation.yield(Result.failure(sendError))
            } else {
                continuation.yield(Result.success(sendedMessage))
            }
            continuation.finish()
        }
    }
    
    internal func yield(receiveMessage: HSMSMessage, connection: NWConnection) async {
        
        let pair = HSMSMessageAndNWConnection(message: receiveMessage, connection: connection)
        
        if let continuation = self.didReceiveMap[pair] {
            continuation.yield(receiveMessage)
            continuation.finish()
        } else {
            self.didReceiveContinuation.yield(pair)
        }
    }
    
}
