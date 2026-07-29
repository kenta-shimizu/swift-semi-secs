//
//  NWListenerStreamWrapper.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/07/17.
//

import Foundation
import Network

internal final class NWListenerStreamWrapper: Sendable {
    
    internal final class NWConnectionAndDispatchQueue: Sendable {
        
        internal let connection: NWConnection
        internal let queue: DispatchQueue
        
        internal init(connection: NWConnection, queue: DispatchQueue) {
            self.connection = connection
            self.queue = queue
        }
    }
    
    private let (stream, continuation) = AsyncStream.makeStream(of: Result<NWConnectionAndDispatchQueue, Error>.self)
    private let listener: NWListener
    private nonisolated(unsafe) var connections: [NWConnection]
    
    internal init(using: NWParameters, on: NWEndpoint.Port) throws {
        self.listener = try NWListener(using: using, on: on)
        self.connections = []
    }
    
    /// Start NWListener.
    ///
    /// - Parameters:
    ///   - queue: The DispatchQueue
    internal func start(queue: DispatchQueue) throws {
        
        self.listener.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            
            switch state {
            case .failed(let error):
                self.continuation.yield(.failure(error))
                self.continuation.finish()
            case .cancelled:
                self.continuation.yield(.failure(CancellationError()))
                self.continuation.finish()
            default:
                break
            }
        }
            
        self.listener.newConnectionHandler = { [weak self] connection in
            guard let self = self else { return }
            
            self.continuation.yield(.success(NWConnectionAndDispatchQueue(connection: connection, queue: queue)))
            
            // cleanup cancelled.
            self.connections.removeAll { $0.state == .cancelled }
            // append
            self.connections.append(connection)
        }
        
        self.listener.start(queue: queue)
    }
    
    /// Cancel NWListener and connected NWConnection.
    internal func cancel() {
        self.listener.cancel()
        self.continuation.finish()
        for connection in self.connections {
            if connection.state != .cancelled {
                connection.cancel()
            }
        }
        self.connections.removeAll()
    }
    
    /// Returns NWConnection and DispatchQueue Result AsyncStream
    ///
    /// - Returns: NWConnection and DispatchQueue Result AsyncStream
    internal func connectionAndQueueStream() -> AsyncStream<Result<NWConnectionAndDispatchQueue, Error>> {
        return self.stream
    }
    
}


