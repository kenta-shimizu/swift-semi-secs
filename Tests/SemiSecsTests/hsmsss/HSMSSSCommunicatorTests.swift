//
//  HSMSSSCommunicatorTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/07/06.
//

import Testing
import Foundation
import Network
import SemiSecs

struct HSMSSSCommunicatorTests {
    
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
        
        communicator.didReceivePrimaryDataSECSMessage = { message in
            Task {
                do {
                    switch message.stream {
                    case 1:
                        switch message.function {
                        case 1:
                            if message.wbit {
                                try await communicator.gem.s1f2(primaryMessage: message)
                            }
                        case 13:
                            if message.wbit {
                                try await communicator.gem.s1f14(primaryMessage: message, commack: .accepted)
                            }
                        default:
                            if message.wbit {
                                try await communicator.reply(primaryMessage: message, stream: message.stream, function: 0, wbit: false)
                            }
                        }
                    case 2:
                        switch message.function {
                        case 17:
                            if message.wbit {
                                try await communicator.gem.s2f18Now(primaryMessage: message, clockType: .a16)
                            }
                        default:
                            if message.wbit {
                                try await communicator.reply(primaryMessage: message, stream: message.stream, function: 0, wbit: false)
                            }
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
                            try await communicator.gem.s1f2(primaryMessage: message, mdln: "MDLN-A", softrev: "000001")
                        case 13:
                            if message.wbit {
                                try await communicator.gem.s1f14(primaryMessage: message, commack: .accepted, mdln: "MDLN-A", softrev: "000001")
                            }
                        case 15:
                            if message.wbit {
                                try await communicator.gem.s1f16(primaryMessage: message, oflack: .acknowledge)
                            }
                        case 17:
                            if message.wbit {
                                try await communicator.gem.s1f18(primaryMessage: message, onlack: .accepted)
                            }
                        default:
                            if message.wbit {
                                try await communicator.reply(primaryMessage: message, stream: message.stream, function: 0, wbit: false)
                            }
                            
                            try await communicator.gem.s9f5(referenceMessage: message)
                        }
                    case 2:
                        switch message.function {
                        case 31:
                            if message.wbit {
                                guard let string = message.secs2Body?.stringValue(),
                                      let date: Date = GEM.Clock.date(from: string) else {
                                    try
                                    await communicator.gem.s2f32(primaryMessage: message, tiack: .notAccepted)
                                    return
                                }
                                
                                let formatter = DateFormatter()
                                formatter.locale = Locale.current
                                formatter.timeZone = TimeZone.current
                                formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
                                let dateString = formatter.string(from: date)
                                print("S2F31: \(dateString)")

                                try
                                await communicator.gem.s2f32(primaryMessage: message, tiack: .ok)
                            }
                        default:
                            if message.wbit {
                                try await communicator.reply(primaryMessage: message, stream: message.stream, function: 0, wbit: false)
                            }
                            
                            try await communicator.gem.s9f5(referenceMessage: message)
                        }
                    default:
                        if message.wbit {
                            try await communicator.reply(primaryMessage: message, stream: 0, function: 0, wbit: false)
                        }
                        
                        try await communicator.gem.s9f3(referenceMessage: message)
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
        
        guard try await active.untilCommunicating(timeout: .seconds(5.0)) else {
            Issue.record("communicatable timeout")
            return
        }
        
        try await Task.sleep(for: .seconds(0.2))
        
        let commack = try await active.gem.s1f13()
        guard commack == .accepted else {
            Issue.record("COMMACK: \(commack)")
            return
        }
        
        try await Task.sleep(for: .seconds(0.2))
        
        let onlack = try await active.gem.s1f17()
        guard onlack == .accepted else {
            Issue.record("ONLACK: \(onlack)")
            return
        }
        
        try await active.gem.s2f31Now(clockType: .a16)
        
        let date = try await passive.gem.s2f17()
        
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        let dateString = formatter.string(from: date)
        print("S2F18: \(dateString)")

        let s5f1 = try SMLMessageParser.shared.parse("S5F1 <L <B 0x81><U2 1001><A \"ON FIRE\">>.")
        try await passive.send(smlMessage: s5f1)
        
        try await Task.sleep(for: .seconds(10.0))
        
        let oflack = try await active.gem.s1f15()
        guard oflack == .acknowledge else {
            Issue.record("OFLACK: \(oflack)")
            return
        }
        
        active.shutdown()
        try await Task.sleep(for: .seconds(1.0))
        passive.shutdown()
        try await Task.sleep(for: .seconds(1.0))
    }

}
