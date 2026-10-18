//
//  UInt32+Extension.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/10/17.
//

import Foundation

extension UInt32 {
    
    internal init?(bytes: [UInt8]) {
        guard bytes.count == 4 else { return nil }
        self = (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
    }
    
}
