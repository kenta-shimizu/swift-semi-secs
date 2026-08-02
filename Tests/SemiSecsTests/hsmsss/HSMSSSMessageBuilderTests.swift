//
//  HSMSSSMessageBuilderTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/03/01.
//

import Testing
import Foundation
@testable import SemiSecs

struct HSMSSSMessageBuilderTests {
    
    private func builder(isEquipment: Bool) -> HSMSSSMessageBuilder {
        let builder = HSMSSSMessageBuilder()
        builder.isEquipment = {isEquipment}
        return builder
    }
    
    @Test func testBuildPrimaryData() async throws {
        
        let equipBuilder = builder(isEquipment: true)
        let secs2Body = SECS2BodyBuilder.shared.build(list: [])
        let message = equipBuilder.buildPrimaryData(sessionId: 0x1234, stream: 5, function: 1, wbit: false, secs2Body: secs2Body)
        
        #expect(message.header10Bytes[0] == 0x12)
        #expect(message.header10Bytes[1] == 0x34)
        #expect(message.header10Bytes[2] == 0x05)
        #expect(message.header10Bytes[3] == 0x01)
        #expect(message.header10Bytes[4] == 0x00)
        #expect(message.header10Bytes[5] == 0x00)
        #expect(message.header10Bytes[6] == 0x12)
        #expect(message.header10Bytes[7] == 0x34)
        #expect(message.secs2Body != nil)
        #expect(message.messageType == .data)
        #expect(message.isDataMessage == true)
        #expect(message.stream == 5)
        #expect(message.function == 1)
        #expect(message.wbit == false)
        
        #expect(message.data[0] == 0x00)
        #expect(message.data[1] == 0x00)
        #expect(message.data[2] == 0x00)
        #expect(message.data[3] == 0x0C)
        #expect(message.data[4] == 0x12)
        #expect(message.data[5] == 0x34)
        #expect(message.data[6] == 0x05)
        #expect(message.data[7] == 0x01)
        #expect(message.data[8] == 0x00)
        #expect(message.data[9] == 0x00)
        #expect(message.data[10] == 0x12)
        #expect(message.data[11] == 0x34)
        #expect(message.data[14] == 0x01)
        #expect(message.data[15] == 0x00)
        
    }
    
    @Test func testBuildPrimaryDataBySMLMessage() async throws {
        
        let hostBuilder = builder(isEquipment: false)
        let smlMessage = SMLMessage(stream: 1, function: 3, wbit: true)
        let message = hostBuilder.buildPrimaryData(sessionId: 0x1234, smlMessage: smlMessage)
        
        #expect(message.header10Bytes[0] == 0x12)
        #expect(message.header10Bytes[1] == 0x34)
        #expect(message.header10Bytes[2] == 0x81)
        #expect(message.header10Bytes[3] == 0x03)
        #expect(message.header10Bytes[4] == 0x00)
        #expect(message.header10Bytes[5] == 0x00)
        #expect(message.header10Bytes[6] == 0x00)
        #expect(message.header10Bytes[7] == 0x00)
        #expect(message.secs2Body == nil)
        #expect(message.messageType == .data)
        #expect(message.isDataMessage == true)
        #expect(message.stream == 1)
        #expect(message.function == 3)
        #expect(message.wbit == true)
        
        #expect(message.data[0] == 0x00)
        #expect(message.data[1] == 0x00)
        #expect(message.data[2] == 0x00)
        #expect(message.data[3] == 0x0A)
        #expect(message.data[4] == 0x12)
        #expect(message.data[5] == 0x34)
        #expect(message.data[6] == 0x81)
        #expect(message.data[7] == 0x03)
        #expect(message.data[8] == 0x00)
        #expect(message.data[9] == 0x00)
        #expect(message.data[10] == 0x00)
        #expect(message.data[11] == 0x00)
        
    }
    
