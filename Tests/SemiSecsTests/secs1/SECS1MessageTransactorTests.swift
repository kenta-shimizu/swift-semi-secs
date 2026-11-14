//
//  SECS1MessageTransactorTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/11/14.
//

import Testing
@testable import SemiSecs

struct SECS1MessageTransactorTests {
    
    private func hostMessageBuilder() -> SECS1MessageBuilder {
        let builder = SECS1MessageBuilder()
        builder.deviceId = { 10 }
        builder.isEquipment = { false }
        return builder
    }
    
    private func equipMessageBuilder() -> SECS1MessageBuilder {
        let builder = SECS1MessageBuilder()
        builder.deviceId = { 10 }
        builder.isEquipment = { true }
        return builder
    }
    
    private func transactor(timeoutT3: Duration) -> SECS1MessageTransactor {
        let transactor = SECS1MessageTransactor()
        transactor.timeoutT3 = { timeoutT3 }
        return transactor
    }
    
    @Test func testSuccess() async throws {
        
        let equipMessage1 = equipMessageBuilder().buildPrimaryData(stream: 5, function: 1, wbit: false)
        let equipMessage2 = equipMessageBuilder().buildPrimaryData(stream: 1, function: 1, wbit: true)
        let equipMessage3 = equipMessageBuilder().buildPrimaryData(stream: 5, function: 1, wbit: false)

        let transactor = transactor(timeoutT3: .seconds(5.0))
        
        Task {
            for await message in transactor.willSendMessageStream() {
                try await Task.sleep(for: .seconds(0.50))
                transactor.yield(sendedMessage: message, error: nil)
                
                if message.wbit {
                    try await Task.sleep(for: .seconds(0.10))
                    let response = hostMessageBuilder().buildResponseData(primaryMessage: message, stream: message.stream, function: (message.function + 1), wbit: false, secs2Body: SECS2Body(list: []))
                    transactor.yield(receiveMessage: response)
                }
            }
        }
        
        // receive primary message
        Task {
            var receivePrimaryMessages: [SECS1Message] = []
            
            for await message in transactor.didReceiveMessageStream() {
                receivePrimaryMessages.append(message)
            }
            
            #expect(receivePrimaryMessages.count == 2)
        }
        
        Task {
            try await Task.sleep(for: .seconds(0.3))
            let message1 = hostMessageBuilder().buildPrimaryData(stream: 1, function: 3, wbit: false)
            transactor.yield(receiveMessage: message1)
            
            try await Task.sleep(for: .seconds(0.5))
            let message2 = hostMessageBuilder().buildPrimaryData(stream: 1, function: 5, wbit: false)
            transactor.yield(receiveMessage: message2)
        }
        
        // send-only
        do {
            try await transactor.send(message: equipMessage1)
        }
        catch {
            Issue.record("send failed")
        }
        
        // send and await response
        try await Task.sleep(for: .seconds(0.10))
        if let response = try await transactor.sendAndAwaitResponse(message: equipMessage2) {
            #expect(response.system4BytesKeyValue == equipMessage2.system4BytesKeyValue)
        } else {
            Issue.record("no response")
        }
        
        // send-only
        do {
            let _ = try await transactor.sendAndAwaitResponse(message: equipMessage3)
        }
        catch {
            Issue.record("no response")
        }

        try await Task.sleep(for: .seconds(2.0))
        transactor.shutdown()

        try await Task.sleep(for: .seconds(1.0))
    }

}
