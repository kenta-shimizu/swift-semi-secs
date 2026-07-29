//
//  HSMSMessageReceivable.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/04/18.
//

import Network

/// Receivable HSMSMessage.
public protocol HSMSMessageReceivable {
    
    /// Whole HSMSMessage receive.
    var didReceiveWholeHSMSMessage: ((HSMSMessage, NWConnection) -> Void)? { get set }
}
