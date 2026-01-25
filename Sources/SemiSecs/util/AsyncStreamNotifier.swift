//
//  AsyncStreamNotifier.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/24.
//

import Foundation

/// AsyncStreamNotifier, notify value via AsyncStream.
internal actor AsyncStreamNotifier<T: Sendable>: AsyncShutdownable {
    
    internal struct ObserverWrapper: @unchecked Sendable {
        fileprivate let uuid = UUID()
        fileprivate let observer: (T) -> Void
        
        fileprivate init(observer: @escaping (T) -> Void) {
            self.observer = observer
        }
        
        /// Put value
        fileprivate func put(_ value: T) {
            self.observer(value)
        }
    }
    
    private var _shutdowned: Bool
    internal var shutdowned: Bool {
        get {
            _shutdowned
        }
    }
    
    private var observers: [ObserverWrapper] = []
    
    private let (stream, continuation) = AsyncStream.makeStream(of: T.self)

    internal init() {
        self._shutdowned = false
        
        Task {
            for await value in self.stream {
                for observer in await self.observers {
                    observer.put(value)
                }
            }
        }
    }
    
    deinit {
        if self._shutdowned == false {
            self.continuation.finish()
            self.observers.removeAll()
        }
    }
    
    internal func shutdown() async {
        self.continuation.finish()
        self.observers.removeAll()
        self._shutdowned = true
    }
    
    /// Put value in stream.
    ///
    /// - Parameter value: the value
    /// - Throws: AsyncShutdownError if shutdowned.
    internal func put(_ value: T) async throws(AsyncShutdownError) {
        guard self.shutdowned == false else {
            throw .alreadyShutdowned
        }
        self.continuation.yield(value)
    }
    
    /// Append observer function, returns wrapped observer.
    ///
    /// - Parameter observer: observer function
    /// - Returns: wrapped observer
    /// - Throws: AsyncShutdownError if shutdowned.
    @discardableResult
    internal func append(observer: @escaping (T) -> Void) async throws(AsyncShutdownError) -> ObserverWrapper {
        guard self.shutdowned == false else {
            throw .alreadyShutdowned
        }
        let wrapper = ObserverWrapper(observer: observer)
        self.observers.append(wrapper)
        return wrapper
    }
    
    /// Remove observer.
    ///
    /// - Parameter observer: wrapped observer from append
    internal func remove(observer: ObserverWrapper) {
        self.observers.removeAll { $0.uuid == observer.uuid }
    }

}
