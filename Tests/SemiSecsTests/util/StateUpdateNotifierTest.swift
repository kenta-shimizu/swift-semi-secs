//
//  StateUpdateNotifierTest.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/07/03.
//

import Testing
@testable import SemiSecs

struct StateUpdateNotifierTest {

    @Test func testStreamAndFinish() async throws {
        
        let s1 = "aaa"
        let s2 = "bbb"
        let s3 = "ccc"
        
        let notifier = StateUpdateNotifier<String>(state: s1)
        let stream = notifier.stateUpdateStream()
        
        await notifier.yield(s1)
        await notifier.yield(s2)
        await notifier.yield(s3)
        await notifier.yield(s3)
        await notifier.shutdown()
        
        var states: [String] = []
        for await state in stream {
            states.append(state)
        }
        
        #expect(states.count == 3)
        #expect(states[0] == s1)
        #expect(states[1] == s2)
        #expect(states[2] == s3)
    }
    
    @Test func testUntil() async throws {
        
        let s1 = "aaa"
        let s2 = "bbb"
        let s3 = "ccc"
        
        let notifier = StateUpdateNotifier<String>(state: s1)
        
        try await notifier.until(s1)
        
        Task {
            try await Task.sleep(for: .seconds(0.2))
            await notifier.yield(s2)
        }
        
        try await notifier.until(s2)
        
        Task {
            try await Task.sleep(for: .seconds(0.2))
            await notifier.yield(s2)
            try await Task.sleep(for: .seconds(0.1))
            await notifier.yield(s1)
            try await Task.sleep(for: .seconds(0.1))
            await notifier.yield(s3)
        }
        
        try await notifier.until(s3)
        
        Task {
            try await Task.sleep(for: .seconds(0.2))
            await notifier.shutdown()
        }
        
        await #expect(throws: CancellationError.self) {
            try await notifier.until(s1)
        }
        
        await notifier.yield(s1)
        
        await #expect(throws: CancellationError.self) {
            try await notifier.until(s1)
        }
        
    }
    
    @Test func testUntilNot() async throws {
        
        let s1 = "aaa"
        let s2 = "bbb"
        let s3 = "ccc"
        
        let notifier = StateUpdateNotifier<String>(state: s1)
        
        try await notifier.untilNot(s2)
        
        Task {
            try await Task.sleep(for: .seconds(0.2))
            await notifier.yield(s2)
        }
        
        try await notifier.untilNot(s1)
        
        Task {
            try await Task.sleep(for: .seconds(0.2))
            await notifier.yield(s2)
            try await Task.sleep(for: .seconds(0.1))
            await notifier.yield(s3)
        }
        
        try await notifier.untilNot(s2)
        
        Task {
            try await Task.sleep(for: .seconds(0.2))
            await notifier.shutdown()
        }
        
        await #expect(throws: CancellationError.self) {
            try await notifier.untilNot(s3)
        }
        
        await notifier.yield(s1)
        
        await #expect(throws: CancellationError.self) {
            let _ = try await notifier.untilNot(s3)
        }
        
    }
    
    @Test func testUntilWithTimeout() async throws {
        
        let s1 = "aaa"
        let s2 = "bbb"
        let s3 = "ccc"
        
        let notifier = StateUpdateNotifier<String>(state: s1)
        
        #expect(try await notifier.until(s1, timeout: .seconds(1.0)) == true)
        
        Task {
            try await Task.sleep(for: .seconds(0.2))
            await notifier.yield(s2)
        }
        
        #expect(try await notifier.until(s2, timeout: .seconds(1.0)) == true)
        
        Task {
            try await Task.sleep(for: .seconds(0.2))
            await notifier.yield(s2)
            try await Task.sleep(for: .seconds(0.1))
            await notifier.yield(s1)
            try await Task.sleep(for: .seconds(0.1))
            await notifier.yield(s3)
        }
        
        #expect(try await notifier.until(s3, timeout: .seconds(1.0)) == true)
        
        #expect(try await notifier.until(s2, timeout: .seconds(0.1)) == false)
        
        Task {
            try await Task.sleep(for: .seconds(0.2))
            await notifier.yield(s2)
        }
        
        #expect(try await notifier.until(s2, timeout: .seconds(1.0)) == true)
        
        Task {
            try await Task.sleep(for: .seconds(0.2))
            await notifier.shutdown()
        }
        
        await #expect(throws: CancellationError.self) {
            try await notifier.until(s1, timeout: .seconds(1.0))
        }
        
        await notifier.yield(s1)
        
        await #expect(throws: CancellationError.self) {
            try await notifier.until(s1, timeout: .seconds(1.0))
        }
        
    }
    
    @Test func testUntilNotWithTimeout() async throws {
        
        let s1 = "aaa"
        let s2 = "bbb"
        let s3 = "ccc"
        
        let notifier = StateUpdateNotifier<String>(state: s1)
        
        #expect(try await notifier.untilNot(s2, timeout: .seconds(1.0)) == true)
        
        Task {
            try await Task.sleep(for: .seconds(0.2))
            await notifier.yield(s2)
        }
        
        #expect(try await notifier.untilNot(s1, timeout: .seconds(1.0)) == true)
        
        Task {
            try await Task.sleep(for: .seconds(0.2))
            await notifier.yield(s2)
            try await Task.sleep(for: .seconds(0.1))
            await notifier.yield(s3)
        }
        
        #expect(try await notifier.untilNot(s2, timeout: .seconds(1.0)) == true)
        
        #expect(try await notifier.untilNot(s3, timeout: .seconds(0.1)) == false)

        Task {
            try await Task.sleep(for: .seconds(0.2))
            await notifier.yield(s2)
        }
        
        #expect(try await notifier.untilNot(s3, timeout: .seconds(1.0)) == true)
        
        Task {
            try await Task.sleep(for: .seconds(0.2))
            await notifier.shutdown()
        }
        
        await #expect(throws: CancellationError.self) {
            try await notifier.untilNot(s2, timeout: .seconds(1.0))
        }
        
        await notifier.yield(s1)
        
        await #expect(throws: CancellationError.self) {
            let _ = try await notifier.untilNot(s2, timeout: .seconds(1.0))
        }
        
    }
    
}
