//
//  HSMSMessageTransactor.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/04/04.
//

import Foundation
import Network
import Synchronization

internal final class HSMSMessageTransactor: Sendable {
    
    private let (willSendStream, willSendContinuation) = AsyncStream.makeStream(of: HSMSMessageAndNWConnection.self)
    private let (didReceiveStream, didReceiveContinuation) = AsyncStream.makeStream(of: HSMSMessageAndNWConnection.self)
    
    private let didSendMap = Mutex<[HSMSMessageAndNWConnection: AsyncStream<Result<HSMSMessage, Error>>.Continuation]>([:])
    private let didReceiveMap = Mutex<[HSMSMessageAndNWConnection: AsyncStream<HSMSMessage>.Continuation]>([:])
    
    internal init() {
        // Nothing
    }
    
    internal let _timeoutT3 = Mutex<(@Sendable () -> Duration)?>(nil)
    
    internal var timeoutT3: (@Sendable () -> Duration)? {
        get { self._timeoutT3.withLock { $0 } }
        set { self._timeoutT3.withLock { $0 = newValue } }
    }

    private let _timeoutT6 = Mutex<(@Sendable () -> Duration)?>(nil)
    
    internal var timeoutT6: (@Sendable () -> Duration)? {
        get { self._timeoutT6.withLock { $0 } }
        set { self._timeoutT6.withLock { $0 = newValue } }
    }
    
    internal func shutdown() {
        self.willSendContinuation.finish()
        self.didReceiveContinuation.finish()
        
        self.didSendMap.withLock {
            for (_, continuation) in $0 {
                continuation.finish()
            }
            $0 = [:]
        }
        
        self.didReceiveMap.withLock {
            for (_, continuation) in $0 {
                continuation.finish()
            }
            $0 = [:]
        }
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
    
    internal func sendAndAwaitResponse(message: HSMSMessage, connection: NWConnection) async throws -> HSMSMessage? {
        
        if let timeout = timeoutTx(message) {
            
            let pair = HSMSMessageAndNWConnection(message: message, connection: connection)
            let (stream, continuation) = AsyncStream.makeStream(of: HSMSMessage.self)
            
            defer {
                self.didReceiveMap.withLock { $0[pair] = nil }
                continuation.finish()
            }
            
            self.didReceiveMap.withLock { $0[pair] = continuation }
            
            try await self.send(message: message, connection: connection)
            
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
                
                return responseMessage
            }
            catch is CancellationError {
                throw HSMSWaitReplyError.waitReplyFailedByTransactionShutdown(primaryMessage: message, connection: connection)
            }
            
        } else {
            
            try await self.send(message: message, connection: connection)
            return nil
        }
    }
    
    internal func send(message: HSMSMessage, connection: NWConnection) async throws {
        
        let pair = HSMSMessageAndNWConnection(message: message, connection: connection)
        let (stream, continuation) = AsyncStream.makeStream(of: Result<HSMSMessage, Error>.self)
        
        defer {
            self.didSendMap.withLock { $0[pair] = nil }
            continuation.finish()
        }
        
        self.didSendMap.withLock { $0[pair] = continuation }
        
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
    }
    
    internal func yield(sendedMessage: HSMSMessage, connection: NWConnection, error: Error?) {
        let pair = HSMSMessageAndNWConnection(message: sendedMessage, connection: connection)
        self.didSendMap.withLock {
            if let continuation = $0[pair] {
                if let sendError = error {
                    continuation.yield(Result.failure(sendError))
                } else {
                    continuation.yield(Result.success(sendedMessage))
                }
                continuation.finish()
            }
        }
    }
    
    internal func yield(receiveMessage: HSMSMessage, connection: NWConnection) {
        let pair = HSMSMessageAndNWConnection(message: receiveMessage, connection: connection)
        self.didReceiveMap.withLock {
            if let continuation = $0[pair] {
                continuation.yield(receiveMessage)
                continuation.finish()
            } else {
                self.didReceiveContinuation.yield(pair)
            }
        }
    }
    
}
