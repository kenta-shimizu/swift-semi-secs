//
//  SECS1Communicator.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/11/03.
//

import Foundation

/// SECS1Error.
public protocol SECS1Error: SECSError {
}

/// SECS1SendError.
public enum SECS1SendError: SECSSendError, SECS1Error {
    
    case sendFailed(message: SECS1Message, cause: Error)
    case sendFailedByCommunicatorShutdowned(message: SECS1Message?)
    case sendFailedByNotConnected(message: SECS1Message)
    case sendFailedByRetryOver(message: SECS1Message)
    
    public var description: String {
        let type = String(describing: type(of: self))
        
        switch self {
        case .sendFailed(let message, let cause):
            return "\(type).sendFailed, message: \(message.header10BytesString), cause: \(cause)"
            
        case .sendFailedByCommunicatorShutdowned(let message):
            var r = "\(type).sendFailedByCommunicatorShutdowned"
            if let message = message {
                r.append(", message: \(message.header10BytesString)")
            }
            return r
            
        case .sendFailedByNotConnected(let message):
            return "\(type).sendFailedByNotConnected, message: \(message.header10BytesString)"
            
        case .sendFailedByRetryOver(let message):
            return "\(type).sendFailedByRetryOver, message: \(message.header10BytesString)"
        }
    }
    
    public var debugDescription: String {
        return self.description;
    }
}

/// SECS1WaitReplyError.
public enum SECS1WaitReplyError: SECSWaitReplyError, SECS1Error {
    
    case waitReplyFailedByTransactionShutdown(primaryMessage: SECS1Message)
    case timeoutT3(primaryMessage: SECS1Message)
    
    public var description: String {
        let type = String(describing: type(of: self))
        
        switch self {
        case .waitReplyFailedByTransactionShutdown(let primaryMessage):
            return "\(type).waitReplyFailedByTransactionShutdown, primaryMessage: \(primaryMessage.header10BytesString)"
            
        case .timeoutT3(let primaryMessage):
            return "\(type).timeoutT3, primaryMessage: \(primaryMessage.header10BytesString)"
        }
    }
    
    public var debugDescription: String {
        return self.description;
    }
}

/// SECS1 config.
public protocol SECS1CommunicatorConfig: SECSCommunicatorConfig {
    
    /// Device-ID
    var deviceId: UInt16 { get set }
    
    /// Master/Slave, Returns true if Master, false if Slave
    var isMaster: Bool { get set }
    
    /// Retry
    var retry: UInt { get set }
    
}

/// SECS1Communicator
public protocol SECS1Communicator: SECSCommunicator {
    
}
