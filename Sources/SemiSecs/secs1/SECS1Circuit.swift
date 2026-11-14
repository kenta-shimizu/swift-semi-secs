//
//  File.swift
//  swift-semi-secs
//
//  Created by 清水健太 on 2026/11/05.
//

import Foundation
import Synchronization

internal final class SECS1Circuit: Sendable {
    
    private let startAndShutdown = StartAndShutdown()
    private let queue = SECS1RecweiveByteAndSendMessageQueue()
    
    internal init() {
        // Nothing
    }
    
    deinit {
        self.shutdown()
    }
    
    // MARK: - closure
    
    private let _transactor = Mutex<(@Sendable () -> SECS1MessageTransactor)?>(nil)
    
    internal var transactor: (@Sendable () -> SECS1MessageTransactor)? {
        get { self._transactor.withLock { $0 } }
        set { self._transactor.withLock { $0 = newValue } }
    }
    
    private let _sender = Mutex<(@Sendable (Data) -> Void)?>(nil)
    
    internal var sender: (@Sendable (Data) -> Void)? {
        get { self._sender.withLock { $0 } }
        set { self._sender.withLock { $0 = newValue } }
    }
    
    private let _isMaster = Mutex<(@Sendable () -> Bool)?>(nil)
    
    internal var isMaster: (@Sendable () -> Bool)? {
        get { self._isMaster.withLock { $0 } }
        set { self._isMaster.withLock { $0 = newValue } }
    }
    
    private let _timeoutT1 = Mutex<(@Sendable () -> Duration)?>(nil)
    
    internal var timeoutT1: (@Sendable () -> Duration)? {
        get { self._timeoutT1.withLock { $0 } }
        set { self._timeoutT1.withLock { $0 = newValue } }
    }
    
    private let _timeoutT2 = Mutex<(@Sendable () -> Duration)?>(nil)
    
    internal var timeoutT2: (@Sendable () -> Duration)? {
        get { self._timeoutT2.withLock { $0 } }
        set { self._timeoutT2.withLock { $0 = newValue } }
    }
    
    private let _timeoutT4 = Mutex<(@Sendable () -> Duration)?>(nil)
    
    internal var timeoutT4: (@Sendable () -> Duration)? {
        get { self._timeoutT4.withLock { $0 } }
        set { self._timeoutT4.withLock { $0 = newValue } }
    }
    
    private let _retry = Mutex<(@Sendable () -> Int)?>(nil)
    
    internal var retry: (@Sendable () -> Int)? {
        get { self._retry.withLock { $0 } }
        set { self._retry.withLock { $0 = newValue } }
    }
    
    // MARK: - interface
    
    internal func yield(message: SECS1Message) {
        self.queue.yield(message: message)
    }
    
    internal func yield(receiveBytes: Data) {
        self.queue.yield(receiveBytes: receiveBytes)
    }
    
    // MARK: - circuit
    
    internal func start() throws {
        try self.startAndShutdown.start()
        Task.detached {
            do {
                try await self.circut()
            }
            catch is CancellationError {
                // Nothing
            }
            catch {
                
                // TODO
                // logging
                print(error)
            }
        }
    }
    
    internal func shutdown() {
        guard self.startAndShutdown.shutdown() == false else {
            return
        }
        self.queue.shutdown()
    }
    
    private let ENQ = UInt8(0x05)
    private let EOT = UInt8(0x04)
    private let ACK = UInt8(0x06)
    private let NAK = UInt8(0x15)
    
    private func circut() async throws {
        top: while !Task.isCancelled {
            // wait until entry
            try await queue.untilEntry()
            
            // peek first message
            if let message = try self.queue.peekFirstSendMessage() {
                for _ in 0...self.retry!() {
                    self.send(byte: ENQ)
                    guard let b = try await self.queue.pollReceiveByte(timeout: self.timeoutT2!()) else {
                        continue
                    }
                    if b == ENQ {
                        // conflict
                        if self.isMaster!() {
                            // Master, wait EOT once
                            guard let b = try await self.queue.pollReceiveByte(timeout: self.timeoutT2!()),
                                  b == EOT else {
                                continue
                            }
                            
                            // to send circuit
                            guard try await self.circuitSend(message: message) else {
                                continue
                            }
                            
                            continue top
                            
                        } else {
                            // Slave, to receive ciecuit
                            try await self.circuitReceive()
                            continue top
                        }
                        
                    } else if b == EOT {
                        
                        // to send circuit
                        guard try await self.circuitSend(message: message) else {
                            continue
                        }
                        
                        continue top
                        
                    } else {
                        continue
                    }
                }
                
                // send failed. retry over.
                try self.queue.removeFirstSendMessage()
                
                // send block failed. retry overself
                self.transactor!().yield(sendedMessage: message, error: SECS1SendError.sendFailedByRetryOver(message: message))
                
                continue top
            }
            
            // poll receive byte
            if let b = try queue.pollReceiveByte() {
                guard b == ENQ else {
                    continue top
                }
                
                // to receive circuit
                try await circuitReceive()
                
                continue top
            }
        }
    }
    
