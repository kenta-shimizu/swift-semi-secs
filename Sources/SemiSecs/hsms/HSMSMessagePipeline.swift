//
//  HSMSMessagePipeline.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/04/27.
//

import Foundation
import Network

internal final class HSMSMessagePipeline: Sendable {
    
    private let (byteStream, byteContinuation) = AsyncStream.makeStream(of: UInt8.self)
    
    private let connection: NWConnection
    internal nonisolated(unsafe) var timeoutT8: (@Sendable () -> Duration)?
    
    internal init(connection: NWConnection) {
        self.connection = connection
        self.timeoutT8 = nil
    }
    
    internal func shutdown() {
        self.byteContinuation.finish()
    }
    
    internal func yield(data: Data) {
        self.byteContinuation.yield(data: data)
    }
    
    internal func hsmsMessageAndNWConnectionStream() -> AsyncStream<Result<HSMSMessageAndNWConnection, Error>> {
        AsyncStream<Result<HSMSMessageAndNWConnection, Error>> { continuation in
            Task.detached { [weak self] in
                guard let self = self else { return }
                do {
                    while !Task.isCancelled {
                        let lengthData = try await self.readLengthData()
                        let bodyDataCount = ((Int(lengthData[0]) << 24) | (Int(lengthData[1]) << 16) | (Int(lengthData[2]) << 8) | Int(lengthData[3]))
                        guard bodyDataCount >= 10 else {
                            throw HSMSReceiveError.illegalReceiveLengthByte
                        }
                        let headerData = try await self.readHeaderData()
                        let bodyData = try await self.readBodyData(length: bodyDataCount - 10)
                        let message = HSMSMessageDecoder.shared.decode(header10Bytes: headerData, secs2BodyData: bodyData)
                        let hsmsMessageAndNWConnection = HSMSMessageAndNWConnection(message: message, connection: self.connection)
                        continuation.yield(.success(hsmsMessageAndNWConnection))
                    }
                }
                catch let error as HSMSReceiveError {
                    continuation.yield(.failure(error))
                }
                catch {
                }
                
                continuation.finish()
            }
        }
    }
    
    private func pollByte() async throws -> UInt8 {
        guard let result = try await self.byteStream.poll(timeout: self.timeoutT8!()) else {
            throw HSMSReceiveError.timeoutT8;
        }
        return result;
    }
    
    private func readLengthData() async throws -> Data {
        var data = Data([])
        data.append(try await self.byteStream.take());
        while data.count < 4 {
            data.append(try await self.pollByte());
        }
        return data;
    }
    
    private func readHeaderData() async throws -> Data {
        var data = Data([])
        while data.count < 10 {
            data.append(try await self.pollByte());
        }
        return data;
    }
    
    private func readBodyData(length: Int) async throws -> Data {
        var data = Data([])
        while data.count < length {
            data.append(try await self.pollByte());
        }
        return data;
    }
    
}
