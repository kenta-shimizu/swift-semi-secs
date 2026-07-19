//
//  Logger+Extension.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/07/15.
//

import Foundation
import os

extension Logger {
    
    private static let subsystem = "com.shimizukenta.swift-semi-secs"
    
    internal static let nwConnection = Logger(subsystem: subsystem, category: "NWConnection")
    internal static let communicator = Logger(subsystem: subsystem, category: "communicator")
    internal static let hsmsConnectionState = Logger(subsystem: subsystem, category: "HSMSConnectionState")
    internal static let receiveHSMSMessage = Logger(subsystem: subsystem, category: "receiveHSMSMessage")
    internal static let sendedHSMSMessage = Logger(subsystem: subsystem, category: "sendedHSMSMessage")
    
}
