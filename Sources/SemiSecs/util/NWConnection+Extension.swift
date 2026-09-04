//
//  NWConnection+Extension.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/06/13.
//

import Foundation
import Network

extension NWConnection {
    
    /// start connect and await connected.
    ///
    /// - Parameters:
    ///     - queue: the DispatchQueue
    /// - Throws: `CancellationError`: if Canceled
    internal func connect(queue: DispatchQueue) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let (stateStream, stateContinuation) = AsyncStream.makeStream(of: Result<Void, Error>.self)
            self.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    stateContinuation.yield(Result.success(()))
                    stateContinuation.finish()
                case .failed(let error):
                    stateContinuation.yield(Result.failure(error))
                    stateContinuation.finish()
                case .cancelled:
                    stateContinuation.yield(Result.failure(CancellationError()))
                    stateContinuation.finish()
                default:
                    break
                }
            }
            
            Task {
                for await result in stateStream {
                    switch result {
                    case .success(_):
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            self.start(queue: queue)
        }
    }
    
    /// Receive data AsyncStream.
    ///
    /// - Parameters:
    ///     - maximumLength: the max data length
    /// - Returns: Receive Data Result AsyncStream
    internal func dataStream(maximumLength: Int = 4096) -> AsyncStream<Result<Data, Error>> {
        AsyncStream { continuation in
            @Sendable func readNext() {
                self.receive(minimumIncompleteLength: 1, maximumLength: maximumLength) { data, _, isComplete, error in
                    if let error = error {
                        continuation.yield(.failure(error))
                        continuation.finish()
                        return
                    }
                    
                    if let data = data, !data.isEmpty {
                        continuation.yield(.success(data))
                    }
                    
                    if isComplete {
                        continuation.finish()
                    } else {
                        readNext()
                    }
                }
            }
            
            readNext()
        }
    }

}
