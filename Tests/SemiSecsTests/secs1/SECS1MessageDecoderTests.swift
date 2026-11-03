//
//  SECS1MessageDecoderTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/11/02.
//

import Testing
import Foundation
import SemiSecs

struct SECS1MessageDecoderTests {
    
    private func decode(_ datas: [Data]) -> SECS1Message {
        return SECS1MessageDecoder.shared.decode(datas.map { SECS1Message.Block(data: $0)! })
    }
    
    @Test func testDecodeNil() async throws {
        
        let s1m = decode([
            Data([0x0A, 0x00, 0x01, 0x81, 0x01, 0x80, 0x01, 0x00, 0x00, 0x00, 0x01, 0x01, 0x05])
        ])
        
        #expect(s1m.secs2Body == nil)
    }
    
    @Test func testDecodeSingleBlock() async throws {
        
        let s1m = decode([
            Data([0x0C, 0x00, 0x01, 0x81, 0x03, 0x80, 0x01, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01, 0x08])
        ])
        
        #expect(s1m.deviceId == 1)
        #expect(s1m.stream == 1)
        #expect(s1m.function == 3)
        #expect(s1m.wbit == true)
        #expect(s1m.secs2Body?.type == .list)
        #expect(s1m.secs2Body?.count == 0)
    }
    
    @Test func testDecodeMultiBlock() async throws {
        
        let s1m = decode([
            Data([0x0B, 0x00, 0x01, 0x81, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x88]),
            Data([0x0B, 0x00, 0x01, 0x81, 0x03, 0x80, 0x02, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x08])
        ])
        
        #expect(s1m.deviceId == 1)
        #expect(s1m.stream == 1)
        #expect(s1m.function == 3)
        #expect(s1m.wbit == true)
        #expect(s1m.secs2Body?.type == .list)
        #expect(s1m.secs2Body?.count == 0)
    }
    
    @Test func testDecodeError() async throws {
        
        let invalidLength = Data([0xFE, 0x00, 0x01, 0x81, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x88])
        
        let sumCheckError = Data([0x0B, 0x00, 0x01, 0x81, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x01, 0xFF, 0xFF])
        
        let firstBlock = Data([0x0B, 0x00, 0x01, 0x81, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x88])
        
        let endBlock = Data([0x0B, 0x00, 0x01, 0x81, 0x03, 0x80, 0x02, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x08])
        
        let s1m = decode([
            invalidLength,
            sumCheckError,
            firstBlock,
            firstBlock, // NOT next-block
            endBlock,
            endBlock    // already-end
        ])
        
        #expect(s1m.deviceId == 1)
        #expect(s1m.stream == 1)
        #expect(s1m.function == 3)
        #expect(s1m.wbit == true)
        #expect(s1m.secs2Body?.type == .list)
        #expect(s1m.secs2Body?.count == 0)
    }

}
