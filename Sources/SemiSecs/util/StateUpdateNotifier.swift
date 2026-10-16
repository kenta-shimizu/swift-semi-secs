//
//  StateUpdateNotifier.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/06/30.
//

import Foundation
import Synchronization

internal final class StateUpdateNotifier<T: Equatable & Sendable>: Sendable {
    
    private struct ContinuationWrapper: Sendable {
        
        internal let uuid = UUID()
        internal let continuation: AsyncStream<T>.Continuation
        
        internal init(_ continuation: AsyncStream<T>.Continuation) {
            self.continuation = continuation
        }
    }
    
    private struct Inner: Sendable {
        internal var shutdown: Bool
        internal var lastState: T
        internal let stream: AsyncStream<T>
        internal let continuation: AsyncStream<T>.Continuation
        internal var continuationWrappers: [ContinuationWrapper] = []
        
        internal init(state: T) {
            self.shutdown = false
            self.lastState = state
            (self.stream, self.continuation) = AsyncStream.makeStream(of: T.self)
            self.continuation.yield(state)
        }
        
        internal mutating func yield(_ state: T) {
            guard self.shutdown == false else { return }
            if state != self.lastState {
                self.lastState = state
                self.continuation.yield(state)
                for wrapper in self.continuationWrappers {
                    wrapper.continuation.yield(state)
                }
            }
        }
        
        internal mutating func finish() {
            guard self.shutdown == false else { return }
            self.shutdown = true
            self.continuation.finish()
            for wrapper in self.continuationWrappers {
                wrapper.continuation.finish()
            }
            self.continuationWrappers = []
        }
        
        internal mutating func append(_ wrapper: ContinuationWrapper) throws {
            guard self.shutdown == false else {
                throw CancellationError()
            }
            self.continuationWrappers.append(wrapper)
            wrapper.continuation.yield(self.lastState)
        }
        
        internal mutating func remove(_ wrapper: ContinuationWrapper) {
            self.continuationWrappers.removeAll(where: { $0.uuid == wrapper.uuid })
        }
        
    }
    
    private let inner: Mutex<Inner>
    
    internal init(state: T) {
        self.inner = Mutex<Inner>(Inner(state: state))
    }
    
    internal var lastState: T {
        get { self.inner.withLock { $0.lastState } }
    }
    
    internal func shutdown() {
        self.inner.withLock { $0.finish() }
    }
    
    internal func yield(_ state: T) {
        self.inner.withLock { $0.yield(state) }
    }
    
    internal func stateUpdateStream() -> AsyncStream<T> {
        return self.inner.withLock { $0.stream }
    }
    
    /// Wait until state changed.
    ///
    /// - Parameters:
    ///   - state: The target state
    /// - Throws:
    ///   - `CancellationError`: throw if cancelled.
    internal func until(_ state: T) async throws {
        try await self.until(predicate: { $0 == state })
    }
    
    /// Wait until state NOT changed.
    ///
    /// - Parameters:
    ///   - state: The target state
    /// - Throws:
    ///   - `CancellationError`: throw if cancelled.
    internal func untilNot(_ state: T) async throws {
        try await self.until(predicate: { $0 != state })
    }
    
    /// Wait until state changed with timeout.
    ///
    /// - Parameters:
    ///   - state: The target state
    ///   - timeout: The timeout duration
    /// - Returns: true if state changed, false if timeout.
    /// - Throws:
    ///   - `CancellationError`: throw if cancelled.
    @discardableResult
    internal func until(_ state: T, timeout: Duration) async throws -> Bool {
        return try await self.until(predicate: { $0 == state }, timeout: timeout)
    }
    
    /// Wait until state NOT changed with timeout.
    ///
    /// - Parameters:
    ///   - state: The target state
    ///   - timeout: The timeout duration
    /// - Returns: true if state changed, false if timeout.
    /// - Throws:
    ///   - `CancellationError`: throw if cancelled.
    @discardableResult
    internal func untilNot(_ state: T, timeout: Duration) async throws -> Bool {
        return try await self.until(predicate: { $0 != state }, timeout: timeout)
    }
    
    private func until(predicate: (T) -> Bool) async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: T.self)
        let wrapper = ContinuationWrapper(continuation)
        defer {
            continuation.finish()
            self.inner.withLock { $0.remove(wrapper) }
        }
        try self.inner.withLock { try $0.append(wrapper) }
        while true {
            let newState = try await stream.take()
            if predicate(newState) {
                break
            }
        }
    }
    
    private func until(predicate: @escaping @Sendable (T) -> Bool, timeout: Duration) async throws -> Bool {
        return try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                try await self.until(predicate: predicate)
                return true
            }
            group.addTask {
                try await Task.sleep(for: timeout)
                return false
            }
            
            defer {
                group.cancelAll()
            }
            return try await group.next()!
        }
    }
    
}
