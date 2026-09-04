//
//  AsyncStream+Extension.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/06/20.
//

import Foundation

extension AsyncStream {
    
    /// Returns value waiting until yield value, othewise nil if cancelled or finished.
    ///
    /// - Returns: The value
    /// - Throws: `CancellationError`: if finished or cancelled.
    @discardableResult
    internal func take() async throws -> Element {
        var iterator = self.makeAsyncIterator()
        guard let result = await iterator.next() else {
            throw CancellationError()
        }
        return result;
    }
    
}
  
extension AsyncStream where Element: Sendable {

    /// Returns value waiting until yield value, otherwise nil if timeout, cancelled or finished.
    ///
    /// If timeout, stream is finished.
    /// - Parameters:
    ///     - timeout: The timeout
    /// - Returns: The value, otherwise nil if timeout.
    /// - Throws: `CancellationError`: if finished or cancelled.
    @discardableResult
    internal func poll(timeout: Duration) async throws -> Element? {
        return try await withThrowingTaskGroup(of: Element?.self) { group in
            group.addTask {
                return try await self.take()
            }
            group.addTask {
                try await Task.sleep(for: timeout)
                return nil
            }
            
            defer {
                group.cancelAll()
            }
            return try await group.next() ?? nil
        }
    }
    
}

extension AsyncStream.Continuation where Element == UInt8 {
    
    /// Yield all Data as UInt8
    ///
    /// - Parameters:
    ///     - data: the Data
    internal func yield(data: Data) {
        for value in data {
            self.yield(value)
        }
    }
    
}
