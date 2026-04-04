//
//  SMLMessage.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Foundation

/// SMLMessage
public struct SMLMessage: CustomStringConvertible, Sendable {
    
    /// Stream-Number, Readonly.
    public private(set) var stream: UInt8
    
    /// Function-Number Readonly.
    public private(set) var function: UInt8
    
    /// W-Bit Readonly.
    public private(set) var wbit: Bool
    
    /// SECS-II-Body Readonly.
    public private(set) var secs2Body: (any SECS2Body)?
    
    public init(stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2Body)? = nil) {
        guard (0...127).contains(stream) else {
            fatalError("stream is in (0...127). stream: \"\(stream)\"")
        }
        self.stream = stream
        self.function = function
        self.wbit = wbit
        self.secs2Body = secs2Body
    }
    
    private static let lineSeparator = "\n"
    private static let endMessage = "."
    
    public var description: String {
        var r = "S\(self.stream)F\(self.function)"
        if self.wbit {
            r += " W"
        }
        if let secs2BodySmlString = self.secs2Body?.smlString {
            r += Self.lineSeparator + secs2BodySmlString + Self.endMessage
        } else {
            r += Self.endMessage
        }
        return r
    }

}

