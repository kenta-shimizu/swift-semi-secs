//
//  HSMSGSMessageBuilderTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/03/01.
//

import Testing
import SemiSecs

struct HSMSGSMessageBuilderTests {
    
    func builder(isEquipment: Bool) -> HSMSGSMessageBuilder {
        let builder = HSMSGSMessageBuilder()
        builder.isEquipmentDelegate = {isEquipment}
        return builder
    }
    
    
    // data
    // select.req
    // select.rsp
    // deselect.req
    // deselect.rsp
    // linktest.req
    // linktest.rsp
    // reject.req
    // separate.req
    
    
    @Test func testA() async throws {
        
        let builder = builder(isEquipment: true)
        
        
        
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}