    @Test func testBuildResponseData() async throws {
        
        let hostBuilder = builder(isEquipment: false)
        let primaryMessage = hostBuilder.buildPrimaryData(sessionId: 0x1234, stream: 1, function: 3, wbit: true)
        
        let equipBuilder = builder(isEquipment: true)
        let responseSECS2Body = SECS2BodyBuilder.shared.build(list: [])
        let message = equipBuilder.buildResponseData(primaryMessage: primaryMessage, stream: 1, function: 4, wbit: false, secs2Body: responseSECS2Body)
        
        #expect(message.header10Bytes[0] == 0x12)
        #expect(message.header10Bytes[1] == 0x34)
        #expect(message.header10Bytes[2] == 0x01)
        #expect(message.header10Bytes[3] == 0x04)
        #expect(message.header10Bytes[4] == 0x00)
        #expect(message.header10Bytes[5] == 0x00)
        #expect(message.header10Bytes[6] == 0x00)
        #expect(message.header10Bytes[7] == 0x00)
        #expect(message.header10Bytes[8] == primaryMessage.header10Bytes[8])
        #expect(message.header10Bytes[9] == primaryMessage.header10Bytes[9])
        #expect(message.secs2Body != nil)
        #expect(message.messageType == .data)
        #expect(message.isDataMessage == true)
        #expect(message.stream == 1)
        #expect(message.function == 4)
        #expect(message.wbit == false)

        #expect(message.data[0] == 0x00)
        #expect(message.data[1] == 0x00)
        #expect(message.data[2] == 0x00)
        #expect(message.data[3] == 0x0C)
        #expect(message.data[4] == 0x12)
        #expect(message.data[5] == 0x34)
        #expect(message.data[6] == 0x01)
        #expect(message.data[7] == 0x04)
        #expect(message.data[8] == 0x00)
        #expect(message.data[9] == 0x00)
        #expect(message.data[10] == 0x00)
        #expect(message.data[11] == 0x00)
        #expect(message.data[12] == primaryMessage.data[12])
        #expect(message.data[13] == primaryMessage.data[13])
        #expect(message.data[14] == 0x01)
        #expect(message.data[15] == 0x00)
        
    }
    
    @Test func testBuildResponseDataBySMLMessage() async throws {
        
        let equipBuilder = builder(isEquipment: true)
        let primarySECS2Body = SECS2BodyBuilder.shared.build(list: [])
        let primarySMLMessage = SMLMessage(stream: 6, function: 11, wbit: true, secs2Body: primarySECS2Body)
        let primaryMessage = equipBuilder.buildPrimaryData(sessionId: 0x1234, smlMessage: primarySMLMessage)
        
        let hostBuilder = builder(isEquipment: false)
        let responseSECS2Body = SECS2BodyBuilder.shared.build(binary: Data([0x00]))
        let responseSMLMessage = SMLMessage(stream: 6, function: 12, wbit: false, secs2Body: responseSECS2Body)
        let message = hostBuilder.buildResponseData(primaryMessage: primaryMessage, smlMessage: responseSMLMessage)
        
        #expect(message.header10Bytes[0] == 0x12)
        #expect(message.header10Bytes[1] == 0x34)
        #expect(message.header10Bytes[2] == 0x06)
        #expect(message.header10Bytes[3] == 0x0C)
        #expect(message.header10Bytes[4] == 0x00)
        #expect(message.header10Bytes[5] == 0x00)
        #expect(message.header10Bytes[6] == 0x12)
        #expect(message.header10Bytes[7] == 0x34)
        #expect(message.header10Bytes[8] == primaryMessage.header10Bytes[8])
        #expect(message.header10Bytes[9] == primaryMessage.header10Bytes[9])
        #expect(message.secs2Body != nil)
        #expect(message.messageType == .data)
        #expect(message.isDataMessage == true)
        #expect(message.stream == 6)
        #expect(message.function == 12)
        #expect(message.wbit == false)

        #expect(message.data[0] == 0x00)
        #expect(message.data[1] == 0x00)
        #expect(message.data[2] == 0x00)
        #expect(message.data[3] == 0x0D)
        #expect(message.data[4] == 0x12)
        #expect(message.data[5] == 0x34)
        #expect(message.data[6] == 0x06)
        #expect(message.data[7] == 0x0C)
        #expect(message.data[8] == 0x00)
        #expect(message.data[9] == 0x00)
        #expect(message.data[10] == 0x12)
        #expect(message.data[11] == 0x34)
        #expect(message.data[12] == primaryMessage.data[12])
        #expect(message.data[13] == primaryMessage.data[13])
        #expect(message.data[14] == 0x21)
        #expect(message.data[15] == 0x01)
        #expect(message.data[16] == 0x00)
        
    }
    
