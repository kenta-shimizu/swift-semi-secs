//
//  AsyncStateChangeNotifier.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/14.
//

import Foundation

internal actor AsyncStateChangeNotifier<T: Equatable & Sendable>: AsyncShutdownable  {
    
    internal struct ObserverWrapper: @unchecked Sendable {
        fileprivate let uuid = UUID()
        fileprivate let observer: (T?) -> Void
        
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
    
    private var lastState: T
    internal var state: T {
        get {
            lastState
        }
    }
    
    private var observers: [ObserverWrapper] = []

    internal init(_ state: T) {
        self._shutdowned = false
        self.lastState = state
    }
    
    deinit {
        if self._shutdowned == false {
            for observer in self.observers {
                observer.put(nil)
            }
            self.observers.removeAll()
        }
    }
    
    internal func shutdown() async {
        for observer in self.observers {
            observer.put(nil)
        }
        self.observers.removeAll()
        self._shutdowned = true
    }
    
    internal func set(_ state: T) async throws(AsyncShutdownError) {
        guard self.shutdowned == false else {
            throw .alreadyShutdowned
        }
        if state != self.lastState {
            self.lastState = state
            for observer in self.observers {
                observer.put(state)
            }
        }
    }
    
    @discardableResult
    internal func append(observer: @escaping (T?) -> Void) async throws(AsyncShutdownError) -> ObserverWrapper {
        guard self.shutdowned == false else {
            throw .alreadyShutdowned
        }
        let wrapper = ObserverWrapper(observer: observer)
        self.observers.append(wrapper)
        return wrapper
    }
    
    internal func remove(observer: ObserverWrapper) {
        self.observers.removeAll {$0.uuid == observer.uuid}
    }
    
}
