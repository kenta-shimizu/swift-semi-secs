//
//  SECS1MessageTransactor.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/11/03.
//

import Foundation
import Synchronization

internal final class SECS1MessageTransactor: Sendable {
    
    private final class ReceiveMessageAndResettableTimer: Sendable {
        
        private let (stream, continuation) = AsyncStream.makeStream(of: SECS1Message.self)
        private let resetFlag = StateUpdateNotifier<Bool>(state: false)
        
        fileprivate init() {
            // Nothing
        }
        
        fileprivate func shutdown() {
            self.continuation.finish()
            self.resetFlag.shutdown()
        }
        
        fileprivate func poll(timeout: Duration) async throws -> SECS1Message? {
            return try await withThrowingTaskGroup(of: SECS1Message?.self) { group in
                group.addTask {
                    return try await self.stream.take()
                }
                group.addTask {
                    while !Task.isCancelled {
                        self.resetFlag.yield(false)
                        let result = try await self.resetFlag.until(true, timeout: timeout)
                        guard result else {
                            // timeout
                            break
                        }
                    }
                    return nil
                }
                
                defer {
                    group.cancelAll()
                }
                return try await group.next() ?? nil
            }
        }
        
        internal func yield(receiveMessage: SECS1Message) {
            self.continuation.yield(receiveMessage)
            self.continuation.finish()
        }
        
        fileprivate func reset() {
            self.resetFlag.yield(true)
        }
    }
    
    // MARK: -
    
    private let (willSendStream, willSendContinuation) = AsyncStream.makeStream(of: SECS1Message.self)
    private let (didReceiveStream, didReceiveContinuation) = AsyncStream.makeStream(of: SECS1Message.self)
    
    private let didSendMap = Mutex<[UInt32: AsyncStream<Result<SECS1Message, Error>>.Continuation]>([:])
    private let didReceiveMap = Mutex<[UInt32: ReceiveMessageAndResettableTimer]>([:])
    
    internal init() {
        // Nothing
    }
    
    deinit {
        self.shutdown()
    }
    
    internal let _timeoutT3 = Mutex<(@Sendable () -> Duration)?>(nil)
    
    internal var timeoutT3: (@Sendable () -> Duration)? {
        get { self._timeoutT3.withLock { $0 } }
        set { self._timeoutT3.withLock { $0 = newValue } }
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
            for (_, container) in $0 {
                container.shutdown()
            }
            $0 = [:]
        }
    }
    
    internal func willSendMessageStream() -> AsyncStream<SECS1Message> {
        return self.willSendStream
    }
    
    internal func didReceiveMessageStream() -> AsyncStream<SECS1Message> {
        return self.didReceiveStream
    }
    
    internal func sendAndAwaitResponse(message: SECS1Message) async throws -> SECS1Message? {
        
        if message.wbit {
            
            let container = ReceiveMessageAndResettableTimer()
            
            defer {
                self.didReceiveMap.withLock { $0[message.system4BytesKeyValue] = nil }
                container.shutdown()
            }
            
            self.didReceiveMap.withLock { $0[message.system4BytesKeyValue] = container }
            
            try await self.send(message: message)
            
            do {
                // wait until receive response message in timeout.
                guard let responseMessage = try await container.poll(timeout: self.timeoutT3!()) else {
                    throw SECS1WaitReplyError.timeoutT3(primaryMessage: message)
                }
                
                return responseMessage
            }
            catch is CancellationError {
                throw SECS1WaitReplyError.waitReplyFailedByTransactionShutdown(primaryMessage: message)
            }
            
        } else {
            try await self.send(message: message)
            return nil
        }
    }
    
    internal func send(message: SECS1Message) async throws {
        
        let (stream, continuation) = AsyncStream.makeStream(of: Result<SECS1Message, Error>.self)
        
        defer {
            self.didSendMap.withLock { $0[message.system4BytesKeyValue] = nil }
            continuation.finish()
        }
        
        self.didSendMap.withLock { $0[message.system4BytesKeyValue] = continuation }
        
        let yieldResult = self.willSendContinuation.yield(message)
        guard case .enqueued(_) = yieldResult else {
            throw SECS1SendError.sendFailedByCommunicatorShutdowned(message: message)
        }
        
        do {
            // await until did-send.
            let result = try await stream.take()
            
            switch result {
            case .success(_):
                // do nothing.
                break
            case .failure(_ as CancellationError):
                throw SECS1SendError.sendFailedByCommunicatorShutdowned(message: message)
            case .failure(let error as SECS1Error):
                throw error
            case .failure(let error):
                throw SECS1SendError.sendFailed(message: message, cause: error)
            }
        }
        catch is CancellationError {
            throw SECS1SendError.sendFailedByCommunicatorShutdowned(message: message)
        }
    }
    
    internal func yield(sendedMessage: SECS1Message, error: Error?) {
        self.didSendMap.withLock {
            if let continuation = $0[sendedMessage.system4BytesKeyValue] {
                if let sendError = error {
                    continuation.yield(Result.failure(sendError))
                } else {
                    continuation.yield(Result.success(sendedMessage))
                }
                continuation.finish()
            }
        }
    }
    
    internal func yield(receiveMessage: SECS1Message) {
        self.didReceiveMap.withLock {
            if let container = $0[receiveMessage.system4BytesKeyValue] {
                container.yield(receiveMessage: receiveMessage)
            } else {
                self.didReceiveContinuation.yield(receiveMessage)
            }
        }
    }
    
    /// Reset Timtout-T3 Timer
    internal func reset(block: SECS1Message.Block) {
        self.didReceiveMap.withLock {
            if let container = $0[block.system4BytesKeyValue] {
                container.reset()
            }
        }
    }
    
}
