//
//  HSMSMessagePipelineTest.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/04/30.
//

import Testing
import Foundation
import Network
@testable import SemiSecs

struct HSMSMessagePipelineTest {
    
    private func networkConnection() -> NWConnection {
        let host = NWEndpoint.Host("127.0.0.1")
        let port = NWEndpoint.Port(integerLiteral: 5000)
        let parameters = NWParameters.tcp
        
        let connection = NWConnection(host: host, port: port, using: parameters)
        return connection
    }
    
    private func createPipeline(timeoutT8: Duration) -> HSMSMessagePipeline {
        let instance = HSMSMessagePipeline(connection: self.networkConnection())
        instance.timeoutT8 = { timeoutT8 }
        return instance
    }
    
    @Test func testSuccess() async throws {
        let pipeline = self.createPipeline(timeoutT8: .seconds(5.0))
        
        Task {
            try await Task.sleep(for: .seconds(0.10))
            
            // SELECT.req
            pipeline.yield(data: Data([0x00, 0x00, 0x00, 0x0A]))
            pipeline.yield(data: Data([0x01, 0x02,
                                       0x00, 0x00,
                                       0x00, 0x01,
                                       0x01, 0x02, 0x03, 0x04]))
            
            try await Task.sleep(for: .seconds(0.10))
            
            // DATA
            pipeline.yield(data: Data([0x00, 0x00, 0x00, 0x0C]))
            pipeline.yield(data: Data([0x01, 0x02,
                                       0x81, 0x0D,
                                       0x00, 0x00,
                                       0x05, 0x06, 0x07, 0x08]))
            pipeline.yield(data: Data([0x01, 0x00]))
            
            pipeline.shutdown()
        }
        
        let stream = pipeline.hsmsMessageAndNWConnectionStream()
        var results: [HSMSMessage] = []
        for await result in stream {
            switch result {
            case .success(let messageAndConnection):
                results.append(messageAndConnection.message)
            case .failure(let error):
                Issue.record(error)
            }
        }
        
        #expect(results[0].messageType == .selectRequest)
        #expect(results[1].messageType == .data)
        #expect(results[1].stream == 1)
        #expect(results[1].function == 13)
        #expect(results[1].wbit == true)
        #expect(results[1].secs2Body?.type == .list)
        
    }
    
    @Test func testIllegalReceiveLengthByte() async throws {
        let pipeline = self.createPipeline(timeoutT8: .seconds(5.0))
        
        Task {
            try await Task.sleep(for: .seconds(0.10))
            
            // SELECT.req
            pipeline.yield(data: Data([0x00, 0x00, 0x00, 0x09]))
            pipeline.yield(data: Data([0x01, 0x02,
                                       0x00, 0x00,
                                       0x00, 0x01,
                                       0x01, 0x02, 0x03, 0x04]))
            
            try await Task.sleep(for: .seconds(0.10))
            
            // DATA
            pipeline.yield(data: Data([0x00, 0x00, 0x00, 0x0C]))
            pipeline.yield(data: Data([0x01, 0x02,
                                       0x81, 0x0D,
                                       0x00, 0x00,
                                       0x05, 0x06, 0x07, 0x08]))
            pipeline.yield(data: Data([0x01, 0x00]))
            
            pipeline.shutdown()
        }
        
        let stream = pipeline.hsmsMessageAndNWConnectionStream()
        var results: [Error] = []
        for await result in stream {
            switch result {
            case .success:
                Issue.record()
            case .failure(let error):
                results.append(error)
            }
        }
        
        #expect(results.count == 1)
        #expect(results[0] as! HSMSReceiveError == .illegalReceiveLengthByte)
        
    }
    
    @Test func testTimeoutT8() async throws {
        let pipeline = self.createPipeline(timeoutT8: .seconds(0.10))
        
        Task {
            try await Task.sleep(for: .seconds(0.10))
            
            // SELECT.req
            pipeline.yield(data: Data([0x00, 0x00, 0x00, 0x0A]))
            
            // timeoutT8
            try await Task.sleep(for: .seconds(0.50))
            
            pipeline.yield(data: Data([0x01, 0x02,
                                       0x00, 0x00,
                                       0x00, 0x01,
                                       0x01, 0x02, 0x03, 0x04]))
            
            try await Task.sleep(for: .seconds(0.10))
            
            // DATA
            pipeline.yield(data: Data([0x00, 0x00, 0x00, 0x0C]))
            pipeline.yield(data: Data([0x01, 0x02,
                                       0x81, 0x0D,
                                       0x00, 0x00,
                                       0x05, 0x06, 0x07, 0x08]))
            pipeline.yield(data: Data([0x01, 0x00]))
            
            pipeline.shutdown()
        }
        
        let stream = pipeline.hsmsMessageAndNWConnectionStream()
        var results: [Error] = []
        for await result in stream {
            switch result {
            case .success:
                Issue.record()
            case .failure(let error):
                results.append(error)
            }
        }
        
        #expect(results.count == 1)
        print(results[0])
        #expect(results[0] as? HSMSReceiveError == .timeoutT8)
        
    }

}
