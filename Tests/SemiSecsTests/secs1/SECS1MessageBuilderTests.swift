//
//  SECS1MessageBuilderTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/11/03.
//

import Testing
import Foundation
@testable import SemiSecs

struct SECS1MessageBuilderTests {
    
    private func builder(deviceId: UInt16, isEquipment: Bool) -> SECS1MessageBuilder {
        let builder = SECS1MessageBuilder()
        builder.deviceId = { deviceId }
        builder.isEquipment = { isEquipment }
        return builder
    }
    
    @Test func testBuildPrimaryAndResponseMessage() async throws {
        let deviceId: UInt16 = 100
        let hostBuilder = builder(deviceId: deviceId, isEquipment: false)
        let equipBuilder = builder(deviceId: deviceId, isEquipment: true)
        
        let rcmd = "START"
        let ack: UInt8 = 0x00
        
        let s2f21 = hostBuilder.buildPrimaryData(stream: 2, function: 21, wbit: true, secs2Body: SECS2Body(ascii: rcmd))
        let s2f22 = equipBuilder.buildResponseData(primaryMessage: s2f21, stream: 2, function: 22, wbit: false, secs2Body: SECS2Body(binary: Data([ack])))
        
        #expect(s2f21.deviceId == deviceId)
        #expect(s2f21.stream == 2)
        #expect(s2f21.function == 21)
        #expect(s2f21.rbit == false)
        #expect(s2f21.wbit == true)
        #expect(s2f21.secs2Body?.type == .ascii)
        #expect(s2f21.secs2Body?.stringValue() == rcmd)
        #expect(s2f21.header10Bytes[6] == 0x00)
        #expect(s2f21.header10Bytes[7] == 0x00)
        #expect(s2f21.isDataMessage == true)
        
        #expect(s2f22.deviceId == deviceId)
        #expect(s2f22.stream == 2)
        #expect(s2f22.function == 22)
        #expect(s2f22.rbit == true)
        #expect(s2f22.wbit == false)
        #expect(s2f22.secs2Body?.type == .binary)
        #expect(s2f22.secs2Body?.count == 1)
        #expect(s2f22.secs2Body?.uint8Value(at: 0) == ack)
        #expect(s2f22.isDataMessage == true)
        
        #expect(s2f21.system4BytesKeyValue == s2f22.system4BytesKeyValue)
        
    }
    
    @Test func testBuildPrimaryAndResponseMessageBySML() async throws {
        let deviceId: UInt16 = 200
        let equipBuilder = builder(deviceId: deviceId, isEquipment: true)
        let hostBuilder = builder(deviceId: deviceId, isEquipment: false)
        
        let deviceIds = deviceId.toBytes()
        let smlS2F17 = "S2F17 W."
        let smlS2F18 = "S2F18 <A \"120123012345\">."
        
        let s2f17 = equipBuilder.buildPrimaryData(smlMessage: try! SMLMessageParser.shared.parse(smlS2F17))
        let s2f18 = hostBuilder.buildResponseData(primaryMessage: s2f17, smlMessage: try! SMLMessageParser.shared.parse(smlS2F18))
        
        #expect(s2f17.deviceId == deviceId)
        #expect(s2f17.stream == 2)
        #expect(s2f17.function == 17)
        #expect(s2f17.rbit == true)
        #expect(s2f17.wbit == true)
        #expect(s2f17.secs2Body == nil)
        #expect(s2f17.header10Bytes[6] == deviceIds[0])
        #expect(s2f17.header10Bytes[7] == deviceIds[1])
        #expect(s2f17.isDataMessage == true)
        
        #expect(s2f18.deviceId == deviceId)
        #expect(s2f18.stream == 2)
        #expect(s2f18.function == 18)
        #expect(s2f18.rbit == false)
        #expect(s2f18.wbit == false)
        #expect(s2f18.secs2Body?.type == .ascii)
        #expect(s2f18.secs2Body?.count == 12)
        #expect(s2f18.secs2Body?.stringValue() == "120123012345")
        #expect(s2f18.isDataMessage == true)
        
        #expect(s2f17.system4BytesKeyValue == s2f18.system4BytesKeyValue)
        
    }
    
}
