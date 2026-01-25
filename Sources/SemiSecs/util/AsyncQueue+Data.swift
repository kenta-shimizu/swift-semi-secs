//
//  AsyncQueue+Data.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/14.
//

import Foundation

/// extention AsyncQueue +Data
extension AsyncQueue where T == UInt8 {
    
    internal func put(data: Data) async throws(AsyncShutdownError) {
        try await self.put([UInt8](data))
    }
    
    /// Take first values as Data, waiting put values.
    ///
    /// - Parameter maxDataCount: The max Data count
    /// - Returns: The Data.
    /// - Throws: AsyncShutdownError if shutdowned.
    internal func take(maxDataCount: Int) async throws(AsyncShutdownError) -> Data {
        guard maxDataCount > 0 else {
            fatalError("maxDataCount must >0.")
        }
        guard self.shutdowned == false else {
            throw .alreadyShutdowned
        }
        
        func removeFirstData() -> Data? {
            guard self.queue.isEmpty == false else {
                return nil
            }
            let extract: [UInt8] = Array(self.queue.prefix(maxDataCount))
            self.queue.removeFirst(min(maxDataCount, extract.count))
            return Data(extract)
        }

        if let data = removeFirstData() {
            return data
        }
        
        let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)
        defer {
            continuation.finish()
        }
        
        func waiting() async throws(AsyncShutdownError) -> Data {
            
            let observer = try await self.append {
                continuation.yield($0 >= 0)
            }
            defer {
                self.remove(observer: observer)
            }
            
            for await result in stream {
                if result {
                    if let data = removeFirstData() {
                        return data
                    }
                } else {
                    throw .alreadyShutdowned
                }
            }
            throw .alreadyShutdowned
        }
        
        return try await waiting()
    }
    
    /// Poll first values as Data, waiting put values until timeout.
    ///
    /// - Parameter maxDataCount: The max Data count
    /// - Parameter timeout: The timeout.
    /// - Returns: The data if exist, othesise nil if timeout.
    /// - Throws: AsyncShutdownError if shutdowned.
    internal func poll(maxDataCount: Int, timeout: TimeInterval) async throws(AsyncShutdownError) -> Data? {
        guard maxDataCount > 0 else {
            fatalError("maxDataCount must >0.")
        }
        do {
            return try await withThrowingTaskGroup(of: Data?.self) { group in
                group.addTask {
                    return try await self.take(maxDataCount: maxDataCount)
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(timeout))
                    return nil
                }
                
                let data = try await group.next()!
                group.cancelAll()
                return data
            }
        }
        catch let error as AsyncShutdownError {
            throw error
        }
        catch {
            return nil
        }
    }
    
}
