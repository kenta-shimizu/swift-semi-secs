//
//  SECSMessageReceivable.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/04/18.
//

/// Receivable Primary-Data-Message.
public protocol SECSMessageReceivable {
    
    /// Primary-Data-Message receive.
    var didReceivePrimaryDataSECSMessage: ((any SECSMessage) -> Void)? { get set }
    
}
