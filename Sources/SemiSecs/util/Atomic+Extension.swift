//
//  Atomic+Extension.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/10/17.
//

import Foundation
import Synchronization

extension Atomic where Value == UInt16 {
    
    internal func incrementAndToBytes() -> [UInt8] {
        let (_, newValue) = self.wrappingAdd(1, ordering: .relaxed)
        return newValue.toBytes()
    }
    
}
