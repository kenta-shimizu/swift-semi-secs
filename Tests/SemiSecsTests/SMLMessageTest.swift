//
//  SMLMessageTest.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Testing
import SemiSecs

struct SMLMessageTest {

    @Test func testSMLMessage() async throws {
        
        let s = SMLMessage(stream: 1, function: 2, wbit: false)
        
        #expect(s.stream == 1)
        #expect(s.function == 2)
        #expect(s.wbit == false)
        
        
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        
        
    }

}
