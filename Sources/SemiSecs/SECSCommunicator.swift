//
//  SecsCommunicator.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Foundation
import Synchronization

public protocol SECSError: Error, CustomStringConvertible, CustomDebugStringConvertible {
}

public protocol SECSSendError: SECSError {
}

public protocol SECSWaitReplyError: SECSError {
}

public protocol SECSReceiveError: SECSError {
}

public protocol SECSCommunicatorError: SECSError {
}

public struct SECSCommunicatorTimeoutConfig: Sendable {
    
    private final class Inner: Sendable {
        fileprivate let t1 = Mutex<Duration>(.seconds( 1.0))
        fileprivate let t2 = Mutex<Duration>(.seconds(15.0))
        fileprivate let t3 = Mutex<Duration>(.seconds(45.0))
        fileprivate let t4 = Mutex<Duration>(.seconds(45.0))
        fileprivate let t5 = Mutex<Duration>(.seconds(10.0))
        fileprivate let t6 = Mutex<Duration>(.seconds( 5.0))
        fileprivate let t7 = Mutex<Duration>(.seconds(10.0))
        fileprivate let t8 = Mutex<Duration>(.seconds( 6.0))
    }
    
    private let inner = Inner()
    
    public init() {
        // Nothing
    }
    
    /// Timeout-T1
    public var t1: Duration {
        get {
            return self.inner.t1.withLock { $0 }
        }
        set {
            guard newValue > .zero else {
                fatalError("t1 set value >0.0")
            }
            self.inner.t1.withLock { $0 = newValue }
        }
    }
    
    /// Timeout-T2
    public var t2: Duration {
        get {
            return self.inner.t2.withLock { $0 }
        }
        set {
            guard newValue > .zero else {
                fatalError("t2 set value >0.0")
            }
            self.inner.t2.withLock { $0 = newValue }
        }
    }
    
    /// Timeout-T3
    public var t3: Duration {
        get {
            return self.inner.t3.withLock { $0 }
        }
        set {
            guard newValue > .zero else {
                fatalError("t3 set value >0.0")
            }
            self.inner.t3.withLock { $0 = newValue }
        }
    }
    
    /// Timeout-T4
    public var t4: Duration {
        get {
            return self.inner.t4.withLock { $0 }
        }
        set {
            guard newValue > .zero else {
                fatalError("t4 set value >0.0")
            }
            self.inner.t4.withLock { $0 = newValue }
        }
    }
    
    /// Timeout-T5
    public var t5: Duration {
        get {
            return self.inner.t5.withLock { $0 }
        }
        set {
            guard newValue > .zero else {
                fatalError("t5 set value >0.0")
            }
            self.inner.t5.withLock { $0 = newValue }
        }
    }
    
    /// Timeout-T6
    public var t6: Duration {
        get {
            return self.inner.t6.withLock { $0 }
        }
        set {
            guard newValue > .zero else {
                fatalError("t6 set value >0.0")
            }
            self.inner.t6.withLock { $0 = newValue }
        }
    }
    
    /// Timeout-T7
    public var t7: Duration {
        get {
            return self.inner.t7.withLock { $0 }
        }
        set {
            guard newValue > .zero else {
                fatalError("t7 set value >0.0")
            }
            self.inner.t7.withLock { $0 = newValue }
        }
    }
    
    /// Timeout-T8
    public var t8: Duration {
        get {
            return self.inner.t8.withLock { $0 }
        }
        set {
            guard newValue > .zero else {
                fatalError("t8 set value >0.0")
            }
            self.inner.t8.withLock { $0 = newValue }
        }
    }
    
}

/// SECS communicator config.
public protocol SECSCommunicatorConfig: Sendable {
    
    /// isEquipment communicator, true is equipment, otherwise false.
    var isEquipment: Bool { get set }
    
    /// timeout config.
    var timeout: SECSCommunicatorTimeoutConfig { get set }
    
}

public protocol SECSCommunicator: AnyObject {
    
    /// start communicator
    ///
    /// - Throws: if already started or shutdown.
    func start() throws
    
    /// shutdown communicator.
    func shutdown()
    
}
