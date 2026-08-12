//
//  AsyncStream+ExtensionTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/06/21.
//

import Testing
import Foundation
@testable import SemiSecs

struct AsyncStreamExtensionTests {

    @Test func testTakeAndFinish() async throws {
        
        let s1 = "aaa"
        let s2 = "bbb"
        let s3 = "ccc"
        
        let (stream, continuation) = AsyncStream.makeStream(of: String.self)
        
        continuation.yield(s1)
        continuation.yield(s2)
        
        let r1 = try await stream.take()
        let r2 = try await stream.take()
        
        Task {
            try await Task.sleep(for: .seconds(0.10))
            continuation.yield(s3)
        }
        
        let r3 = try await stream.take()
        
        #expect(r1 == s1)
        #expect(r2 == s2)
        #expect(r3 == s3)
        
        continuation.finish()
        await #expect(throws: CancellationError.self) {
            let _ = try await stream.take()
        }
        
        continuation.yield(s3)
        await #expect(throws: CancellationError.self) {
            let _ = try await stream.take()
        }
    }
    
    @Test func testTakeAndCancel() async throws {
        
        let s1 = "aaa"
        
        let (stream, continuation) = AsyncStream.makeStream(of: String.self)
        
        let task = Task {
            await #expect(throws: CancellationError.self) {
                let _ = try await stream.take()
            }
        }
        
        task.cancel()
        try await Task.sleep(for: .seconds(0.10))
        
        await #expect(throws: CancellationError.self) {
            let _ = try await stream.take()
        }

        continuation.yield(s1)
        await #expect(throws: CancellationError.self) {
            let _ = try await stream.take()
        }
    }
    
    @Test func testPollAndFinish() async throws {
        
        let s1 = "aaa"
        let s2 = "bbb"
        let s3 = "ccc"
        
        let (stream, continuation) = AsyncStream.makeStream(of: String.self)
        
        continuation.yield(s1)
        continuation.yield(s2)
        
        let r1 = try await stream.poll(timeout: .seconds(0.10))
        let r2 = try await stream.poll(timeout: .seconds(0.10))
        
        Task {
            try await Task.sleep(for: .seconds(0.01))
            continuation.yield(s3)
        }
        
        let r3 = try await stream.poll(timeout: .seconds(0.10))
        
        #expect(r1 == s1)
        #expect(r2 == s2)
        #expect(r3 == s3)
        
        continuation.finish()
        await #expect(throws: CancellationError.self) {
            let _ = try await stream.poll(timeout: .seconds(0.10))
        }
        
        continuation.yield(s3)
        await #expect(throws: CancellationError.self) {
            let _ = try await stream.poll(timeout: .seconds(0.10))
        }
    }
    
    @Test func testPollAndCancel() async throws {
        
        let s1 = "aaa"
        
        let (stream, continuation) = AsyncStream.makeStream(of: String.self)
        
        let task = Task {
            await #expect(throws: CancellationError.self) {
                let _ = try await stream.poll(timeout: .seconds(0.10))
            }
        }
        
        task.cancel()
        try await Task.sleep(for: .seconds(0.10))
        
        await #expect(throws: CancellationError.self) {
            let _ = try await stream.poll(timeout: .seconds(0.10))
        }

        continuation.yield(s1)
        await #expect(throws: CancellationError.self) {
            let _ = try await stream.poll(timeout: .seconds(0.10))
        }
    }
    
    @Test func testPollAndTimeout() async throws {
        
        let s1 = "aaa"
        
        let (stream, continuation) = AsyncStream.makeStream(of: String.self)
        
        let r = try await stream.poll(timeout: .seconds(0.10))
        #expect(r == nil)
        
        continuation.yield(s1)
        await #expect(throws: CancellationError.self) {
            let _ = try await stream.poll(timeout: .seconds(0.10))
        }
    }
    
    @Test func testData() async throws {
        
        let a: UInt8 = 0x01
        let b: UInt8 = 0x02
        let c: UInt8 = 0x03
        let data = Data([a, b, c])
        
        let (stream, continuation) = AsyncStream.makeStream(of: UInt8.self)
        
        continuation.yield(data: data)
        
        let r1 = try await stream.take()
        let r2 = try await stream.take()
        let r3 = try await stream.take()
        
        #expect(r1 == a)
        #expect(r2 == b)
        #expect(r3 == c)
    }

}