    private func send(byte: UInt8) {
        self.send(data: Data([byte]))
    }
    
    private func send(data: Data) {
        self.sender!(data)
    }
    
    private func circuitReceive() async throws {
        
        func innerReceive() async throws -> SECS1Message.Block? {
            
            func innerGarbageReceiveBytes() async throws {
                while !Task.isCancelled {
                    try self.queue.clearBytes()
                    guard let _ = try await queue.pollReceiveByte(timeout: self.timeoutT1!()) else {
                        return
                    }
                }
            }
            
            self.send(byte: EOT)
            
            // receive 1st length byte
            guard let lengthByte = try await self.queue.pollReceiveByte(timeout: self.timeoutT2!()) else {
                self.send(byte: NAK)
                return nil
            }
            
            guard (10...254).contains(lengthByte) else {
                try await innerGarbageReceiveBytes()
                self.send(byte: NAK)
                return nil
            }
            
            // receive data
            let length = Int(lengthByte) + 3
            var data: Data = Data([lengthByte])
            
            while data.count < length {
                guard let bs = try await self.queue.pollReceiveByte(capacity: (length - data.count), timeout: self.timeoutT1!()) else {
                    self.send(byte: NAK)
                    return nil
                }
                data.append(bs)
            }
            
            // sumcheck
            guard let block = SECS1Message.Block(data: data),
                  block.sumCheck else {
                try await innerGarbageReceiveBytes()
                self.send(byte: NAK)
                return nil
            }
            
            // receive block success
            self.send(byte: ACK)
            return block
        }
        
        guard let block = try await innerReceive(),
              block.blockNumber <= 1 else {
            return
        }
        
        self.transactor!().reset(block: block)
        
        var blocks: [SECS1Message.Block] = []
        blocks.append(block)
        
        // receive rest blocks
        while blocks.last!.ebit == false {
            guard let b = try await self.queue.pollReceiveByte(timeout: self.timeoutT4!()) else {
                return
            }
            guard b == ENQ else {
                continue
            }
            
            guard let block = try await innerReceive() else {
                continue
            }
            
            if blocks.last!.isSame(block: block) {
                continue
            }
            
            guard blocks.last!.isNext(block: block) else {
                return
            }
            
            self.transactor!().reset(block: block)
            blocks.append(block)
        }
        
        let message = SECS1MessageDecoder.shared.decode(blocks)
        self.transactor!().yield(receiveMessage: message)
    }
    
    /// Send 1st and rest message blocks, Returns true if 1st block send success, otherwise false.
    ///
    /// - Parameters:
    ///   - message: the SECS1Message
    /// - Returns: true if 1st block send success, otherwise false.
    /// - Throws:
    ///   - `CancellationError`: if cancelled
    private func circuitSend(message: SECS1Message) async throws -> Bool {
        
        func innerSend(block: SECS1Message.Block) async throws -> Bool {
            self.send(data: block.data)
            
            guard let b = try await self.queue.pollReceiveByte(timeout: self.timeoutT2!()),
                  b == ACK else {
                return false
            }
            
            return true
        }
        
        // send 1st block
        guard try await innerSend(block: message.blocks.first!) else {
            return false
        }
        
        // remove message from queue
        try self.queue.removeFirstSendMessage()
        
        // send rest blocks
        top: for block in message.blocks.dropFirst() {
            for _ in 0...self.retry!() {
                self.send(byte: ENQ)
                
                guard let b = try await self.queue.pollReceiveByte(timeout: self.timeoutT2!()),
                      b == EOT else {
                    continue
                }
                
                guard try await innerSend(block: block) else {
                    continue
                }
                
                // send block success, receive ACK
                continue top
            }
            
            // send block failed. retry overself
            self.transactor!().yield(sendedMessage: message, error: SECS1SendError.sendFailedByRetryOver(message: message))
            
            return true
        }
        
        // success all blocks
        self.transactor!().yield(sendedMessage: message, error: nil)

        return true
    }
    
}