    @Test func testBuildSelectRequest() async throws {
        
        let builder = builder(isEquipment: false)
        let message = builder.buildSelectRequest(sessionId: 0x1234)
        
        #expect(message.header10Bytes[0] == 0xFF)
        #expect(message.header10Bytes[1] == 0xFF)
        #expect(message.header10Bytes[2] == 0x00)
        #expect(message.header10Bytes[3] == 0x00)
        #expect(message.header10Bytes[4] == 0x00)
        #expect(message.header10Bytes[5] == 0x01)
        #expect(message.header10Bytes[6] == 0x00)
        #expect(message.header10Bytes[7] == 0x00)
        #expect(message.secs2Body == nil)
        #expect(message.messageType == .selectRequest)
        #expect(message.isDataMessage == false)
        
        #expect(message.data.count == 14)
        #expect(message.data[0] == 0x00)
        #expect(message.data[1] == 0x00)
        #expect(message.data[2] == 0x00)
        #expect(message.data[3] == 0x0A)
        #expect(message.data[4] == 0xFF)
        #expect(message.data[5] == 0xFF)
        #expect(message.data[6] == 0x00)
        #expect(message.data[7] == 0x00)
        #expect(message.data[8] == 0x00)
        #expect(message.data[9] == 0x01)
        #expect(message.data[10] == 0x00)
        #expect(message.data[11] == 0x00)
        
    }

    @Test func testBuildSelectResponse() async throws {
        
        let hostBuilder = builder(isEquipment: false)
        let equipBuilder = builder(isEquipment: true)

        func xx(selectStatus: HSMSMessage.SelectStatus, statusByte: UInt8) {
            
            let selectRequest = hostBuilder.buildSelectRequest(sessionId: 0x1234)
            let message = equipBuilder.buildSelectResponse(selectRequest: selectRequest, selectStatus: selectStatus)
            
            #expect(message.header10Bytes[0] == 0xFF)
            #expect(message.header10Bytes[1] == 0xFF)
            #expect(message.header10Bytes[2] == 0x00)
            #expect(message.header10Bytes[3] == statusByte)
            #expect(message.header10Bytes[4] == 0x00)
            #expect(message.header10Bytes[5] == 0x02)
            #expect(message.header10Bytes[6] == selectRequest.header10Bytes[6])
            #expect(message.header10Bytes[7] == selectRequest.header10Bytes[7])
            #expect(message.header10Bytes[8] == selectRequest.header10Bytes[8])
            #expect(message.header10Bytes[9] == selectRequest.header10Bytes[9])
            #expect(message.secs2Body == nil)
            #expect(message.messageType == .selectResponse)
            #expect(message.isDataMessage == false)
            
            #expect(message.data.count == 14)
            #expect(message.data[0] == 0x00)
            #expect(message.data[1] == 0x00)
            #expect(message.data[2] == 0x00)
            #expect(message.data[3] == 0x0A)
            #expect(message.data[4] == 0xFF)
            #expect(message.data[5] == 0xFF)
            #expect(message.data[6] == 0x00)
            #expect(message.data[7] == statusByte)
            #expect(message.data[8] == 0x00)
            #expect(message.data[9] == 0x02)
            #expect(message.data[10] == selectRequest.data[10])
            #expect(message.data[11] == selectRequest.data[11])
            #expect(message.data[12] == selectRequest.data[12])
            #expect(message.data[13] == selectRequest.data[13])
        }
        
        xx(selectStatus: .success, statusByte: 0x00)
        xx(selectStatus: .actived, statusByte: 0x01)
        xx(selectStatus: .notReady, statusByte: 0x02)
        xx(selectStatus: .alreadyUsed, statusByte: 0x03)
        
    }
    
