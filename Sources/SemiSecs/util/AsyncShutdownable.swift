//
//  AsyncShutdownable.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/11.
//

import Foundation

/// Shutdownable.
internal protocol AsyncShutdownable {
    
    /// Shutdown, release resources.
    func shutdown() async
}

/// AsyncShutdownError.
internal enum AsyncShutdownError: Error, Sendable {
    case alreadyShutdowned
}
