//
//  BlockingQueueAndNotifier.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/04.
//

import Foundation

internal final class BlockingQueueAndNotifier<T>: ShutdownableBase, @unchecked Sendable {
    
   
    fileprivate class Inner {
        
        fileprivate let semaphore = DispatchSemaphore(value: 1)
        fileprivate let queue: BlockingQueue<T> = BlockingQueue()
        fileprivate var observers: [(T) -> Void] = []
        
        fileprivate init() {
        }
        
        fileprivate func startLoop() {
            do {
                while true {
                    let value = try self.queue.take()
                    self.semaphore.wait()
                    for observer in self.observers {
                        observer(value)
                    }
                    self.semaphore.signal()
                }
            }
            catch {
                // Nothing
            }
        }
    }
    
    private let inner = Inner()
    
    internal override init() {
        
        super.init()
        self.append(shutdownable: self.inner.queue)
        
        Task {
            
        }
        
        DispatchQueue.global().async {
            self.inner.startLoop()
        }
    }
    
    internal override func shutdown() {
        self.inner.semaphore.wait()
        if !self.shutdowned {
            self.inner.observers.removeAll()
            super.shutdown()
        }
        self.inner.semaphore.signal()
    }
    
    @discardableResult
    internal func put(_ value: T) throws(ShutdownError) -> Bool {
        return try self.inner.queue.put(value)
    }
    
    internal func append(observer: @escaping (T) -> Void) {
        self.inner.semaphore.wait()
        self.inner.observers.append(observer)
        self.inner.semaphore.signal()
    }
}
