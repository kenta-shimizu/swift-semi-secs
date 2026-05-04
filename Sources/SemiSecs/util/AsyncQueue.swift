//
//  AsyncQueue.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/06.
//

import Foundation

/// AsyncQueue put, take, poll, poll with timeout
internal actor AsyncQueue<T: Sendable>: AsyncShutdownable {
    
    internal struct ObserverWrapper: Sendable {
        fileprivate let uuid = UUID()
        fileprivate nonisolated(unsafe) let observer: (Int) -> Void
        
        fileprivate init(observer: @escaping (Int) -> Void) {
            self.observer = observer
        }
        
        /// Put -1 if shutdowned, otherwise queue size
        ///
        /// - Parameter size: the queue size
        fileprivate func put(_ queueCount: Int) {
            self.observer(queueCount)
        }
    }
    
    private var _shutdowned: Bool
    internal var shutdowned: Bool {
        get {
            _shutdowned
        }
    }
    
    internal var queue: [T] = []
    private var observers: [ObserverWrapper] = []
    
    internal init() {
        self._shutdowned = false
    }
    
    deinit {
        guard self._shutdowned == false else { return }
        for observer in self.observers {
            observer.put(-1)
        }
        self.observers.removeAll()
        self.queue.removeAll()
    }
    
    internal func shutdown() async {
        for observer in self.observers {
            observer.put(-1)
        }
        self.observers.removeAll()
        self.queue.removeAll()
        self._shutdowned = true
    }
    
    @discardableResult
    internal func append(observer: @escaping (Int) -> Void) async throws(AsyncShutdownError) -> ObserverWrapper {
        guard self.shutdowned == false else {
            throw .alreadyShutdowned
        }
        let wrapper = ObserverWrapper(observer: observer)
        self.observers.append(wrapper)
        return wrapper
    }
    
    internal func remove(observer: ObserverWrapper) {
        self.observers.removeAll { $0.uuid == observer.uuid }
    }
    
    /// Put value in queue.
    ///
    /// - Parameter value: The value
    /// - Throws: AsyncShutdownError if shutdowned.
    internal func put(_ value: T) async throws(AsyncShutdownError) {
        try await self.put([value])
    }
    
    /// Put value in queue.
    ///
    /// - Parameter value: the value.
    /// - Throws: AsyncShutdownError if shutdowned.
    internal func put(_ values: [T]) async throws(AsyncShutdownError) {
        guard self.shutdowned == false else {
            throw .alreadyShutdowned
        }
        self.queue.append(contentsOf: values)
        let size = self.queue.count
        for observer in self.observers {
            observer.put(size)
        }
    }
    
    /// Take first value in queue, waiting put value.
    ///
    /// - Returns: First value in queue.
    /// - Throws: AsyncShutdownError if shutdowned.
    @discardableResult
    internal func take() async throws(AsyncShutdownError) -> T {
        if let result = try await self.poll() {
            return result
        }
        
        let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)
        defer {
            continuation.finish()
        }
        
        func waiting() async throws(AsyncShutdownError) -> T {
            
            let observer = try await self.append {
                continuation.yield($0 >= 0)
            }
            defer {
                self.remove(observer: observer)
            }
            
            for await result in stream {
                if result {
                    if self.queue.isEmpty == false {
                        return self.queue.removeFirst()
                    }
                } else {
                    throw .alreadyShutdowned
                }
            }
            throw .alreadyShutdowned
        }
        
        return try await waiting()
    }
    
    /// Poll first value in queue.
    ///
    /// - Returns: Value if queue is present, othewise nil.
    /// - Throws: AsyncShutdownError if shutdowned.
    @discardableResult
    internal func poll() async throws(AsyncShutdownError) -> T? {
        guard self.shutdowned == false else {
            throw .alreadyShutdowned
        }
        if self.queue.isEmpty {
            return nil
        } else {
            return self.queue.removeFirst()
        }
    }
    
    /// Poll first value in queue, waiting put value until timeout.
    ///
    /// - Parameter timeout: The timeout.
    /// - Returns: First value in queue if exist, othesise nil if timeout.
    /// - Throws: AsyncShutdownError if shutdowned.
    @discardableResult
    internal func poll(timeout: TimeInterval) async throws(AsyncShutdownError) -> T? {
        do {
            return try await withThrowingTaskGroup(of: T?.self) { group in
                group.addTask {
                    return try await self.take()
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(timeout))
                    return nil
                }
                
                let result = try await group.next()!
                group.cancelAll()
                return result
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
