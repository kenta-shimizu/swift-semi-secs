//
//  AsyncQueueTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/11.
//

import Testing
import Foundation
@testable import SemiSecs

@Suite struct AsyncQueueTests {

    @Test func testTake() async throws {
        
        let queue = AsyncQueue<String>()
        
        let s1 = "a"
        let s2 = "b"
        
        try await queue.put(s1)
        try await queue.put(s2)

        let r1 = try await queue.take()
        let r2 = try await queue.take()
        
        #expect(r1 == s1)
        #expect(r2 == s2)
        
        // test waiting until put
        let s3 = "c"
        Task {
            try await Task.sleep(for: .seconds(0.5))
            try await queue.put(s3)
        }
        
        let r3 = try await queue.take()
        #expect(r3 == s3)
        
        // test shutdown
        Task {
            try await Task.sleep(for: .seconds(0.5))
            await queue.shutdown()
        }
        
        await #expect(throws: AsyncShutdownError.self) {
            try await queue.take()
        }
        
        // test already shutdown
        await #expect(throws: AsyncShutdownError.self) {
            try await queue.take()
        }
        
    }
    
    @Test func testPoll() async throws {
        
        let queue = AsyncQueue<String>()
        
        let s1 = "a"
        let s2 = "b"
        
        try await queue.put(s1)
        try await queue.put(s2)
        
        let r1 = try await queue.poll()
        let r2 = try await queue.poll()
        let r3 = try await queue.poll()
        
        #expect(r1 == s1)
        #expect(r2 == s2)
        #expect(r3 == nil)
        
        try await queue.put(s1)
        await queue.shutdown()
        
        await #expect(throws: AsyncShutdownError.self) {
            try await queue.poll()
        }

        await #expect(throws: AsyncShutdownError.self) {
            try await queue.put(s2)
        }

    }
    
    @Test func testPollWithTimeout() async throws {
        
        let queue = AsyncQueue<String>()
        
        let s1 = "a"
        let s2 = "b"
        
        try await queue.put(s1)
        try await queue.put(s2)
        
        let r1 = try await queue.poll(timeout: 0.5)
        let r2 = try await queue.poll(timeout: 0.5)

        #expect(r1 == s1)
        #expect(r2 == s2)
        
        // waiting until put
        let s3 = "c"
        Task {
            try await Task.sleep(for: .seconds(0.5))
            try await queue.put(s3)
        }
        
        let r3 = try await queue.poll(timeout: 1.0)
        #expect(r3 == s3)
        
        // test shutdown
        Task {
            try await Task.sleep(for: .seconds(0.5))
            await queue.shutdown()
        }
        
        await #expect(throws: AsyncShutdownError.self) {
            try await queue.poll(timeout: 1.0)
        }
        
        // test already shutdown
        await #expect(throws: AsyncShutdownError.self) {
            try await queue.poll(timeout: 1.0)
        }
        
    }
    
    @Suite struct DataTests {
        
        @Test func testTake() async throws {
            
            let bytes1: [UInt8] = [0x1, 0x2]
            let bytes2: [UInt8] = [0x3, 0x4]
            let bytes3: [UInt8] = [0x5, 0x6]

            let data1 = Data(bytes1)
            let data2 = Data(bytes2)
            let data3 = Data(bytes3)

            let queue = AsyncQueue<UInt8>()
            
            try await queue.put(data: data1)
            try await queue.put(data: data2)
            try await queue.put(data: data3)
            
            let r1 = try await queue.take(maxDataCount: 4)
            let r2 = try await queue.take(maxDataCount: 4)
            
            #expect(r1 == (data1 + data2))
            #expect(r2 == data3)
            
            // waiting until put count < maxCount
            Task {
                try await Task.sleep(for: .seconds(0.5))
                try await queue.put(data: data1)
            }
            
            let r3 = try await queue.take(maxDataCount: 4)
            #expect(r3 == data1)
            
            // waiting until put count > maxCount
            Task {
                try await Task.sleep(for: .seconds(0.5))
                try await queue.put(data: (data1 + data2 + data3))
            }
            
            let r4 = try await queue.take(maxDataCount: 4)
            #expect(r4 == (data1 + data2))
            
            let r5 = try await queue.take(maxDataCount: 4)
            #expect(r5 == data3)
            
            // test shutdown
            Task {
                try await Task.sleep(for: .seconds(0.5))
                await queue.shutdown()
            }
            
            await #expect(throws: AsyncShutdownError.self) {
                try await queue.take(maxDataCount: 4)
            }
            
            // test already shutdown
            await #expect(throws: AsyncShutdownError.self) {
                try await queue.take(maxDataCount: 4)
            }

        }

        @Test func testPollWithTimeout() async throws {
            
            let bytes1: [UInt8] = [0x1, 0x2]
            let bytes2: [UInt8] = [0x3, 0x4]
            let bytes3: [UInt8] = [0x5, 0x6]

            let data1 = Data(bytes1)
            let data2 = Data(bytes2)
            let data3 = Data(bytes3)

            let queue = AsyncQueue<UInt8>()
            
            try await queue.put(data: data1)
            try await queue.put(data: data2)
            try await queue.put(data: data3)
            
            let r1 = try await queue.poll(maxDataCount: 4, timeout: 1.0)
            let r2 = try await queue.poll(maxDataCount: 4, timeout: 1.0)
            let r3 = try await queue.poll(maxDataCount: 4, timeout: 0.1)
            
            #expect(r1 == (data1 + data2))
            #expect(r2 == data3)
            #expect(r3 == nil)
            
            // waiting until put count < maxCount
            Task {
                try await Task.sleep(for: .seconds(0.5))
                try await queue.put(data: data1)
            }
            
            let r4 = try await queue.poll(maxDataCount: 4, timeout: 1.0)
            #expect(r4 == data1)
            
            // waiting until put count > maxCount
            Task {
                try await Task.sleep(for: .seconds(0.5))
                try await queue.put(data: (data1 + data2 + data3))
            }
            
            let r5 = try await queue.poll(maxDataCount: 4, timeout: 1.0)
            #expect(r5 == (data1 + data2))
            
            let r6 = try await queue.poll(maxDataCount: 4, timeout: 1.0)
            #expect(r6 == data3)
            
            Task {
                try await Task.sleep(for: .seconds(0.2))
                try await queue.put(data: Data())
            }
            
            // waiting until put count == 0
            let r7 = try await queue.poll(maxDataCount: 4, timeout: 0.5)
            #expect(r7 == nil)
            
            // test shutdown
            Task {
                try await Task.sleep(for: .seconds(0.5))
                await queue.shutdown()
            }
            
            await #expect(throws: AsyncShutdownError.self) {
                try await queue.poll(maxDataCount: 4, timeout: 1.0)
            }
            
            // test already shutdown
            await #expect(throws: AsyncShutdownError.self) {
                try await queue.poll(maxDataCount: 4, timeout: 1.0)
            }
        }
        
    }
    
}
