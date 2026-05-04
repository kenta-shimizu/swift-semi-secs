//
//  HSMSMessageReceivable.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/04/18.
//

/// Receivable HSMSMessage.
public protocol HSMSMessageReceivable: SECSPrimaryDataMessageReceivable {
    
    /// Whole HSMSMessage receive.
    var onDidReceiveWholeHSMSMessage: ((HSMSMessage) -> ())? { get set }
}