    @Test func testBuildDeselectRequest() async throws {
        
        let builder = builder(isEquipment: false)
        let message = builder.buildDeselectRequest(sessionId: 0x1234)
        
        #expect(message.header10Bytes[0] == 0xFF)
        #expect(message.header10Bytes[1] == 0xFF)
        #expect(message.header10Bytes[2] == 0x00)
        #expect(message.header10Bytes[3] == 0x00)
        #expect(message.header10Bytes[4] == 0x00)
        #expect(message.header10Bytes[5] == 0x03)
        #expect(message.header10Bytes[6] == 0x00)
        #expect(message.header10Bytes[7] == 0x00)
        #expect(message.secs2Body == nil)
        #expect(message.messageType == .deselectRequest)
        #expect(message.isDataMessage == false)
        
        #expect(message.data.count == 14)
        #expect(message.data[0] == 0x00)
        #expect(message.data[1] == 0x00)
        #expect(message.data[2] == 0x00)
        #expect(message.data[3] == 0x0A)
        #expect(message.data[4] == 0xFF)
        #expect(message.data[5] == 0xFF)
        #expect(message.data[6] == 0x00)
        #expect(message.data[7] == 0x00)
        #expect(message.data[8] == 0x00)
        #expect(message.data[9] == 0x03)
        #expect(message.data[10] == 0x00)
        #expect(message.data[11] == 0x00)
        
    }
    
    @Test func testBuildDeselectResponse() async throws {
        
        let hostBuilder = builder(isEquipment: false)
        let equipBuilder = builder(isEquipment: true)

        func xx(deselectStatus: HSMSMessage.DeselectStatus, statusByte: UInt8) {
            
            let deselectRequest = hostBuilder.buildDeselectRequest(sessionId: 0x1234)
            let message = equipBuilder.buildDeselectResponse(deselectRequest: deselectRequest, deselectStatus: deselectStatus)
            
            #expect(message.header10Bytes[0] == 0xFF)
            #expect(message.header10Bytes[1] == 0xFF)
            #expect(message.header10Bytes[2] == 0x00)
            #expect(message.header10Bytes[3] == statusByte)
            #expect(message.header10Bytes[4] == 0x00)
            #expect(message.header10Bytes[5] == 0x04)
            #expect(message.header10Bytes[6] == deselectRequest.header10Bytes[6])
            #expect(message.header10Bytes[7] == deselectRequest.header10Bytes[7])
            #expect(message.header10Bytes[8] == deselectRequest.header10Bytes[8])
            #expect(message.header10Bytes[9] == deselectRequest.header10Bytes[9])
            #expect(message.secs2Body == nil)
            #expect(message.messageType == .deselectResponse)
            #expect(message.isDataMessage == false)
            
            #expect(message.data.count == 14)
            #expect(message.data[0] == 0x00)
            #expect(message.data[1] == 0x00)
            #expect(message.data[2] == 0x00)
            #expect(message.data[3] == 0x0A)
            #expect(message.data[4] == 0xFF)
            #expect(message.data[5] == 0xFF)
            #expect(message.data[6] == 0x00)
            #expect(message.data[7] == statusByte)
            #expect(message.data[8] == 0x00)
            #expect(message.data[9] == 0x04)
            #expect(message.data[10] == deselectRequest.data[10])
            #expect(message.data[11] == deselectRequest.data[11])
            #expect(message.data[12] == deselectRequest.data[12])
            #expect(message.data[13] == deselectRequest.data[13])
        }
        
        xx(deselectStatus: .success, statusByte: 0x00)
        xx(deselectStatus: .noSelected, statusByte: 0x01)
        xx(deselectStatus: .failed, statusByte: 0x02)
        
    }
    
