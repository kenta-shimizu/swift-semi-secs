//
//  HSMSMessageTransactorTest.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/05/01.
//

import Testing
import Foundation
import Network
@testable import SemiSecs

struct HSMSMessageTransactorTest {
    
    private func hostMessageBuilder() -> HSMSMessageBuildable {
        let builder = HSMSSSMessageBuilder()
        builder.isEquipment = { false }
        return builder
    }
    
    private func equipMessageBuilder() -> HSMSMessageBuildable {
        let builder = HSMSSSMessageBuilder()
        builder.isEquipment = { true }
        return builder
    }
    
    private func networkConnection() -> NWConnection {
        let host = NWEndpoint.Host("127.0.0.1")
        let port = NWEndpoint.Port(integerLiteral: 5000)
        let parameters = NWParameters.tcp
        
        let connection = NWConnection(host: host, port: port, using: parameters)
        return connection
    }
    
    @Test func testSuccessSendAndReply() async throws {
        
        let transactor = HSMSMessageTransactor()
        
        do {
            transactor.timeoutT3 = { 45.0 }
            transactor.timeoutT6 = {  5.0 }
            
            transactor.onWillSendMessage = { message, connection in
                do {
                    try await transactor.putDidSend(message: message, connection: connection, error: nil)
                }
                catch {
                    Issue.record("will-send error")
                }
                
                Task.detached {
                    do {
                        let builder = equipMessageBuilder()
                        
                        switch message.messageType {
                        case .data:
                            if message.wbit {
                                let response = builder.buildResponseData(primaryMessage: message, stream: message.stream, function: message.function  + 1, wbit: false)
                                try await transactor.putDidReceive(message: response, connection: connection)
                            }
                            
                        case .selectRequest:
                            let response = builder.buildSelectResponse(selectRequest: message, selectStatus: .success)
                            try await transactor.putDidReceive(message: response, connection: connection)

                        case .deselectRequest:
                            let response = builder.buildDeselectResponse(deselectRequest: message, deselectStatus: .success)
                            try await transactor.putDidReceive(message: response, connection: connection)

                        case .linktestRequest:
                            let response = builder.buildLinktestResponse(linktestRequest: message)
                            try await transactor.putDidReceive(message: response, connection: connection)
                            
                        default:
                            // nothing
                            break
                        }
                    }
                    catch {
                        Issue.record("reply error")
                    }
                }
            }
            
            transactor.onDidReceiveMessage = { message, connection in
                Issue.record("did-receive error")
            }
            
            let sessionId: UInt16 = 100
            let builder = hostMessageBuilder()
            let connection = networkConnection()
            
            // data
            let dataRequest = builder.buildPrimaryData(sessionId: sessionId, stream: 1, function: 13, wbit: true)
            let dataResponse = try await transactor.send(message: dataRequest, connection: connection)
            
            #expect(dataResponse?.messageType == .data)
            #expect(dataResponse?.stream == 1)
            #expect(dataResponse?.function == 14)
            #expect(dataResponse?.wbit == false)
            
            // no-reply-data
            let noReplyRequest = builder.buildPrimaryData(sessionId: sessionId, stream: 1, function: 13, wbit: false)
            let noReplyResponse = try await transactor.send(message: noReplyRequest, connection: connection)
            
            #expect(noReplyResponse == nil)
            
            // select.req
            let selectRequest = builder.buildSelectRequest(sessionId: sessionId)
            let selectResponse = try await transactor.send(message: selectRequest, connection: connection)
            
            #expect(selectResponse?.messageType == .selectResponse)
            
            // deselect.req
            let deselectRequest = builder.buildDeselectRequest(sessionId: sessionId)
            let deselectResponse = try await transactor.send(message: deselectRequest, connection: connection)
            
            #expect(deselectResponse?.messageType == .deselectResponse)
            
            // linktest.req
            let linktestRequest = builder.buildLinktestRequest(sessionId: sessionId)
            let linktestResponse = try await transactor.send(message: linktestRequest, connection: connection)
            
            #expect(linktestResponse?.messageType == .linktestResponse)
            
            // finally
            await transactor.shutdown()
        }
        catch {
            // error finally
            await transactor.shutdown()
            
            Issue.record("error finally")
        }
    }
    
