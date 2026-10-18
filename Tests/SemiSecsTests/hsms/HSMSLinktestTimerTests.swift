//
//  HSMSLinktestTimerTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/08/12.
//

import Testing
import Synchronization
@testable import SemiSecs

struct HSMSLinktestTimerTests {

    @Test func testAutolinktestFalse() async throws {
        let count = Atomic<Int>(0)
        
        let timer = HSMSLinktestTimer()
        timer.autoLinktest = { return false }
        timer.linktestDuration = { return .seconds(0.50) }
        timer.linktest = { count.add(1, ordering: .relaxed) }
        
        timer.start()
        try await Task.sleep(for: .seconds(1.50))
        timer.shutdown()
        
        #expect(count.load(ordering: .relaxed) == 0)
    }
    
    @Test func testAutolinktestTrue() async throws {
        let count = Atomic<Int>(0)
        
        let timer = HSMSLinktestTimer()
        timer.autoLinktest = { return true }
        timer.linktestDuration = { return .seconds(0.50) }
        timer.linktest = { count.add(1, ordering: .relaxed) }
        
        timer.start()
        try await Task.sleep(for: .seconds(1.70))
        timer.shutdown()
        
        #expect(count.load(ordering: .relaxed) > 0)
    }
    
    @Test func testAutolinktestTrueAndReset() async throws {
        let count = Atomic<Int>(0)
        
        let timer = HSMSLinktestTimer()
        timer.autoLinktest = { return true }
        timer.linktestDuration = { return .seconds(1.00) }
        timer.linktest = { count.add(1, ordering: .relaxed) }
        
        timer.start()
        try await Task.sleep(for: .seconds(0.50))
        timer.reset()
        try await Task.sleep(for: .seconds(0.50))
        timer.reset()
        try await Task.sleep(for: .seconds(0.50))
        timer.reset()
        try await Task.sleep(for: .seconds(0.50))
        timer.reset()
        try await Task.sleep(for: .seconds(1.50))
        timer.shutdown()
        
        #expect(count.load(ordering: .relaxed) > 0)
        #expect(count.load(ordering: .relaxed) < 3)
    }
    
    @Test func testAutolinktestCoverage() async throws {
        let count = Atomic<Int>(0)
        
        let timer = HSMSLinktestTimer()
        timer.autoLinktest = { return true }
        timer.linktestDuration = { return .seconds(0.100) }
        timer.linktest = { count.add(1, ordering: .relaxed) }
        
        timer.reset()
        timer.start()
        timer.shutdown()
        timer.shutdown()
        
    }
    
}
