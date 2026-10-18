//
//  UInt16+Extension.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/10/17.
//

import Foundation

extension UInt16 {
    
    internal init?(bytes: [UInt8]) {
        guard bytes.count == 2 else { return nil }
        self = (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
    }
    
    internal func toBytes() -> [UInt8] {
        return [
            UInt8((self >> 8) & 0xFF),
            UInt8(self & 0xFF)
        ]
    }
    
}
