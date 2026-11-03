//
//  SECS1RecweiveByteAndSendMessageQueue.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/10/28.
//

import Foundation
import Synchronization

internal final class SECS1RecweiveByteAndSendMessageQueue: Sendable {
    
    private struct Inner: Sendable {
        
        private let state = StartAndShutdown()
        
        private var receiveByteQueue: [UInt8]
        private var receiveByteContinuations: [AsyncStream<Int>.Continuation]
        
        private var sendSECS1MessageQueue: [SECS1Message]
        private var sendSECS1MessageContinuations: [AsyncStream<Int>.Continuation]
        
        fileprivate init() {
            try! self.state.start()
            self.receiveByteQueue = []
            self.receiveByteContinuations = []
            self.sendSECS1MessageQueue = []
            self.sendSECS1MessageContinuations = []
        }
        
        fileprivate mutating func shutdown() {
            guard self.state.shutdown() == false else { return }
            
            self.receiveByteQueue = []
            for continuation in self.receiveByteContinuations {
                continuation.finish()
            }
            self.receiveByteContinuations = []
            
            self.sendSECS1MessageQueue = []
            for continuation in self.sendSECS1MessageContinuations {
                continuation.finish()
            }
            self.sendSECS1MessageContinuations = []
        }
        
        fileprivate mutating func yield(receiveBytes: Data) {
            guard self.state.isRunning else { return }
            for value in receiveBytes {
                self.receiveByteQueue.append(value)
            }
            let count = self.receiveByteQueue.count
            for continuation in self.receiveByteContinuations {
                continuation.yield(count)
            }
            self.receiveByteContinuations = []
        }
        
        fileprivate mutating func receiveByteAsyncStream() -> AsyncStream<Int> {
            let (asyncStream, continuation) = AsyncStream.makeStream(of: Int.self)
            
            guard self.state.isRunning else {
                continuation.finish()
                return asyncStream
            }
            
            let count = self.receiveByteQueue.count
            if count > 0 {
                continuation.yield(count)
            } else {
                self.receiveByteContinuations.append(continuation)
            }
            
            return asyncStream
        }
        
        fileprivate mutating func messageAsyncStream() -> AsyncStream<Int> {
            let (asyncStream, continuation) = AsyncStream.makeStream(of: Int.self)
            
            guard self.state.isRunning else {
                continuation.finish()
                return asyncStream
            }
            
            let count = self.sendSECS1MessageQueue.count
            if count > 0 {
                continuation.yield(count)
            } else {
                self.sendSECS1MessageContinuations.append(continuation)
            }
            
            return asyncStream
        }
        
        fileprivate mutating func yield(message: SECS1Message) {
            guard self.state.isRunning else { return }
            self.sendSECS1MessageQueue.append(message)
            let count = self.sendSECS1MessageQueue.count
            for continuation in self.sendSECS1MessageContinuations {
                continuation.yield(count)
            }
            self.sendSECS1MessageContinuations = []
        }
        
        fileprivate mutating func clearBytes() throws {
            guard self.state.isRunning else {
                throw CancellationError()
            }
            self.receiveByteQueue = []
        }
        
        fileprivate mutating func pollReceiveByte() throws -> UInt8? {
            guard self.state.isRunning else {
                throw CancellationError()
            }
            guard self.receiveByteQueue.isEmpty == false else {
                return nil
            }
            
            return self.receiveByteQueue.removeFirst()
        }
        
        fileprivate mutating func pollReceiveBytes(capacity: Int) throws -> Data? {
            guard self.state.isRunning else {
                throw CancellationError()
            }
            var count = self.receiveByteQueue.count
            guard count > 0 else {
                return nil
            }
            if count > capacity {
                count = capacity
            }
            
            let prefix = self.receiveByteQueue.prefix(count)
            self.receiveByteQueue.removeFirst(count)
            
            return Data(Array(prefix))
        }
        
        fileprivate func peekFirstSendMessage() throws -> SECS1Message? {
            guard self.state.isRunning else {
                throw CancellationError()
            }
            
            return self.sendSECS1MessageQueue.first
        }
        
        fileprivate mutating func removeFirstSendMessage() throws {
            guard self.state.isRunning else {
                throw CancellationError()
            }
            guard self.sendSECS1MessageQueue.isEmpty == false else {
                return
            }
            
            self.sendSECS1MessageQueue.removeFirst()
        }
        
    }
    
    // MARK: -
    
    private let inner = Mutex<Inner>(Inner())
    
    internal init() {
        // Nothing
    }
    
    deinit {
        self.shutdown()
    }
    
    internal func shutdown() {
        self.inner.withLock { $0.shutdown() }
    }
    
    internal func yield(receiveBytes: Data) {
        self.inner.withLock { $0.yield(receiveBytes: receiveBytes) }
    }
    
    internal func yield(message: SECS1Message) {
        self.inner.withLock { $0.yield(message: message)}
    }
    
    @discardableResult
    internal func untilEntry() async throws -> Int {
        return try await withThrowingTaskGroup(of: Int.self) { group in
            group.addTask {
                let asyncStream = self.inner.withLock { $0.receiveByteAsyncStream() }
                return try await asyncStream.take()
            }
            group.addTask {
                let asyncStream = self.inner.withLock { $0.messageAsyncStream() }
                return try await asyncStream.take()
            }
            
            defer {
                group.cancelAll()
            }
            return try await group.next() ?? 0
        }
    }
    
    internal func clearBytes() throws {
        try self.inner.withLock { try $0.clearBytes() }
    }
    
    @discardableResult
    internal func pollReceiveByte() throws -> UInt8? {
        try self.inner.withLock { try $0.pollReceiveByte() }
    }
    
    @discardableResult
    internal func pollReceiveByte(timeout: Duration) async throws -> UInt8? {
        let asyncStream = self.inner.withLock { $0.receiveByteAsyncStream() }
        guard let _ = try await asyncStream.poll(timeout: timeout) else {
            return nil
        }
        return try self.pollReceiveByte()
    }
    
    @discardableResult
    internal func pollReceiveByte(capacity: Int, timeout: Duration) async throws -> Data? {
        let asyncStream = self.inner.withLock { $0.receiveByteAsyncStream() }
        guard let _ = try await asyncStream.poll(timeout: timeout) else {
            return nil
        }
        return try self.inner.withLock { try $0.pollReceiveBytes(capacity: capacity) }
    }
    
    @discardableResult
    internal func peekFirstSendMessage() throws -> SECS1Message? {
        return try self.inner.withLock { try $0.peekFirstSendMessage() }
    }
    
    internal func removeFirstSendMessage() throws {
        try self.inner.withLock { try $0.removeFirstSendMessage() }
    }
    
}
