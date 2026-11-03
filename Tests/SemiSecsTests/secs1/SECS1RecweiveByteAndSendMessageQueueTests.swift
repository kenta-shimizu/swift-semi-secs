//
//  SECS1RecweiveByteAndSendMessageQueueTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/10/31.
//

import Testing
import Foundation
@testable import SemiSecs

struct SECS1RecweiveByteAndSendMessageQueueTests {
    
    private func createSECS1Message() -> SECS1Message {
        let builder = SECS1MessageBuilder()
        builder.deviceId = { 100 }
        builder.isEquipment = { true }
        return builder.buildPrimaryData(stream: 1, function: 1, wbit: true)
    }
    
    @Test func testPoll() async throws {
        
        let sendMessage = createSECS1Message()
        
        let queue = SECS1RecweiveByteAndSendMessageQueue()
        
        // pollByte nil
        try #expect(queue.pollReceiveByte() == nil)
        #expect(try! await queue.pollReceiveByte(timeout: .seconds(0.1)) == nil)
        #expect(try! await queue.pollReceiveByte(capacity: 1, timeout: .seconds(0.1)) == nil)
        
        // peekSendMessage nil
        #expect(try! queue.peekFirstSendMessage() == nil)
        
        // poll byte
        queue.yield(receiveBytes: Data([0x01, 0x02, 0x03, 0x04, 0x05]))
        
        try #expect(queue.pollReceiveByte() == 0x01)
        #expect(try! await queue.pollReceiveByte(timeout: .seconds(0.1)) == 0x02)
        #expect(try! await queue.pollReceiveByte(capacity: 2, timeout: .seconds(0.1)) == Data([0x03, 0x04]))
        #expect(try! await queue.pollReceiveByte(capacity: 2, timeout: .seconds(0.1)) == Data([0x05]))
        
        try #expect(queue.pollReceiveByte() == nil)
        #expect(try! await queue.pollReceiveByte(timeout: .seconds(0.1)) == nil)
        #expect(try! await queue.pollReceiveByte(capacity: 1, timeout: .seconds(0.1)) == nil)
        
        // peek sendSECS1Message
        queue.yield(message: sendMessage)
        queue.yield(message: sendMessage)
        try #expect(queue.peekFirstSendMessage() != nil)
        try queue.removeFirstSendMessage()
        try #expect(queue.peekFirstSendMessage() != nil)
        try queue.removeFirstSendMessage()
        try #expect(queue.peekFirstSendMessage() == nil)
        
        // retry poll byte
        queue.yield(receiveBytes: Data([0x11, 0x12, 0x13, 0x14, 0x15]))
        
        try #expect(queue.pollReceiveByte() == 0x11)
        #expect(try! await queue.pollReceiveByte(timeout: .seconds(0.1)) == 0x12)
        #expect(try! await queue.pollReceiveByte(capacity: 2, timeout: .seconds(0.1)) == Data([0x13, 0x14]))
        try queue.clearBytes()
        
        try #expect(queue.pollReceiveByte() == nil)
        #expect(try! await queue.pollReceiveByte(timeout: .seconds(0.1)) == nil)
        #expect(try! await queue.pollReceiveByte(capacity: 1, timeout: .seconds(0.1)) == nil)
        
        // retry peek sendSECS1Message
        queue.yield(message: sendMessage)
        try #expect(queue.peekFirstSendMessage() != nil)
        try queue.removeFirstSendMessage()
        try #expect(queue.peekFirstSendMessage() == nil)
        
        try queue.removeFirstSendMessage()  // No-Crash

        // until entry receive byte
        queue.yield(receiveBytes: Data([0x21]))
        try await queue.untilEntry()    // through
        try queue.clearBytes()
        
        // until entry sendMessage
        queue.yield(message: sendMessage)
        try await queue.untilEntry()    // through
        try queue.removeFirstSendMessage()
        
        // before shutdown, yield.
        queue.yield(receiveBytes: Data([0x21]))
        queue.yield(message: sendMessage)
        
        // shutdown
        queue.shutdown()
        
        // No Crash
        queue.yield(receiveBytes: Data([0x01]))
        queue.yield(message: sendMessage)
        
        // CancellationError
        #expect(throws: CancellationError.self) {
            try queue.clearBytes()
        }
        #expect(throws: CancellationError.self) {
            try queue.pollReceiveByte()
        }
        await #expect(throws: CancellationError.self) {
            try await queue.pollReceiveByte(timeout: .seconds(0.1))
        }
        await #expect(throws: CancellationError.self) {
            try await queue.pollReceiveByte(capacity: 1, timeout: .seconds(0.1))
        }
        #expect(throws: CancellationError.self) {
            try queue.peekFirstSendMessage()
        }
        #expect(throws: CancellationError.self) {
            try queue.removeFirstSendMessage()
        }
        await #expect(throws: CancellationError.self) {
            try await queue.untilEntry()
        }
        
    }

    @Test func testUntilEntry() async throws {
        
        let sendMessage = createSECS1Message()
        
        let queue = SECS1RecweiveByteAndSendMessageQueue()
        
        // SendMessage
        Task {
            try await Task.sleep(for: .seconds(0.50))
            queue.yield(message: sendMessage)
        }
        
        try await queue.untilEntry()    // through
        try queue.removeFirstSendMessage()
        
        // Receive-byte
        Task {
            try await Task.sleep(for: .seconds(0.50))
            queue.yield(receiveBytes: Data([0x01, 0x02]))
        }
        
        try await queue.untilEntry()    // through
        try queue.clearBytes()

        // shutdown
        Task {
            try await Task.sleep(for: .seconds(0.50))
            queue.shutdown()
        }
        
        await #expect(throws: CancellationError.self) {
            try await queue.untilEntry()
        }
        
    }
    
    @Test func testPollTimeout() async throws {
        
        let queue = SECS1RecweiveByteAndSendMessageQueue()
        let b: UInt8 = 1
        
        // timeout
        #expect(try! await queue.pollReceiveByte(timeout: .seconds(0.1)) == nil)
        
        // in time
        Task {
            try await Task.sleep(for: .seconds(0.50))
            queue.yield(receiveBytes: Data([b]))
        }
        
        #expect(try! await queue.pollReceiveByte(timeout: .seconds(10.0)) == b)
        
        // shutdown
        Task {
            try await Task.sleep(for: .seconds(0.50))
            queue.shutdown()
        }
        
        await #expect(throws: CancellationError.self) {
            try await queue.pollReceiveByte(timeout: .seconds(10.0))
        }
        
    }
    
    @Test func testPollCapacityTimeout() async throws {
        
        let queue = SECS1RecweiveByteAndSendMessageQueue()
        let d2 = Data([0x01, 0x02])
        let d3 = d2 + Data([0x03])
        
        // timeout
        #expect(try! await queue.pollReceiveByte(capacity: 1, timeout: .seconds(0.1)) == nil)
        
        // in time, yield count == capacity
        Task {
            try await Task.sleep(for: .seconds(0.50))
            queue.yield(receiveBytes: d2)
        }
        
        #expect(try! await queue.pollReceiveByte(capacity: 2, timeout: .seconds(10.0)) == d2)
        try queue.clearBytes()
        
        // in time, yield count > capacity
        Task {
            try await Task.sleep(for: .seconds(0.50))
            queue.yield(receiveBytes: d3)
        }
        
        #expect(try! await queue.pollReceiveByte(capacity: 2, timeout: .seconds(10.0)) == d2)
        try queue.clearBytes()
        
        // in time, yield count < capacity
        Task {
            try await Task.sleep(for: .seconds(0.50))
            queue.yield(receiveBytes: d2)
        }
        
        #expect(try! await queue.pollReceiveByte(capacity: 3, timeout: .seconds(10.0)) == d2)
        try queue.clearBytes()
        
        // shutdown
        Task {
            try await Task.sleep(for: .seconds(0.50))
            queue.shutdown()
        }
        
        await #expect(throws: CancellationError.self) {
            try await queue.pollReceiveByte(capacity: 1, timeout: .seconds(10.0))
        }
        
    }
    
}
