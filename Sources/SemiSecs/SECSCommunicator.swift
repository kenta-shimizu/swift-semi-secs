//
//  SecsCommunicator.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Foundation

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
    
    private var _t1: Duration
    private var _t2: Duration
    private var _t3: Duration
    private var _t4: Duration
    private var _t5: Duration
    private var _t6: Duration
    private var _t7: Duration
    private var _t8: Duration
    
    public init() {
        self._t1 = .seconds(1.0)
        self._t2 = .seconds(15.0)
        self._t3 = .seconds(45.0)
        self._t4 = .seconds(45.0)
        self._t5 = .seconds(10.0)
        self._t6 = .seconds(5.0)
        self._t7 = .seconds(10.0)
        self._t8 = .seconds(6.0)
    }
    
    /// Timeout-T1
    public var t1: Duration {
        get {
            return self._t1
        }
        set {
            guard newValue > .zero else {
                fatalError("t1 set value >0.0")
            }
            self._t1 = newValue
        }
    }
    
    /// Timeout-T2
    public var t2: Duration {
        get {
            return self._t2
        }
        set {
            guard newValue > .zero else {
                fatalError("t2 set value >0.0")
            }
            self._t2 = newValue
        }
    }
    
    /// Timeout-T3
    public var t3: Duration {
        get {
            return self._t3
        }
        set {
            guard newValue > .zero else {
                fatalError("t3 set value >0.0")
            }
            self._t3 = newValue
        }
    }
    
    /// Timeout-T4
    public var t4: Duration {
        get {
            return self._t4
        }
        set {
            guard newValue > .zero else {
                fatalError("t4 set value >0.0")
            }
            self._t4 = newValue
        }
    }
    
    /// Timeout-T5
    public var t5: Duration {
        get {
            return self._t5
        }
        set {
            guard newValue > .zero else {
                fatalError("t5 set value >0.0")
            }
            self._t5 = newValue
        }
    }
    
    /// Timeout-T6
    public var t6: Duration {
        get {
            return self._t6
        }
        set {
            guard newValue > .zero else {
                fatalError("t6 set value >0.0")
            }
            self._t6 = newValue
        }
    }
    
    /// Timeout-T7
    public var t7: Duration {
        get {
            return self._t7
        }
        set {
            guard newValue > .zero else {
                fatalError("t7 set value >0.0")
            }
            self._t7 = newValue
        }
    }
    
    /// Timeout-T8
    public var t8: Duration {
        get {
            return self._t8
        }
        set {
            guard newValue > .zero else {
                fatalError("t8 set value >0.0")
            }
            self._t8 = newValue
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

public protocol SECSCommunicator {
    
    /// start communicator
    ///
    /// - Throws: if already started or shutdown.
    func start() throws
    
    /// shutdown communicator.
    func shutdown()
    
}

public enum SECSCommunicatorStartAndShutdownError: SECSCommunicatorError {
    
    case alreadyStarted
    case alreadyShutdown
    
    public var description: String {
        let type = String(describing: type(of: self))
        
        switch self {
        case .alreadyStarted:
            return "\(type).alreadyStarted"
            
        case .alreadyShutdown:
            return "\(type).alreadyShutdown"
        }
    }
    
    public var debugDescription: String {
        return self.description;
    }
}

/// StartAndShutdonw marking.
internal final class StartAndShutdown: Sendable {
    
    private let lockQueue = DispatchQueue(label: "StartAndShutdown")
    private nonisolated(unsafe) var started: Bool
    private nonisolated(unsafe) var shutdowned: Bool
    
    internal init() {
        self.started = false
        self.shutdowned = false
    }
    
    /// Mark start, throws if already started or shutdown.
    ///
    /// - Throws:
    ///   - SECSCommunicatorStartAndShutdownError.alreadyShutdowned: if already shutdown.
    ///   - SECSCommunicatorStartAndShutdownError.alreadyStarted:  if already started.
    internal func start() throws {
        try lockQueue.sync {
            guard self.shutdowned == false else {
                throw SECSCommunicatorStartAndShutdownError.alreadyShutdown
            }
            guard self.started == false else {
                throw SECSCommunicatorStartAndShutdownError.alreadyStarted
            }
            self.started = true
        }
    }
    
    /// Mark shutdown, returns true if already shutdown, otherwise false.
    ///
    /// - Returns: true if already shutdown, otherwise false.
    @discardableResult
    internal func shutdown() -> Bool {
        lockQueue.sync {
            let prev = self.shutdowned
            self.shutdowned = true
            return prev
        }
    }
    
}
