//
//  HSMSMessageDecoder.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/03/06.
//

import Foundation

/// HSMS Message decordable
public protocol HSMSMessageDecodable {
    
    /// Decode Data to HSMSMessage.
    ///
    /// - Parameters:
    ///   - header10Bytes: Header 10 bytes Data
    ///   - secs2BodyData: SECS-II Body Data
    /// - Returns: HSMSMessage
    func decode(header10Bytes: Data, secs2BodyData: Data) -> HSMSMessage
}

public extension HSMSMessageDecodable {
    
    func decode(header10Bytes: Data, secs2BodyData: Data) -> HSMSMessage {
        let secs2Body = SECS2BodyDecoder.shared.decode(secs2BodyData)
        return HSMSMessage(header10Bytes: header10Bytes, secs2Body: secs2Body)
    }
    
}

public final class HSMSMessageDecoder: HSMSMessageDecodable, Sendable {
    
    public  static let shared = HSMSMessageDecoder()
    
    private init() {
        // Nothing
    }
    
}
