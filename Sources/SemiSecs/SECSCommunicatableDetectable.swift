//
//  SECSCommunicatableDetectable.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/05/05.
//

import Foundation

/// SECS-Communicatable detectable.
public protocol SECSCommunicatableDetectable {
    
    var onDidUpdateCommunicatable: ((Bool) -> Void)? { get set }
    
    func untilCommunicatable() async throws
    
    func untilNotCommunicatable() async throws
    
    func untilCommunicatable(timeout: Duration) async throws -> Bool
    
    func untilNotCommunicatable(timeout: Duration) async throws -> Bool
    
}
