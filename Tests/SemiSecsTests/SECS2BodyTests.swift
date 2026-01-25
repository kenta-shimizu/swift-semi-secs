//
//  SECS2BodyTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Testing
import SemiSecs

struct SECS2BodyTests {

    @Test func testSECS2BodyBinary() async throws {
        
        let secs2Body = SECS2Body(binary: [0x00, 0x01])
        
        #expect(secs2Body.itemType == .binary)
        #expect(secs2Body.count == 2)
        #expect(secs2Body.getUInt8(0) == 0x00)
        #expect(secs2Body.getUInt8(1) == 0x01)

    }
    
}
