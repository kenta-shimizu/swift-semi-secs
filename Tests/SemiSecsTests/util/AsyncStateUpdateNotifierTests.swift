//
//  AsyncStateUpdateNotifierTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/18.
//

import Testing
@testable import SemiSecs

@Suite struct AsyncStateUpdateNotifierTests {

    @Test func testSet() async throws {
        let s1 = "a"
        let s2 = "b"
        
        let notifier = AsyncStateUpdateNotifier<String>(state: s1)
        
        #expect(await notifier.state == s1)
        
        try await notifier.set(state: s2)
        #expect(await notifier.state == s2)
        
        await notifier.shutdown()
        await #expect(throws: AsyncShutdownError.self) {
            try await notifier.set(state: s1)
        }
    }
    
    @Suite struct WaitUntilTests {
        
        @Test func testWaitUntil() async throws {
            
            let s1 = "a"
            let s2 = "b"
            
            let notifier = AsyncStateUpdateNotifier<String>(state: s1)
            
            // already setted
            try await notifier.waitUntil(state: s1)
            
            // waiting state change
            Task {
                try await Task.sleep(for: .seconds(0.5))
                try await notifier.set(state: s2)
            }
            try await notifier.waitUntil(state: s2)
            
            // waining shutdown
            Task {
                try await Task.sleep(for: .seconds(0.5))
                await notifier.shutdown()
            }
            await #expect(throws: AsyncShutdownError.self) {
                try await notifier.waitUntil(state: s1)
            }

            // already shutdowned
            await #expect(throws: AsyncShutdownError.self) {
                try await notifier.waitUntil(state: s2)
            }
            
        }
        
        @Test func testWaitUntilNot() async throws {
            
            let s1 = "a"
            let s2 = "b"
            
            let notifier = AsyncStateUpdateNotifier<String>(state: s1)
            
            // already setted
            try await notifier.waitUntilNot(state: s2)
            
            // waiting state change
            Task {
                try await Task.sleep(for: .seconds(0.5))
                try await notifier.set(state: s2)
            }
            try await notifier.waitUntilNot(state: s1)
            
            // waining shutdown
            Task {
                try await Task.sleep(for: .seconds(0.5))
                await notifier.shutdown()
            }
            await #expect(throws: AsyncShutdownError.self) {
                try await notifier.waitUntilNot(state: s2)
            }

            // already shutdowned
            await #expect(throws: AsyncShutdownError.self) {
                try await notifier.waitUntilNot(state: s1)
            }
            
        }
        
        @Test func testWaitUntilWithTimeout() async throws {
            
            let s1 = "a"
            let s2 = "b"
            
            let notifier = AsyncStateUpdateNotifier<String>(state: s1)
            
            // already setted
            let r1 = try await notifier.waitUntil(state: s1, timeout: 10.0)
            #expect(r1 == true)
            
            // set time-in
            Task {
                try await Task.sleep(for: .seconds(0.5))
                try await notifier.set(state: s2)
            }
            let r2 = try await notifier.waitUntil(state: s2, timeout: 10.0)
            #expect(r2 == true)
            
            // time-out
            let r3 = try await notifier.waitUntil(state: s1, timeout: 0.1)
            #expect(r3 == false)
            
            // waiting shutdown
            Task {
                try await Task.sleep(for: .seconds(0.5))
                await notifier.shutdown()
            }
            await #expect(throws: AsyncShutdownError.self) {
                try await notifier.waitUntil(state: s1, timeout: 10.0)
            }
            
            // already shutdowned
            await #expect(throws: AsyncShutdownError.self) {
                try await notifier.waitUntil(state: s2, timeout: 10.0)
            }

        }
        
        @Test func testWaitUntilNotWithTimeout() async throws {
            
            let s1 = "a"
            let s2 = "b"
            
            let notifier = AsyncStateUpdateNotifier<String>(state: s1)
            
            // already setted
            let r1 = try await notifier.waitUntilNot(state: s2, timeout: 10.0)
            #expect(r1 == true)
            
            // set time-in
            Task {
                try await Task.sleep(for: .seconds(0.5))
                try await notifier.set(state: s2)
            }
            let r2 = try await notifier.waitUntilNot(state: s1, timeout: 10.0)
            #expect(r2 == true)
            
            // time-out
            let r3 = try await notifier.waitUntilNot(state: s2, timeout: 0.1)
            #expect(r3 == false)
            
            // waiting shutdown
            Task {
                try await Task.sleep(for: .seconds(0.5))
                await notifier.shutdown()
            }
            await #expect(throws: AsyncShutdownError.self) {
                try await notifier.waitUntilNot(state: s2, timeout: 10.0)
            }
            
            // already shutdowned
            await #expect(throws: AsyncShutdownError.self) {
                try await notifier.waitUntilNot(state: s1, timeout: 10.0)
            }
            
        }
        
    }
    
}
