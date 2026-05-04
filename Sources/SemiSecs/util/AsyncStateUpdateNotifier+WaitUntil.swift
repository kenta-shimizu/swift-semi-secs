//
//  AsyncStateUpdateNotifier+WaitUntil.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/18.
//

import Foundation

extension AsyncStateUpdateNotifier {
    
    internal func waitUntil(state: T) async throws(AsyncShutdownError) {
        try await waitUntil(predicate: { $0 == state })
    }
    
    internal func waitUntilNot(state: T) async throws(AsyncShutdownError) {
        try await waitUntil(predicate: { $0 != state })
    }
    
    private func waitUntil(predicate: @escaping @Sendable (T?) -> Bool) async throws(AsyncShutdownError) {
        guard self.shutdowned == false else {
            throw .alreadyShutdowned
        }
        if predicate(self.state) {
            return
        }
        
        let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)
        defer {
            continuation.finish()
        }
        
        func waiting() async throws(AsyncShutdownError) {
            
            let observer = try await self.append(observer: {
                if let newState = $0 {
                    if predicate(newState) {
                        continuation.yield(true)
                    }
                } else {
                    continuation.yield(false)
                }
            })
            defer {
                self.remove(observer: observer)
            }
            
            var iterator = stream.makeAsyncIterator()
            guard let result = await iterator.next() else {
                throw .alreadyShutdowned
            }
            if result == false {
                throw .alreadyShutdowned
            }
        }
        
        try await waiting()
    }
    
    @discardableResult
    internal func waitUntil(state: T, timeout: TimeInterval) async throws(AsyncShutdownError) -> Bool {
        return try await self.waitUntil(perform: {
            try await self.waitUntil(state: state)
        }, timeout: timeout)
    }
    
    @discardableResult
    internal func waitUntilNot(state: T, timeout: TimeInterval) async throws(AsyncShutdownError) -> Bool {
        return try await self.waitUntil(perform: {
            try await self.waitUntilNot(state: state)
        }, timeout: timeout)
    }
    
    private func waitUntil(perform: @escaping @Sendable () async throws -> Void, timeout: TimeInterval) async throws(AsyncShutdownError) -> Bool {
        do {
            return try await withThrowingTaskGroup(of: Bool.self) { group in
                group.addTask {
                    try await perform()
                    return true
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(timeout))
                    return false
                }
                
                let firstResult = try await group.next()!
                group.cancelAll()
                return firstResult
            }
        }
        catch let error as AsyncShutdownError {
            throw error
        }
        catch {
            return false
        }
    }
    
}