    @Test func testBuildLinktestRequest() async throws {
        
        let builder = builder(isEquipment: true)
        let message = builder.buildLinktestRequest(sessionId: 0x1234)
        
        #expect(message.header10Bytes[0] == 0xFF)
        #expect(message.header10Bytes[1] == 0xFF)
        #expect(message.header10Bytes[2] == 0x00)
        #expect(message.header10Bytes[3] == 0x00)
        #expect(message.header10Bytes[4] == 0x00)
        #expect(message.header10Bytes[5] == 0x05)
        #expect(message.header10Bytes[6] == 0x12)
        #expect(message.header10Bytes[7] == 0x34)
        #expect(message.secs2Body == nil)
        #expect(message.messageType == .linktestRequest)
        #expect(message.isDataMessage == false)
        
        #expect(message.data.count == 14)
        #expect(message.data[0] == 0x00)
        #expect(message.data[1] == 0x00)
        #expect(message.data[2] == 0x00)
        #expect(message.data[3] == 0x0A)
        #expect(message.data[4] == 0xFF)
        #expect(message.data[5] == 0xFF)
        #expect(message.data[6] == 0x00)
        #expect(message.data[7] == 0x00)
        #expect(message.data[8] == 0x00)
        #expect(message.data[9] == 0x05)
        #expect(message.data[10] == 0x12)
        #expect(message.data[11] == 0x34)
        
    }
    
    @Test func testBuildLinktestResponse() async throws {
        
        let equipBuilder = builder(isEquipment: true)
        let linktestRequest = equipBuilder.buildLinktestRequest(sessionId: 0x1234)
        let hostBuilder = builder(isEquipment: true)
        let message = hostBuilder.buildLinktestResponse(linktestRequest: linktestRequest)
        
        #expect(message.header10Bytes[0] == 0xFF)
        #expect(message.header10Bytes[1] == 0xFF)
        #expect(message.header10Bytes[2] == 0x00)
        #expect(message.header10Bytes[3] == 0x00)
        #expect(message.header10Bytes[4] == 0x00)
        #expect(message.header10Bytes[5] == 0x06)
        #expect(message.header10Bytes[6] == linktestRequest.header10Bytes[6])
        #expect(message.header10Bytes[7] == linktestRequest.header10Bytes[7])
        #expect(message.header10Bytes[8] == linktestRequest.header10Bytes[8])
        #expect(message.header10Bytes[9] == linktestRequest.header10Bytes[9])
        #expect(message.secs2Body == nil)
        #expect(message.messageType == .linktestResponse)
        #expect(message.isDataMessage == false)
        
        #expect(message.data.count == 14)
        #expect(message.data[0] == 0x00)
        #expect(message.data[1] == 0x00)
        #expect(message.data[2] == 0x00)
        #expect(message.data[3] == 0x0A)
        #expect(message.data[4] == 0xFF)
        #expect(message.data[5] == 0xFF)
        #expect(message.data[6] == 0x00)
        #expect(message.data[7] == 0x00)
        #expect(message.data[8] == 0x00)
        #expect(message.data[9] == 0x06)
        #expect(message.data[10] == linktestRequest.data[10])
        #expect(message.data[11] == linktestRequest.data[11])
        #expect(message.data[12] == linktestRequest.data[12])
        #expect(message.data[13] == linktestRequest.data[13])
        
    }
    
