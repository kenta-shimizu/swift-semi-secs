//
//  HSMSMessageDecoderTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/03/01.
//

import Testing
import Foundation
import SemiSecs

struct  HSMSMessageDecoderTests {
    
    @Test func testDecodeDataSECS2BodyNone() async throws {
        
        let header10Bytes = Data([0x01, 0x02, 0x83, 0x04, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04])
        let secs2Body = Data([])
        
        let message = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message.messageType == .data)
        #expect(message.sessionId == 0x0102)
        #expect(message.stream == 0x03)
        #expect(message.function == 0x04)
        #expect(message.wbit == true)
        #expect(message.secs2Body == nil)
        #expect(message.isDataMessage == true)
        #expect(message.system4BytesKeyValue == 0x01020304)
        #expect(message.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x83, 0x04, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04]))
    }
    
    @Test func testDecodeDataSECS2BodyList0() async throws {
        
        let header10Bytes = Data([0x11, 0x22, 0x33, 0x44, 0x00, 0x00, 0x11, 0x22, 0x33, 0x44])
        let secs2Body = Data([0x01, 0x00])
        
        let message = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message.messageType == .data)
        #expect(message.sessionId == 0x1122)
        #expect(message.stream == 0x33)
        #expect(message.function == 0x44)
        #expect(message.wbit == false)
        #expect(message.secs2Body != nil)
        #expect(message.secs2Body!.type == .list)
        #expect(message.secs2Body!.count == 0)
        #expect(message.isDataMessage == true)
        #expect(message.system4BytesKeyValue == 0x11223344)
        #expect(message.data == Data([0x00, 0x00, 0x00, 0x0C, 0x11, 0x22, 0x33, 0x44, 0x00, 0x00, 0x11, 0x22, 0x33, 0x44, 0x01, 0x00]))
    }
    
    @Test func testDecodeSelectRequest() async throws {
        
        let header10Bytes = Data([0x01, 0x02, 0x00, 0x00, 0x00, 0x01, 0x01, 0x02, 0x03, 0x04])
        let secs2Body = Data([])
        
        let message = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message.messageType == .selectRequest)
        #expect(message.secs2Body == nil)
        #expect(message.isDataMessage == false)
        #expect(message.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x00, 0x00, 0x00, 0x01, 0x01, 0x02, 0x03, 0x04]))
    }
    
    @Test func testDecodeSelectResponse() async throws {
        
        var header10Bytes = Data([0x01, 0x02, 0x00, 0x00, 0x00, 0x02, 0x01, 0x02, 0x03, 0x04])
        let secs2Body = Data([])
        
        // success
        header10Bytes[3] = 0x00
        let message0 = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message0.messageType == .selectResponse)
        #expect(HSMSMessage.SelectStatus(hsmsSelectRespnseMessage: message0) == .success)
        #expect(message0.secs2Body == nil)
        #expect(message0.isDataMessage == false)
        #expect(message0.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x00, 0x00, 0x00, 0x02, 0x01, 0x02, 0x03, 0x04]))
        
        // actived
        header10Bytes[3] = 0x01
        let message1 = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message1.messageType == .selectResponse)
        #expect(HSMSMessage.SelectStatus(hsmsSelectRespnseMessage: message1) == .actived)
        #expect(message1.secs2Body == nil)
        #expect(message1.isDataMessage == false)
        #expect(message1.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x00, 0x01, 0x00, 0x02, 0x01, 0x02, 0x03, 0x04]))
        
        // notReady
        header10Bytes[3] = 0x02
        let message2 = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message2.messageType == .selectResponse)
        #expect(HSMSMessage.SelectStatus(hsmsSelectRespnseMessage: message2) == .notReady)
        #expect(message2.secs2Body == nil)
        #expect(message2.isDataMessage == false)
        #expect(message2.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x00, 0x02, 0x00, 0x02, 0x01, 0x02, 0x03, 0x04]))
        
        // alreadyUsed
        header10Bytes[3] = 0x03
        let message3 = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message3.messageType == .selectResponse)
        #expect(HSMSMessage.SelectStatus(hsmsSelectRespnseMessage: message3) == .alreadyUsed)
        #expect(message3.secs2Body == nil)
        #expect(message3.isDataMessage == false)
        #expect(message3.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x00, 0x03, 0x00, 0x02, 0x01, 0x02, 0x03, 0x04]))
        
        // entityUnknown
        header10Bytes[3] = 0x04
        let message4 = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message4.messageType == .selectResponse)
        #expect(HSMSMessage.SelectStatus(hsmsSelectRespnseMessage: message4) == .entityUnknown)
        #expect(message4.secs2Body == nil)
        #expect(message4.isDataMessage == false)
        #expect(message4.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x00, 0x04, 0x00, 0x02, 0x01, 0x02, 0x03, 0x04]))
        
        // entityAlreadyUsed
        header10Bytes[3] = 0x05
        let message5 = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message5.messageType == .selectResponse)
        #expect(HSMSMessage.SelectStatus(hsmsSelectRespnseMessage: message5) == .entityAlreadyUsed)
        #expect(message5.secs2Body == nil)
        #expect(message5.isDataMessage == false)
        #expect(message5.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x00, 0x05, 0x00, 0x02, 0x01, 0x02, 0x03, 0x04]))
        
        // entityActived
        header10Bytes[3] = 0x06
        let message6 = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message6.messageType == .selectResponse)
        #expect(HSMSMessage.SelectStatus(hsmsSelectRespnseMessage: message6) == .entityActived)
        #expect(message6.secs2Body == nil)
        #expect(message6.isDataMessage == false)
        #expect(message6.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x00, 0x06, 0x00, 0x02, 0x01, 0x02, 0x03, 0x04]))
        
        // unknown
        header10Bytes[3] = 0x81
        let messageFF = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(messageFF.messageType == .selectResponse)
        #expect(HSMSMessage.SelectStatus(hsmsSelectRespnseMessage: messageFF) == .unknown)
        #expect(messageFF.secs2Body == nil)
        #expect(messageFF.isDataMessage == false)
        #expect(messageFF.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x00, 0x81, 0x00, 0x02, 0x01, 0x02, 0x03, 0x04]))

        
    }
    
    @Test func testDecodeDeselectRequest() async throws {
        
        let header10Bytes = Data([0x01, 0x02, 0x00, 0x00, 0x00, 0x03, 0x01, 0x02, 0x03, 0x04])
        let secs2Body = Data([])
        
        let message = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message.messageType == .deselectRequest)
        #expect(message.secs2Body == nil)
        #expect(message.isDataMessage == false)
        #expect(message.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x00, 0x00, 0x00, 0x03, 0x01, 0x02, 0x03, 0x04]))
    }
    
    @Test func testDecodeDeselectResponse() async throws {
        
        var header10Bytes = Data([0x01, 0x02, 0x00, 0x00, 0x00, 0x04, 0x01, 0x02, 0x03, 0x04])
        let secs2Body = Data([])
        
        // success
        header10Bytes[3] = 0x00
        let message0 = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message0.messageType == .deselectResponse)
        #expect(HSMSMessage.DeselectStatus(hsmsDeselectRespnseMessage: message0) == .success)
        #expect(message0.secs2Body == nil)
        #expect(message0.isDataMessage == false)
        #expect(message0.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x00, 0x00, 0x00, 0x04, 0x01, 0x02, 0x03, 0x04]))
        
        // not-selected
        header10Bytes[3] = 0x01
        let message1 = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message1.messageType == .deselectResponse)
        #expect(HSMSMessage.DeselectStatus(hsmsDeselectRespnseMessage: message1) == .noSelected)
        #expect(message1.secs2Body == nil)
        #expect(message1.isDataMessage == false)
        #expect(message1.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x00, 0x01, 0x00, 0x04, 0x01, 0x02, 0x03, 0x04]))
        
        // failed
        header10Bytes[3] = 0x02
        let message2 = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message2.messageType == .deselectResponse)
        #expect(HSMSMessage.DeselectStatus(hsmsDeselectRespnseMessage: message2) == .failed)
        #expect(message2.secs2Body == nil)
        #expect(message2.isDataMessage == false)
        #expect(message2.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x00, 0x02, 0x00, 0x04, 0x01, 0x02, 0x03, 0x04]))
        
        // unknown
        header10Bytes[3] = 0x81
        let messageFF = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(messageFF.messageType == .deselectResponse)
        #expect(HSMSMessage.DeselectStatus(hsmsDeselectRespnseMessage: messageFF) == .unknown)
        #expect(messageFF.secs2Body == nil)
        #expect(messageFF.isDataMessage == false)
        #expect(messageFF.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x00, 0x81, 0x00, 0x04, 0x01, 0x02, 0x03, 0x04]))

    }
    
    @Test func testDecodeLinktestRequest() async throws {
        
        let header10Bytes = Data([0x01, 0x02, 0x00, 0x00, 0x00, 0x05, 0x01, 0x02, 0x03, 0x04])
        let secs2Body = Data([])
        
        let message = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message.messageType == .linktestRequest)
        #expect(message.secs2Body == nil)
        #expect(message.isDataMessage == false)
        #expect(message.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x00, 0x00, 0x00, 0x05, 0x01, 0x02, 0x03, 0x04]))
    }
    
    @Test func testDecodeLinktestResponse() async throws {
        
        let header10Bytes = Data([0x01, 0x02, 0x00, 0x00, 0x00, 0x06, 0x01, 0x02, 0x03, 0x04])
        let secs2Body = Data([])
        
        let message = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message.messageType == .linktestResponse)
        #expect(message.secs2Body == nil)
        #expect(message.isDataMessage == false)
        #expect(message.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x00, 0x00, 0x00, 0x06, 0x01, 0x02, 0x03, 0x04]))
    }
    
    @Test func testDecodeRejectRequest() async throws {
        
        var header10Bytes = Data([0x01, 0x02, 0x03, 0x00, 0x00, 0x07, 0x01, 0x02, 0x03, 0x04])
        let secs2Body = Data([])
        
        // notSupportTypeS
        header10Bytes[3] = 0x01
        let message1 = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message1.messageType == .rejectRequest)
        #expect(HSMSMessage.RejectReason(hsmsRejectRequestMessage: message1) == .notSupportTypeS)
        #expect(message1.secs2Body == nil)
        #expect(message1.isDataMessage == false)
        #expect(message1.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x03, 0x01, 0x00, 0x07, 0x01, 0x02, 0x03, 0x04]))
        
        // notSupportTypeP
        header10Bytes[3] = 0x02
        let message2 = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message2.messageType == .rejectRequest)
        #expect(HSMSMessage.RejectReason(hsmsRejectRequestMessage: message2) == .notSupportTypeP)
        #expect(message2.secs2Body == nil)
        #expect(message2.isDataMessage == false)
        #expect(message2.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x03, 0x02, 0x00, 0x07, 0x01, 0x02, 0x03, 0x04]))
        
        // transactionNotOpen
        header10Bytes[3] = 0x03
        let message3 = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message3.messageType == .rejectRequest)
        #expect(HSMSMessage.RejectReason(hsmsRejectRequestMessage: message3) == .transactionNotOpen)
        #expect(message3.secs2Body == nil)
        #expect(message3.isDataMessage == false)
        #expect(message3.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x03, 0x03, 0x00, 0x07, 0x01, 0x02, 0x03, 0x04]))
        
        // notSelected
        header10Bytes[3] = 0x04
        let message4 = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message4.messageType == .rejectRequest)
        #expect(HSMSMessage.RejectReason(hsmsRejectRequestMessage: message4) == .notSelected)
        #expect(message4.secs2Body == nil)
        #expect(message4.isDataMessage == false)
        #expect(message4.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x03, 0x04, 0x00, 0x07, 0x01, 0x02, 0x03, 0x04]))
        
        // unknown
        header10Bytes[3] = 0x81
        let messageFF = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(messageFF.messageType == .rejectRequest)
        #expect(HSMSMessage.RejectReason(hsmsRejectRequestMessage: messageFF) == .unknown)
        #expect(messageFF.secs2Body == nil)
        #expect(messageFF.isDataMessage == false)
        #expect(messageFF.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x03, 0x81, 0x00, 0x07, 0x01, 0x02, 0x03, 0x04]))
        
    }
    
    @Test func testDecodeSeparateResponse() async throws {
        
        let header10Bytes = Data([0x01, 0x02, 0x00, 0x00, 0x00, 0x09, 0x01, 0x02, 0x03, 0x04])
        let secs2Body = Data([])
        
        let message = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message.messageType == .separateRequest)
        #expect(message.secs2Body == nil)
        #expect(message.isDataMessage == false)
        #expect(message.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x00, 0x00, 0x00, 0x09, 0x01, 0x02, 0x03, 0x04]))
    }
    
    @Test func testDecodeUnknown() async throws {
        
        let header10Bytes = Data([0x01, 0x02, 0x00, 0x00, 0x01, 0x00, 0x01, 0x02, 0x03, 0x04])
        let secs2Body = Data([])
        
        let message = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: secs2Body)
        
        #expect(message.messageType == .unknown)
        #expect(message.secs2Body == nil)
        #expect(message.isDataMessage == false)
        #expect(message.data == Data([0x00, 0x00, 0x00, 0x0A, 0x01, 0x02, 0x00, 0x00, 0x01, 0x00, 0x01, 0x02, 0x03, 0x04]))
    }
    
}
