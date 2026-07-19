//
//  HSMSCommunicator.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Foundation
import Network

/// HSMSError.
public protocol HSMSError: SECSError {
}

/// HSMSSendError.
public enum HSMSSendError: SECSSendError, HSMSError {
    
    case sendFailed(message: HSMSMessage, connection: NWConnection, cause: Error)
    case sendFailedByCommunicatorShutdowned(message: HSMSMessage?, connection: NWConnection?)
    case sendFailedByNotConnected(message: HSMSMessage)
    
    public var description: String {
        return String(describing: type(of: self))
    }
    
    public var debugDescription: String {
        return self.description;
    }
}

/// HSMSWaitReplyError.
public enum HSMSWaitReplyError: SECSWaitReplyError, HSMSError {
    
    case waitReplyFailedByTransactionShutdown(primaryMessage: HSMSMessage, connection: NWConnection)
    case timeoutT3(primaryMessage: HSMSMessage, connection: NWConnection)
    case timeoutT6(primaryMessage: HSMSMessage, connection: NWConnection)
    case rejectRequest(primaryMessage: HSMSMessage, rejectRequestMessage: HSMSMessage, connection: NWConnection)
    
    public var description: String {
        return String(describing: type(of: self))
    }
    
    public var debugDescription: String {
        return self.description;
    }
}

/// HSMSReceiveError.
public enum HSMSReceiveError: SECSReceiveError, HSMSError, Error {
    
    case timeoutT8
    case illegalReceiveLengthByte
    
    public var description: String {
        return String(describing: type(of: self))
    }
    
    public var debugDescription: String {
        return self.description;
    }
}

/// HSMS Connection mode.
public enum HSMSConnectionMode: Sendable {
    case active
    case passive
}

/// HSMS config.
public protocol HSMSCommunicatorConfig: SECSCommunicatorConfig {
    
    /// HSMS connection mode.
    var connectionMode: HSMSConnectionMode { get set }
    
    /// TCP/IP IP Address, connect or bind.
    var ipAddress: NWEndpoint.Host? { get set }
    
    /// TCP/IP Port, connect or bind
    var port: NWEndpoint.Port { get set }
    
    /// passive rebind time interval.
    var rebindDuration: Duration { get set }
    
    /// auto Linktest.
    var autoLinktest: Bool { get set }

    /// Linktest time interval.
    var linktestDuration: Duration { get set }
    
}

public protocol HSMSCommunicator: SECSCommunicator, HSMSMessageReceivable {
    
}