    @Test func testSuccessReply() async throws {
        
        let transactor = HSMSMessageTransactor()
        
        do {
            transactor.timeoutT3 = { 45.0 }
            transactor.timeoutT6 = {  5.0 }
            
            transactor.onWillSendMessage = { message, connection in
                do {
                    try await transactor.putDidSend(message: message, connection: connection, error: nil)
                }
                catch {
                    Issue.record("will-send error")
                }
            }
            
            transactor.onDidReceiveMessage = { message, connection in
                Issue.record("did-receive error")
            }
            
            let sessionId: UInt16 = 100
            let hostBuilder = hostMessageBuilder()
            let equipBuilder = equipMessageBuilder()
            let connection = networkConnection()
            
            // data
            let dataRequest = equipBuilder.buildPrimaryData(sessionId: sessionId, stream: 5, function: 1, wbit: false)
            try await transactor.reply(message: dataRequest, connection: connection)
            
            // select.rsp
            let selectRequest = hostBuilder.buildSelectRequest(sessionId: sessionId)
            let selectResponse = equipBuilder.buildSelectResponse(selectRequest: selectRequest, selectStatus: .success)
            try await transactor.reply(message: selectResponse, connection: connection)
            
            // deselect.rsp
            let deselectRequest = hostBuilder.buildDeselectRequest(sessionId: sessionId)
            let deselectResponse = equipBuilder.buildDeselectResponse(deselectRequest: deselectRequest, deselectStatus: .success)
            try await transactor.reply(message: deselectResponse, connection: connection)
            
            // linktest.rsp
            let linktestRequest = hostBuilder.buildLinktestRequest(sessionId: sessionId)
            let linktestResponse = equipBuilder.buildLinktestResponse(linktestRequest: linktestRequest)
            try await transactor.reply(message: linktestResponse, connection: connection)
            
            // reject.req
            let failureRequest = hostBuilder.buildSelectRequest(sessionId: sessionId)
            let rejectRequest = equipBuilder.buildRejectRequest(referenceMessage: failureRequest, rejectReason: .notSelected, byte2: 1)
            try await transactor.reply(message: rejectRequest, connection: connection)
            
            // separate.rsp
            let separateRequest = hostBuilder.buildSeparateRequest(sessionId: sessionId)
            try await transactor.reply(message: separateRequest, connection: connection)
            
            // finally
            await transactor.shutdown()
        }
        catch {
            // error finally
            await transactor.shutdown()
            
            Issue.record("error finally")
        }
    }
    
    @Test func testPutPrimaryMessage() async throws {
        
        let transactor = HSMSMessageTransactor()
        var receiveMessages: [HSMSMessage] = []
        
        do {
            transactor.timeoutT3 = { 45.0 }
            transactor.timeoutT6 = {  5.0 }
            
            transactor.onWillSendMessage = { message, connection in
                Issue.record("will-send error")
            }
            
            transactor.onDidReceiveMessage = { message, _ in
                receiveMessages.append(message)
            }
            
            let sessionId: UInt16 = 100
            let builder = equipMessageBuilder()
            let connection = networkConnection()
            
            // data
            let dataRequest = builder.buildPrimaryData(sessionId: sessionId, stream: 1, function: 13, wbit: true)
            try await transactor.putDidReceive(message: dataRequest, connection: connection)
            
            // select.req
            let selectRequest = builder.buildSelectRequest(sessionId: sessionId)
            try await transactor.putDidReceive(message: selectRequest, connection: connection)
            
            // deselect.req
            let deselectRequest = builder.buildDeselectRequest(sessionId: sessionId)
            try await transactor.putDidReceive(message: deselectRequest, connection: connection)
            
            // linktest.req
            let linktestRequest = builder.buildLinktestRequest(sessionId: sessionId)
            try await transactor.putDidReceive(message: linktestRequest, connection: connection)
            
            // separate.req
            let separateRequest = builder.buildSeparateRequest(sessionId: sessionId)
            try await transactor.putDidReceive(message: separateRequest, connection: connection)
            
            #expect(receiveMessages[0].messageType == .data)
            #expect(receiveMessages[1].messageType == .selectRequest)
            #expect(receiveMessages[2].messageType == .deselectRequest)
            #expect(receiveMessages[3].messageType == .linktestRequest)
            #expect(receiveMessages[4].messageType == .separateRequest)
            
            // finally
            await transactor.shutdown()
        }
        catch {
            // error finally
            await transactor.shutdown()
            
            Issue.record("error finally")
        }
    }
    
    // tests
    // timeout-T3
    // timeout-T3
    // shutdown
    // send-error
    
}
