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
    
    private func transactor(timeoutT3: Duration, timeoutT6: Duration) -> HSMSMessageTransactor {
        let instance = HSMSMessageTransactor()
        instance.timeoutT3 = { timeoutT3 }
        instance.timeoutT6 = { timeoutT6 }
        return instance
    }
    
    @Test func testSuccessSendAndReply() async throws {
        
        let transactor = self.transactor(timeoutT3: .seconds(45.0), timeoutT6: .seconds(5.0))
        
        Task { [weak transactor] in
            guard let transactor = transactor else { return }
            let builder = equipMessageBuilder()
            let stream = await transactor.willSendMessageStream()
            for await value in stream {
                let message = value.message
                let connection = value.connection
                
                await transactor.yield(sendedMessage: message, connection: connection, error: nil)
                
                switch message.messageType {
                case .data:
                    if message.wbit {
                        let response = builder.buildResponseData(primaryMessage: message, stream: message.stream, function: message.function  + 1, wbit: false)
                        await transactor.yield(receiveMessage: response, connection: connection)
                    }
                    
                case .selectRequest:
                    let response = builder.buildSelectResponse(selectRequest: message, selectStatus: .success)
                    await transactor.yield(receiveMessage: response, connection: connection)

                case .deselectRequest:
                    let response = builder.buildDeselectResponse(deselectRequest: message, deselectStatus: .success)
                    await transactor.yield(receiveMessage: response, connection: connection)

                case .linktestRequest:
                    let response = builder.buildLinktestResponse(linktestRequest: message)
                    await transactor.yield(receiveMessage: response, connection: connection)
                    
                default:
                    // nothing
                    break
                }
            }
        }
        
        Task { [weak transactor] in
            guard let transactor = transactor else { return }
            let stream = await transactor.didReceiveMessageStream()
            for await _ in stream {
                Issue.record("did-receive error")
            }
        }
        
        do {
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
        
        let transactor = self.transactor(timeoutT3: .seconds(45.0), timeoutT6: .seconds(5.0))
        
        Task { [weak transactor] in
            guard let transactor = transactor else { return }
            let stream = await transactor.willSendMessageStream()
            for await value in stream {
                let message = value.message
                let connection = value.connection
                
                await transactor.yield(sendedMessage: message, connection: connection, error: nil)
            }
        }
        
        Task { [weak transactor] in
            guard let transactor = transactor else { return }
            let stream = await transactor.didReceiveMessageStream()
            for await _ in stream {
                Issue.record("did-receive error")
            }
        }
        
        
        do {
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
    
    @Test func testReceivePrimaryMessage() async throws {
        
        let transactor = self.transactor(timeoutT3: .seconds(45.0), timeoutT6: .seconds(5.0))
        
        Task { [weak transactor] in
            guard let transactor = transactor else { return }
            let stream = await transactor.willSendMessageStream()
            for await _ in stream {
                Issue.record("did-receive error")
            }
        }
        
        Task { [weak transactor] in
            guard let transactor = transactor else { return }
            let stream = await transactor.didReceiveMessageStream()
            
            do {
                #expect(try await stream.take().message.messageType == .data)
                #expect(try await stream.take().message.messageType == .selectRequest)
                #expect(try await stream.take().message.messageType == .deselectRequest)
                #expect(try await stream.take().message.messageType == .linktestRequest)
                #expect(try await stream.take().message.messageType == .separateRequest)
            }
            catch {
                Issue.record(error)
            }
        }
        
        let sessionId: UInt16 = 100
        let builder = equipMessageBuilder()
        let connection = networkConnection()
        
        // data
        let dataRequest = builder.buildPrimaryData(sessionId: sessionId, stream: 1, function: 13, wbit: true)
        await transactor.yield(receiveMessage: dataRequest, connection: connection)
        
        // select.req
        let selectRequest = builder.buildSelectRequest(sessionId: sessionId)
        await transactor.yield(receiveMessage: selectRequest, connection: connection)
        
        // deselect.req
        let deselectRequest = builder.buildDeselectRequest(sessionId: sessionId)
        await transactor.yield(receiveMessage: deselectRequest, connection: connection)
        
        // linktest.req
        let linktestRequest = builder.buildLinktestRequest(sessionId: sessionId)
        await transactor.yield(receiveMessage: linktestRequest, connection: connection)
        
        // separate.req
        let separateRequest = builder.buildSeparateRequest(sessionId: sessionId)
        await transactor.yield(receiveMessage: separateRequest, connection: connection)
        
        // finally
        await transactor.shutdown()
    }
    
    @Test func testTimeoutT3() async throws {
        
        let transactor = self.transactor(timeoutT3: .seconds(0.10), timeoutT6: .seconds(5.0))
        
        Task { [weak transactor] in
            guard let transactor = transactor else { return }
            let stream = await transactor.willSendMessageStream()
            for await value in stream {
                let message = value.message
                let connection = value.connection
                
                await transactor.yield(sendedMessage: message, connection: connection, error: nil)
            }
        }
        
        Task { [weak transactor] in
            guard let transactor = transactor else { return }
            let stream = await transactor.didReceiveMessageStream()
            for await _ in stream {
            }
        }
        
        do {
            let sessionId: UInt16 = 100
            let builder = hostMessageBuilder()
            let connection = networkConnection()
            
            // data
            let dataRequest = builder.buildPrimaryData(sessionId: sessionId, stream: 1, function: 13, wbit: true)
            let _ = try await transactor.send(message: dataRequest, connection: connection)
            
            Issue.record("timeoutT3-failed")
            
            // finally
            await transactor.shutdown()
        }
        catch HSMSWaitReplyError.timeoutT3(_, _) {
            // error finally
            await transactor.shutdown()
            // success
        }
        catch {
            // error finally
            await transactor.shutdown()
            
            Issue.record("error finally")
        }
    }
    
    @Test func testTimeoutT6() async throws {
        
        let transactor = self.transactor(timeoutT3: .seconds(45.0), timeoutT6: .seconds(0.10))
        
        Task { [weak transactor] in
            guard let transactor = transactor else { return }
            let stream = await transactor.willSendMessageStream()
            for await value in stream {
                let message = value.message
                let connection = value.connection
                
                await transactor.yield(sendedMessage: message, connection: connection, error: nil)
            }
        }
        
        Task { [weak transactor] in
            guard let transactor = transactor else { return }
            let stream = await transactor.didReceiveMessageStream()
            for await _ in stream {
            }
        }
        
        let sessionId: UInt16 = 100
        let builder = hostMessageBuilder()
        let connection = networkConnection()
        
        do {
            // select.req
            let selectRequest = builder.buildSelectRequest(sessionId: sessionId)
            let _ = try await transactor.send(message: selectRequest, connection: connection)
            
            Issue.record("timeoutT6-failed")
        }
        catch HSMSWaitReplyError.timeoutT6(_, _) {
            // error success
        }
        catch {
            Issue.record("error finally")
        }
        do {
            // deselect.req
            let deselectRequest = builder.buildDeselectRequest(sessionId: sessionId)
            let _ = try await transactor.send(message: deselectRequest, connection: connection)
            
            Issue.record("timeoutT6-failed")
        }
        catch HSMSWaitReplyError.timeoutT6(_, _) {
            // error success
        }
        catch {
            Issue.record("error finally")
        }
        do {
            // linktest.req
            let linktestRequest = builder.buildLinktestRequest(sessionId: sessionId)
            let _ = try await transactor.send(message: linktestRequest, connection: connection)
            
            Issue.record("timeoutT6-failed")
        }
        catch HSMSWaitReplyError.timeoutT6(_, _) {
            // error success
        }
        catch {
            Issue.record("error finally")
        }
        
        await transactor.shutdown()
    }
    
    // tests
    // reject
    // receive-shutdown
    // send-error
    // send-shutdown
    
}
