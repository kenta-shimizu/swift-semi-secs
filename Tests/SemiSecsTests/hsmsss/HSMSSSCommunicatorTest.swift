//
//  HSMSSSCommunicatorTest.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/07/06.
//

import Testing
import Foundation
import Network
import SemiSecs

struct HSMSSSCommunicatorTest {
    
    private let testPort: NWEndpoint.Port = 5020
    
    private func activeCommunicator() -> HSMSSSCommunicator {
        let communicator = HSMSSSCommunicator()
        communicator.config.connectionMode = .active
        communicator.config.ipAddress = "127.0.0.1"
        communicator.config.port = self.testPort
        communicator.config.isEquipment = false
        communicator.config.sessionId = 10
        communicator.config.timeout.t3 = .seconds(45.0)
        communicator.config.timeout.t5 = .seconds(10.0)
        communicator.config.timeout.t6 = .seconds( 5.0)
        communicator.config.timeout.t8 = .seconds( 6.0)
        communicator.config.autoLinktest = true
        communicator.config.linktestDuration = .seconds(120.0)
        
        return communicator
    }
    
    private func passiveCommunicator() -> HSMSSSCommunicator {
        let communicator = HSMSSSCommunicator()
        communicator.config.connectionMode = .passive
        communicator.config.port = self.testPort
        communicator.config.isEquipment = true
        communicator.config.sessionId = 10
        communicator.config.timeout.t3 = .seconds(45.0)
        communicator.config.timeout.t6 = .seconds( 5.0)
        communicator.config.timeout.t7 = .seconds(10.0)
        communicator.config.timeout.t8 = .seconds( 6.0)
        communicator.config.autoLinktest = false
        communicator.config.rebindDuration = .seconds(10.0)
        
        communicator.didReceivePrimaryDataSECSMessage = { message in
            Task {
                do {
                    switch message.stream {
                    case 1:
                        switch message.function {
                        case 1:
                            let smlMessage = try SMLMessageParser.shared.parse("S1F2 <L>.")
                            try await communicator.reply(primaryMessage: message, smlMessage: smlMessage)
                        case 13:
                            let smlMessage = try SMLMessageParser.shared.parse("S1F14 <L <L>>.")
                            try await communicator.reply(primaryMessage: message, smlMessage: smlMessage)
                        default:
                            try await communicator.reply(primaryMessage: message, stream: message.stream, function: 0, wbit: false)
                        }
                    default:
                        if message.wbit {
                            try await communicator.reply(primaryMessage: message, stream: 0, function: 0, wbit: false)
                        }
                    }
                }
                catch {
                    print(error)
                }
            }
        }
        
        return communicator
    }
    
    @Test func testTest() async throws {
        let passive = self.passiveCommunicator()
        let active = self.activeCommunicator()
        
        active.config.linktestDuration = .seconds(3.0)
        active.config.timeout.t3 = .seconds(2.0)
        active.config.timeout.t6 = .seconds(2.0)
        
        defer {
            active.shutdown()
            passive.shutdown()
        }
        
        try passive.start()
        try await Task.sleep(for: .seconds(0.5))
        try active.start()
        
//        let builder = SECS2BodyBuilder.shared
//        let secs2body =
//        builder.build(list: [
//            builder.build(binary: Data([0x81])),
//            builder.build(uint2:  [1001]),
//            builder.build(ascii:  "ON FIRE")
//        ])
//        
//        let response = try await passive.send(
//            stream: 5,
//            function: 1,
//            wbit: true,
//            secs2Body: secs2body)
//        
//        active.didReceivePrimaryDataSECSMessage = { primaryMessage in
//            let stream = primaryMessage.stream
//            let function = primaryMessage.function
//            let wbit = primaryMessage.wbit
//            
//            if let secs2Body = primaryMessage.secs2Body {
//                let alid: UInt8?  = secs2Body.uint8Value(at: 0, 0)
//                let alcd: UInt16? = secs2Body.uint16Value(at: 1, 0)
//                let altx: String? = secs2Body.stringValue(at: 2)
//            }
//            
//            try await active.reply(
//                primaryMessage: primaryMessage,
//                stream: 5,
//                function: 2,
//                wbit: false,
//                secs2Body: SECS2BodyBuilder.shared.build(binary: Data([0x00]))
//            )
//        }
//
//        if let response = response {
//            let stream   = response.stream
//            let function = response.function
//            let wbit     = response.wbit
//            if let secs2body = response.secs2Body {
//                ...
//            }
//        }
        
        guard try await active.untilCommunicating(timeout: .seconds(5.0)) else {
            Issue.record("communicatable timeout")
            return
        }
        
        if let s1f2 = try await active.send(stream: 1, function: 1, wbit: true) {
            #expect(s1f2.stream == 1)
            #expect(s1f2.function == 2)
            #expect(s1f2.wbit == false)
        } else {
            Issue.record("Send S1F1")
        }
        
        if let s1f14 = try await active.send(stream: 1, function: 13, wbit: true) {
            #expect(s1f14.stream == 1)
            #expect(s1f14.function == 14)
            #expect(s1f14.wbit == false)
        } else {
            Issue.record("Send S1F13")
        }
        
        let s5f1 = try SMLMessageParser.shared.parse("S5F1 <L <B 0x81><U2 1001><A \"ON FIRE\">>.")
        try await passive.send(smlMessage: s5f1)
        
        try await Task.sleep(for: .seconds(10.0))
        active.shutdown()
        try await Task.sleep(for: .seconds(1.0))
        passive.shutdown()
        try await Task.sleep(for: .seconds(1.0))
    }

}
