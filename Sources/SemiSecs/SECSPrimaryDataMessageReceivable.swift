//
//  SECSPrimaryDataMessageReceivable.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/04/18.
//

/// Receivable Primary-Data-Message.
public protocol SECSPrimaryDataMessageReceivable {
    
    /// Primary-Data-Message receive.
    var onDidReceiveSECSPrimaryDataMessage: ((any SECSMessage) -> ())? { get set }
    
}
