//
//  Duration+Extension.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/09/19.
//

import Foundation

extension Duration {
    
    internal func toPureSecondsString(fractionalLength: Int) -> String {
        let secondsDouble = Double(self.components.seconds) + Double(self.components.attoseconds) / 1e18
        return secondsDouble.formatted(.number.precision(.fractionLength(fractionalLength)))
    }
    
}
