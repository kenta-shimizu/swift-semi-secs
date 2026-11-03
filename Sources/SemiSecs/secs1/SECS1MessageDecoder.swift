//
//  SECS1MessageDecoder.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/11/02.
//

import Foundation

/// SECS-I Message decodable
public protocol SECS1MessageDecodable: AnyObject {
    
    /// Decode to SECS1Message
    ///
    /// - Parameters:
    ///   - blocks: SECS1Message.Block Array
    /// - Returns: SECS1Message
    func decode(_ blocks: [SECS1Message.Block]) -> SECS1Message
}

extension SECS1MessageDecodable {
    
    public func decode(_ blocks: [SECS1Message.Block]) -> SECS1Message {
        
        var last: SECS1Message.Block? = nil
        var bodyDatas: [Data.SubSequence] = []
        
        for block in blocks {
            guard block.validLength,
                  block.sumCheck else {
                continue
            }
            
            if let last = last {
                guard last.ebit == false,
                      last.isNext(block: block) else {
                    continue
                }
            }
            
            last = block
            bodyDatas.append(block.data.dropFirst(11).dropLast(2))
        }
        
        let secs2Body = SECS2BodyDecoder.shared.decode(Data(bodyDatas.joined()))
        
        return SECS1Message(secs2Body: secs2Body, blocks: blocks)
    }
}

/// SECS-I Message decoder
public final class SECS1MessageDecoder: SECS1MessageDecodable, Sendable {
    
    public  static let shared = SECS1MessageDecoder()
    
    private init() {
        // Nothing
    }
    
}
