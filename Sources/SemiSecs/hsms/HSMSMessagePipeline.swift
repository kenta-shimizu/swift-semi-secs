//
//  HSMSMessagePipeline.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/04/27.
//

import Foundation

internal actor HSMSMessagePipeline: AsyncShutdownable {
    
    private let queue: AsyncQueue<UInt8> = AsyncQueue()
    internal nonisolated(unsafe) var timeoutT8: (() -> TimeInterval)?
    internal nonisolated(unsafe) var onDidSink: ((HSMSMessage) async -> Void)?
    internal nonisolated(unsafe) var onDidDetectHSMSError: ((HSMSError) async -> Void)?
    
    internal init() {
        self.timeoutT8 = nil
        self.onDidDetectHSMSError = nil
        self.onDidSink = nil
    }
    
    internal func start() async {
        Task.detached {
            do {
                let lengthDataCount = 4
                let headerDataCount = 10
                
                while !Task.isCancelled {
                    
                    var lengthData = try await self.take(maxDataCount: lengthDataCount)
                    
                    while lengthData.count < lengthDataCount {
                        try await lengthData.append(self.poll(maxDataCount: (lengthDataCount - lengthData.count)))
                    }
                    
                    let bodyDataCount = ((Int(lengthData[0]) << 24) | (Int(lengthData[1]) << 16) | (Int(lengthData[2]) << 8) | Int(lengthData[3])) - headerDataCount
                    
                    guard bodyDataCount >= 0 else {
                        throw HSMSError.illegalReceiveLengthByte
                    }
                    
                    var headerData = Data([])
                    while headerData.count < headerDataCount {
                        try await headerData.append(self.poll(maxDataCount: (headerDataCount - headerData.count)))
                    }
                    
                    var bodyData = Data([])
                    while bodyData.count < bodyDataCount {
                        try await bodyData.append(self.poll(maxDataCount: (bodyDataCount - bodyData.count)))
                    }
                    
                    let message = HSMSMessageDecoder.shared.decode(header10Bytes: headerData, secs2BodyData: bodyData)
                    
                    await self.onDidSink?(message)
                }
            }
            catch let error as HSMSError {
                await self.onDidDetectHSMSError?(error)
            }
            catch {
                // ignore
            }
            
            await self.shutdown()
        }
    }
    
    private func take(maxDataCount: Int) async throws -> Data {
        return try await self.queue.take(maxDataCount: maxDataCount)
    }
    
    private func poll(maxDataCount: Int) async throws -> Data {
        guard let timeout = self.timeoutT8?() else {
            throw AsyncShutdownError.alreadyShutdowned
        }
        guard let data = try await self.queue.poll(maxDataCount: maxDataCount, timeout: timeout) else {
            throw HSMSError.timeoutT8
        }
        return data
    }
    
    internal func shutdown() async {
        await self.queue.shutdown()
        self.timeoutT8 = nil
        self.onDidDetectHSMSError = nil
        self.onDidSink = nil
    }
    
    internal func put(source: Data) async throws {
        try await self.queue.put(data: source)
    }
    
}
