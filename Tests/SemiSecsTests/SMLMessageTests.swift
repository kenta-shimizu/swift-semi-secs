//
//  SMLMessageTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Testing
import SemiSecs

struct SMLMessageTests {

    @Test func testSMLMessage() async throws {
        
        let smlMessage = SMLMessage(stream: 1, function: 2, wbit: false)
        
        #expect(smlMessage.stream == 1)
        #expect(smlMessage.function == 2)
        #expect(smlMessage.wbit == false)
        #expect(smlMessage.secs2Body == nil)
    }
    
    @Test func testParseSMLMessageNonSECS2Body() async throws {
        
        let string = "S3F1 W."
        
        let parser = SMLMessageParser()
        
        let result = parser.parse(string)
        
        switch result {
        case .success(let smlMessage):
            #expect(smlMessage.stream == 3)
            #expect(smlMessage.function == 1)
            #expect(smlMessage.wbit == true)
            #expect(smlMessage.secs2Body == nil)

        case .failure(let error):
            throw error
        }
        
    }
    
    @Test func testParseSMLMessageExistSECS2Body() async throws {
        
        let string = "S1F2 <L>."
        
        let parser = SMLMessageParser()
        
        let result = parser.parse(string)
        
        switch result {
        case .success(let smlMessage):
            #expect(smlMessage.stream == 1)
            #expect(smlMessage.function == 2)
            #expect(smlMessage.wbit == false)
            #expect(smlMessage.secs2Body != nil)
            
            if let secs2Body = smlMessage.secs2Body {
                #expect(secs2Body.itemType == .list)
                #expect(secs2Body.count == 0)
            }

        case .failure(let error):
            throw error
        }
        
    }
    
}
