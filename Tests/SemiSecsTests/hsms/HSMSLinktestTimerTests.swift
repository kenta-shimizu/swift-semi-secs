//
//  HSMSLinktestTimerTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/08/12.
//

import Testing
@testable import SemiSecs

struct HSMSLinktestTimerTests {

    @Test func testAutolinktestFalse() async throws {
        var count = 0
        
        let timer = HSMSLinktestTimer()
        timer.autoLinktest = { return false }
        timer.linktestDuration = { return .seconds(0.100) }
        timer.linktest = { count += 1 }
        
        await timer.start()
        try await Task.sleep(for: .seconds(0.350))
        await timer.shutdown()
        
        #expect(count == 0)
    }
    
    @Test func testAutolinktestTrue() async throws {
        var count = 0
        
        let timer = HSMSLinktestTimer()
        timer.autoLinktest = { return true }
        timer.linktestDuration = { return .seconds(0.100) }
        timer.linktest = { count += 1 }
        
        await timer.start()
        try await Task.sleep(for: .seconds(0.350))
        await timer.shutdown()
        
        #expect(count == 3)
    }
    
    @Test func testAutolinktestTrueAndReset() async throws {
        var count = 0
        
        let timer = HSMSLinktestTimer()
        timer.autoLinktest = { return true }
        timer.linktestDuration = { return .seconds(0.100) }
        timer.linktest = { count += 1 }
        
        await timer.start()
        try await Task.sleep(for: .seconds(0.050))
        await timer.reset()
        try await Task.sleep(for: .seconds(0.050))
        await timer.reset()
        try await Task.sleep(for: .seconds(0.050))
        await timer.reset()
        try await Task.sleep(for: .seconds(0.050))
        await timer.reset()
        try await Task.sleep(for: .seconds(0.150))
        await timer.shutdown()
        
        #expect(count > 0)
        #expect(count < 3)
    }
    
    @Test func testAutolinktestCoverage() async throws {
        var count = 0
        
        let timer = HSMSLinktestTimer()
        timer.autoLinktest = { return true }
        timer.linktestDuration = { return .seconds(0.100) }
        timer.linktest = { count += 1 }
        
        await timer.reset()
        await timer.start()
        await timer.start()
        await timer.shutdown()
        await timer.reset()
        await timer.start()
        await timer.shutdown()
        
    }
    
}
