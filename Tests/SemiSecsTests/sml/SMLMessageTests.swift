//
//  SMLMessageTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/03/08.
//

import Testing
import Foundation
import SemiSecs

struct SMLMessageTests {
    
    @Test func testSMLMessage() async throws {
        
        let smlMessage = SMLMessage(stream: 1, function: 2, wbit: false, secs2Body: nil)
        
        #expect(smlMessage.stream == 1)
        #expect(smlMessage.function == 2)
        #expect(smlMessage.wbit == false)
        #expect(smlMessage.secs2Body == nil)
    }
    
}
