//
//  HSMSMessagePipelineTest.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/04/30.
//

import Testing
import Foundation
@testable import SemiSecs

struct HSMSMessagePipelineTest {

    @Test func testSuccess() async throws {
        
        var sinkMessages: [HSMSMessage] = []
        
        let pipeline = HSMSMessagePipeline()
        pipeline.timeoutT8 = { 0.5 }
        pipeline.onDidSink = {
            sinkMessages.append($0)
        }
        
        do {
            await pipeline.start()
            
            try await pipeline.put(source: Data([0x00, 0x00, 0x00, 0x0A,
                                                 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x01, 0x01, 0x23, 0x00, 0x01]))
            
            try await Task.sleep(for: .seconds(1.5))
            
            try await pipeline.put(source: Data([0x00, 0x00, 0x00, 0x0C,
                                                 0x01, 0x23, 0x01, 0x0D, 0x00, 0x00, 0x01, 0x23, 0x00, 0x02,
                                                 0x01, 0x00]))
            
            try await Task.sleep(for: .seconds(1.5))
            
            await pipeline.shutdown()
        }
        catch {
            await pipeline.shutdown()
        }
        
        #expect(sinkMessages[0].messageType == .selectRequest)
        #expect(sinkMessages[1].messageType == .data)
        #expect(sinkMessages[1].stream == 1)
        #expect(sinkMessages[1].function == 13)
        #expect(sinkMessages[1].wbit == false)
        #expect(sinkMessages[1].secs2Body?.type == .list)
        #expect(sinkMessages[1].secs2Body?.count == 0)
        
    }
    
    @Test func testTimeoutT8() async throws {
        
        var sinkMessages: [HSMSMessage] = []
        var error: HSMSError? = nil
        
        let pipeline = HSMSMessagePipeline()
        pipeline.timeoutT8 = { 0.5 }
        pipeline.onDidSink = {
            sinkMessages.append($0)
        }
        pipeline.onDidDetectHSMSError = {
            if case .timeoutT8 = $0 {
                error = $0
            }
        }
        
        do {
            await pipeline.start()
            
            try await pipeline.put(source: Data([0x00, 0x00, 0x00, 0x0A,
                                                 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x01, 0x01, 0x23, 0x00, 0x01]))
            
            try await Task.sleep(for: .seconds(1.5))
            
            try await pipeline.put(source: Data([0x00]))
            
            try await Task.sleep(for: .seconds(1.5))    // timeout-T8
            
            try await pipeline.put(source: Data([0x00, 0x00, 0x0C,
                                                 0x01, 0x23, 0x01, 0x0D, 0x00, 0x00, 0x01, 0x23, 0x00, 0x02,
                                                 0x01, 0x00]))
            
            Issue.record("timeoutError")
            
            try await Task.sleep(for: .seconds(1.5))
            
            await pipeline.shutdown()
        }
        catch {
            // through here
            await pipeline.shutdown()
        }
        
        #expect(sinkMessages.count == 1)
        #expect(error != nil)
    }
    
    @Test func testIllegalReceiveLengthByte() async throws {
        
        var sinkMessages: [HSMSMessage] = []
        var error: HSMSError? = nil
        
        let pipeline = HSMSMessagePipeline()
        pipeline.timeoutT8 = { 0.5 }
        pipeline.onDidSink = {
            sinkMessages.append($0)
        }
        pipeline.onDidDetectHSMSError = {
            if case .illegalReceiveLengthByte = $0 {
                error = $0
            }
        }
        
        do {
            await pipeline.start()
            
            try await pipeline.put(source: Data([0x00, 0x00, 0x00, 0x0A,
                                                 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x01, 0x01, 0x23, 0x00, 0x01]))
            
            try await Task.sleep(for: .seconds(1.5))
            
            try await pipeline.put(source: Data([0x00, 0x00, 0x00, 0x09,
                                                 0x01, 0x23, 0x01, 0x0D, 0x00, 0x00, 0x01, 0x23, 0x00, 0x02,
                                                 0x01, 0x00]))  // Illegal-Receive-length-byte
            
            try await Task.sleep(for: .seconds(1.5))
            
            try await pipeline.put(source: Data([0x00, 0x00, 0x00, 0x0A,
                                                 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x05, 0x01, 0x23, 0x00, 0x03]))  // put Linktest.req, already shutdowned.
            
            Issue.record("IllegalReceiveLengthByteError")
            
            try await Task.sleep(for: .seconds(1.5))

            await pipeline.shutdown()
        }
        catch {
            // through here
            await pipeline.shutdown()
        }
        
        #expect(sinkMessages.count == 1)
        #expect(error != nil)
    }

}
