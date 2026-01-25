//
//  AsyncStreamNotifierTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/24.
//

import Testing
@testable import SemiSecs

struct AsyncStreamNotifierTests {

    @Test func test() async throws {
        
        let s1 = "a"
        let s2 = "b"
        
        let notifier = AsyncStreamNotifier<String>()
        
        try await notifier.append {
            #expect($0 == s1)
        }
        
        try await notifier.put(s1)
        
        // waiting until notified
        try await Task.sleep(for: .seconds(0.5))
        
        await notifier.shutdown()
        
        await #expect(throws: AsyncShutdownError.self) {
            try await notifier.append {
                #expect($0 == s2)
            }
        }
        
        await #expect(throws: AsyncShutdownError.self) {
            try await notifier.put(s2)
        }
        
    }

}
