//
//  SECS1CircuitTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/11/14.
//

import Testing
@testable import SemiSecs

struct SECS1CircuitTests {
    
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
    
    private func masterCircuit() -> SECS1Circuit {
        let circuit = SECS1Circuit()
        circuit.isMaster = { true }
        circuit.timeoutT1 = { .seconds(1.0) }
        circuit.timeoutT2 = { .seconds(15.0) }
        circuit.timeoutT4 = { .seconds(45.0) }
        circuit.retry = { 3 }
        return circuit
    }
    
    private func slavbeCircuit() -> SECS1Circuit {
        let circuit = SECS1Circuit()
        circuit.isMaster = { false }
        circuit.timeoutT1 = { .seconds(1.0) }
        circuit.timeoutT2 = { .seconds(15.0) }
        circuit.timeoutT4 = { .seconds(45.0) }
        circuit.retry = { 3 }
        return circuit
    }
    
    @Test func testSuccess() async throws {
        
        let equipMessageBuilder = equipMessageBuilder()
        let equipTransactor = transactor(timeoutT3: .seconds(45.0))
        let equipCircuit = masterCircuit()
        let hostMessageBuilder = hostMessageBuilder()
        let hostTransactor = transactor(timeoutT3: .seconds(45.0))
        let hostCircuit = slavbeCircuit()
        
        // equip
        equipCircuit.transactor = { equipTransactor }
        equipCircuit.sender = {
            hostCircuit.yield(receiveBytes: $0)
        }
        Task {
            for await message in equipTransactor.willSendMessageStream() {
                equipCircuit.yield(message: message)
            }
        }
        Task {
            for await message in equipTransactor.didReceiveMessageStream() {
                try await Task.sleep(for: .seconds(0.1) )
                if message.wbit {
                    let response = equipMessageBuilder.buildResponseData(primaryMessage: message, stream: message.stream, function: (message.function + 1), wbit: false, secs2Body: SECS2Body(list: []))
                    equipCircuit.yield(message: response)
                }
            }
        }
        
        // host
        hostCircuit.transactor = { hostTransactor }
        hostCircuit.sender = {
            equipCircuit.yield(receiveBytes: $0)
        }
        Task {
            for await message in hostTransactor.willSendMessageStream() {
                hostCircuit.yield(message: message)
            }
        }
        Task {
            for await _ in hostTransactor.didReceiveMessageStream() {
                Issue.record("receive no primary message")
            }
        }
        
        defer {
            equipCircuit.shutdown()
            equipTransactor.shutdown()
            hostCircuit.shutdown()
            hostTransactor.shutdown()
        }
        
        try equipCircuit.start()
        try hostCircuit.start()
        
        // single-block
        let singleMessage = hostMessageBuilder.buildPrimaryData(stream: 1, function: 1, wbit: true)
        if let response = try await hostTransactor.sendAndAwaitResponse(message: singleMessage) {
            #expect(response.system4BytesKeyValue == singleMessage.system4BytesKeyValue)
            #expect(response.stream == singleMessage.stream)
            #expect(response.function == (singleMessage.function + 1))
        } else {
            Issue.record("response error")
        }
        
        // multi-block
        let multiMessage = hostMessageBuilder.buildPrimaryData(stream: 2, function: 37, wbit: true, secs2Body: SECS2Body(list:[
            SECS2Body(uint8: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
            SECS2Body(uint8: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
            SECS2Body(uint8: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
            SECS2Body(uint8: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
            SECS2Body(uint8: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
            SECS2Body(uint8: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
            SECS2Body(uint8: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
            SECS2Body(uint8: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
            SECS2Body(uint8: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
            SECS2Body(uint8: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        ]))
        
        #expect(multiMessage.blocks.count >= 2)
        
        if let response = try await hostTransactor.sendAndAwaitResponse(message: multiMessage) {
            #expect(response.system4BytesKeyValue == multiMessage.system4BytesKeyValue)
            #expect(response.stream == multiMessage.stream)
            #expect(response.function == (multiMessage.function + 1))
        } else {
            Issue.record("response error")
        }
        
        try await Task.sleep(for: .seconds(0.5))
    }

}
