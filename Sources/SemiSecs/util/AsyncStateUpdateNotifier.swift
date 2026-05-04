//
//  AsyncStateUpdateNotifier.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/14.
//

import Foundation

internal actor AsyncStateUpdateNotifier<T: Equatable & Sendable>: AsyncShutdownable  {
    
    internal struct ObserverWrapper: Sendable {
        fileprivate let uuid = UUID()
        fileprivate nonisolated(unsafe) let observer: (T?) -> Void
        
        fileprivate init(observer: @escaping (T?) -> Void) {
            self.observer = observer
        }
        
        /// Put nil if shutdowned, otherwise state
        fileprivate func put(_ state: T?) {
            self.observer(state)
        }
    }
    
    private var _shutdowned: Bool
    internal var shutdowned: Bool {
        get {
            _shutdowned
        }
    }
    
    private var lastState: T {
        didSet {
            if lastState != oldValue {
                for observer in self.observers {
                    observer.put(state)
                }
            }
        }
    }
    
    internal var state: T {
        get {
            lastState
        }
    }
    
    private var observers: [ObserverWrapper] = []

    internal init(state: T) {
        self._shutdowned = false
        self.lastState = state
    }
    
    deinit {
        guard self._shutdowned == false else { return }
        for observer in self.observers {
            observer.put(nil)
        }
        self.observers.removeAll()
    }
    
    internal func shutdown() async {
        guard self._shutdowned == false else { return }
        for observer in self.observers {
            observer.put(nil)
        }
        self.observers.removeAll()
        self._shutdowned = true
    }
    
    internal func set(state: T) async throws(AsyncShutdownError) {
        guard self.shutdowned == false else {
            throw .alreadyShutdowned
        }
        self.lastState = state
    }
    
    @discardableResult
    internal func append(observer: @escaping @Sendable (T?) -> Void) async throws(AsyncShutdownError) -> ObserverWrapper {
        guard self.shutdowned == false else {
            throw .alreadyShutdowned
        }
        let wrapper = ObserverWrapper(observer: observer)
        self.observers.append(wrapper)
        wrapper.put(self.lastState)
        return wrapper
    }
    
    internal func remove(observer: ObserverWrapper) {
        self.observers.removeAll {$0.uuid == observer.uuid}
    }
    
}