    @Test func testBuildRejectRequest() async throws {
        
        let hostBuilder = builder(isEquipment: false)
        let equipBuilder = builder(isEquipment: true)

        func xx(rejectReason: HSMSMessage.RejectReason, reasonByte: UInt8, byte2: UInt8) {
            
            let selectRequest = hostBuilder.buildSelectRequest(sessionId: 0x1234)
            let message = equipBuilder.buildRejectRequest(referenceMessage: selectRequest, rejectReason: rejectReason, byte2: byte2)
            
            #expect(message.header10Bytes[0] == 0xFF)
            #expect(message.header10Bytes[1] == 0xFF)
            #expect(message.header10Bytes[2] == byte2)
            #expect(message.header10Bytes[3] == reasonByte)
            #expect(message.header10Bytes[4] == 0x00)
            #expect(message.header10Bytes[5] == 0x07)
            #expect(message.header10Bytes[6] == selectRequest.header10Bytes[6])
            #expect(message.header10Bytes[7] == selectRequest.header10Bytes[7])
            #expect(message.header10Bytes[8] == selectRequest.header10Bytes[8])
            #expect(message.header10Bytes[9] == selectRequest.header10Bytes[9])
            #expect(message.secs2Body == nil)
            #expect(message.messageType == .rejectRequest)
            #expect(message.isDataMessage == false)
            
            #expect(message.data.count == 14)
            #expect(message.data[0] == 0x00)
            #expect(message.data[1] == 0x00)
            #expect(message.data[2] == 0x00)
            #expect(message.data[3] == 0x0A)
            #expect(message.data[4] == 0xFF)
            #expect(message.data[5] == 0xFF)
            #expect(message.data[6] == byte2)
            #expect(message.data[7] == reasonByte)
            #expect(message.data[8] == 0x00)
            #expect(message.data[9] == 0x07)
            #expect(message.data[10] == selectRequest.data[10])
            #expect(message.data[11] == selectRequest.data[11])
            #expect(message.data[12] == selectRequest.data[12])
            #expect(message.data[13] == selectRequest.data[13])
        }
        
        xx(rejectReason: .notSupportTypeS, reasonByte: 0x01, byte2: 0x0A)
        xx(rejectReason: .notSupportTypeP, reasonByte: 0x02, byte2: 0x0B)
        xx(rejectReason: .transactionNotOpen, reasonByte: 0x03, byte2: 0x0C)
        xx(rejectReason: .notSelected, reasonByte: 0x04, byte2: 0x0D)
        
    }
    
    @Test func testBuildSeparateRequest() async throws {
        
        let builder = builder(isEquipment: false)
        let message = builder.buildSeparateRequest(sessionId: 0x1234)
        
        #expect(message.header10Bytes[0] == 0xFF)
        #expect(message.header10Bytes[1] == 0xFF)
        #expect(message.header10Bytes[2] == 0x00)
        #expect(message.header10Bytes[3] == 0x00)
        #expect(message.header10Bytes[4] == 0x00)
        #expect(message.header10Bytes[5] == 0x09)
        #expect(message.header10Bytes[6] == 0x00)
        #expect(message.header10Bytes[7] == 0x00)
        #expect(message.secs2Body == nil)
        #expect(message.messageType == .separateRequest)
        #expect(message.isDataMessage == false)
        
        #expect(message.data.count == 14)
        #expect(message.data[0] == 0x00)
        #expect(message.data[1] == 0x00)
        #expect(message.data[2] == 0x00)
        #expect(message.data[3] == 0x0A)
        #expect(message.data[4] == 0xFF)
        #expect(message.data[5] == 0xFF)
        #expect(message.data[6] == 0x00)
        #expect(message.data[7] == 0x00)
        #expect(message.data[8] == 0x00)
        #expect(message.data[9] == 0x09)
        #expect(message.data[10] == 0x00)
        #expect(message.data[11] == 0x00)
        
    }
    
    @Test func testSystem4ByteAutoNumber() async throws {
        
        let builder = builder(isEquipment: false)
        let m1 = builder.buildSelectRequest(sessionId: 0x1234)
        let m2 = builder.buildSelectRequest(sessionId: 0x1234)
        let m3 = builder.buildSelectRequest(sessionId: 0x1234)
        
        #expect(m1.system4BytesKeyValue != m2.system4BytesKeyValue)
        #expect(m2.system4BytesKeyValue != m3.system4BytesKeyValue)
        #expect(m3.system4BytesKeyValue != m1.system4BytesKeyValue)
        
    }

}
