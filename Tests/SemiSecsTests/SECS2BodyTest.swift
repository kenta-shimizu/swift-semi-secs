//
//  SECS2BodyTest.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Testing
import SemiSecs

struct SECS2BodyTest {

    @Test func testSECS2Body1() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        
        let ss = SECS2Body(binary: [0x00, 0x01])
        
        #expect(ss.itemType == .binary)
        #expect(ss.count == 2)
        
        
    }
    
}
