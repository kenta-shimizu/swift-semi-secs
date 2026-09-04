//
//  StateUpdateNotifier.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/06/30.
//

import Foundation

fileprivate struct ContinuationWrapper<T: Equatable & Sendable> {
    
    fileprivate let uuid = UUID()
    fileprivate let continuation: AsyncStream<T>.Continuation
    
    fileprivate init(_ continuation: AsyncStream<T>.Continuation) {
        self.continuation = continuation
    }
}

internal actor StateUpdateNotifier<T: Equatable & Sendable> {
    
    private var shutdowned: Bool
    private let (stream, continuation) = AsyncStream.makeStream(of: T.self)
    internal var lastState: T
    private var continuationWrappers: [ContinuationWrapper<T>]
    
    internal init(state: T) {
        self.shutdowned = false
        self.lastState = state
        self.continuation.yield(state)
        self.continuationWrappers = []
    }
    
    internal func shutdown() async {
        self.shutdowned = true
        self.continuation.finish()
        for wrapper in self.continuationWrappers {
            wrapper.continuation.finish()
        }
    }
    
    internal func yield(_ state: T) async {
        guard self.shutdowned == false else { return }
        if state != self.lastState {
            self.lastState = state
            self.continuation.yield(state)
            for wrapper in self.continuationWrappers {
                wrapper.continuation.yield(state)
            }
        }
    }
    
    internal nonisolated func stateUpdateStream() -> AsyncStream<T> {
        return self.stream
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
        guard self.shutdowned == false else {
            throw CancellationError()
        }
        if predicate(self.lastState) { return }
        let (stream, continuation) = AsyncStream.makeStream(of: T.self)
        let wrapper = ContinuationWrapper(continuation)
        self.continuationWrappers.append(wrapper)
        do {
            while true {
                let newState = try await stream.take()
                if predicate(newState) {
                    break
                }
            }
            continuation.finish()
            self.continuationWrappers.removeAll(where: { $0.uuid == wrapper.uuid })
        }
        catch {
            continuation.finish()
            self.continuationWrappers.removeAll(where: { $0.uuid == wrapper.uuid })
            throw error
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
