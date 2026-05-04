//
//  HSMSCommunicator.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Foundation
import Network

public enum HSMSError: SECSError {
    
    // send
    case sendFailed(message: HSMSMessage, connection: NWConnection, cause: Error)
    case sendFailedByCommunicatorShutdowned(messageType: HSMSMessage.MessageType, smlMessage: SMLMessage)
    case sendFailedByCommunicatorShutdowned(messageType: HSMSMessage.MessageType, primaryMessage: SECSMessage, smlMessage: SMLMessage)
    case sendFailedByCommunicatorShutdowned(messageType: HSMSMessage.MessageType)
    case sendFailedByCommunicatorShutdowned(messageType: HSMSMessage.MessageType, primaryMessage: HSMSMessage)
    case sendFailedByCommunicatorShutdowned(messageType: HSMSMessage.MessageType, referenceMessage: HSMSMessage)
    case sendFailedByCommunicatorShutdowned(message: HSMSMessage)
    case sendFailedByCommunicatorShutdowned(message: HSMSMessage, connection: NWConnection)
    case sendFailedByNotConnected(message: HSMSMessage)
    
    // waitReply
    case waitReplyFailedByTransactionShutdown(primaryMessage: HSMSMessage, connection: NWConnection)
    case timeoutT3(primaryMessage: HSMSMessage, connection: NWConnection)
    case timeoutT6(primaryMessage: HSMSMessage, connection: NWConnection)
    case rejectRequest(primaryMessage: HSMSMessage, rejectRequestMessage: HSMSMessage, connection: NWConnection)
    
    // error
    case timeoutT8
    case illegalReceiveLengthByte
    
    public var description: String {
        return String(describing: type(of: self))
    }
    
    public var debugDescription: String {
        return self.description;
    }
}

public class HSMSCommunicator: SECSCommunicator<HSMSMessage> {
    
    public enum HSMSConnectionMode {
        case active
        case passive
    }
    
    public enum HSMSConnectionState: String {
        case notStarted = "NOT_STARTED"
        case notConnected = "NOT_CONNECTED"
        case notSelected = "NOT_SELECTED"
        case selected = "SELECTED"
    }
    
    internal class HSMSMessageTransaction: SECSMessageTransaction {
        
        internal override init() {
            super.init()
        }
        
        internal override func isWaitReply(message: HSMSMessage) -> Bool {
            switch message.messageType {
            case .data:
                return super.isWaitReply(message: message)
            case .selectRequest, .deselectRequest, .linktestRequest:
                return true
            default:
                return false
            }
        }
        
    }
    
    internal class HSMSMessageReceiver: ShutdownableBase {
        
        private let dataQueue = BlockingDataQueue()
        private let hsmsMessageQueue = BlockingQueue<HSMSMessage>()
        private let semaphore = DispatchSemaphore(value: 1)
        
        internal override init() {
            
            super.init()
            
            self.append(shutdownable: self.dataQueue)
            self.append(shutdownable: self.hsmsMessageQueue)
            
            DispatchQueue.global().async {
                do {
                    try self.runTask()
                }
                catch HSMSError.timeoutT8 {
                    // Nothing
                }
                catch {
                    // Nothing
                }

                self.shutdown()
            }
        }
        
        internal override func shutdown() {
            self.semaphore.wait()
            if !self.shutdowned {
                super.shutdown()
            }
            self.semaphore.signal()
        }
        
        internal func getTiemoutT8() -> Double {
            fatalError("must override")
        }
        
        internal func put(_ data: Data) throws {
            do {
                try self.dataQueue.put(data)
            }
            catch {
                self.shutdown()
                throw ShutdownError.alreadyShutdowned
            }
        }
        
        internal func take() throws -> HSMSMessage {
            do {
                return try self.hsmsMessageQueue.take()
            }
            catch {
                self.shutdown()
                throw ShutdownError.alreadyShutdowned
            }
        }
        
        private static let lengthBytesMaxCount = 4
        private static let header10BytesMaxCount = 10
        
        private func runTask() throws {
            
            while !self.shutdowned {
                
                var lengthBytes = Data()
                var header10Bytes = Data()
                var bodyBytes = Data()
                
                lengthBytes.append(try self.dataQueue.take(Self.lengthBytesMaxCount))
 
                while lengthBytes.count < Self.lengthBytesMaxCount {
                    guard let data = try self.dataQueue.poll(Self.lengthBytesMaxCount - lengthBytes.count, timeout: self.getTiemoutT8()) else {
                        throw HSMSError.timeoutT8
                    }
                    lengthBytes.append(data)
                }
                
                while header10Bytes.count < Self.header10BytesMaxCount {
                    guard let data = try self.dataQueue.poll(Self.header10BytesMaxCount - header10Bytes.count, timeout: self.getTiemoutT8()) else {
                        throw HSMSError.timeoutT8
                    }
                    header10Bytes.append(data)
                }
                
                let uint32Value = lengthBytes.withUnsafeBytes { ptr in
                    UInt32(bigEndian: ptr.load(as: UInt32.self))
                }
                guard let intValue = Int(exactly: uint32Value) else {
                    return
                }
                let bodyBytesMaxCount = intValue - 10
                guard bodyBytesMaxCount >= 0 else {
                    return
                }
                
                while bodyBytes.count < bodyBytesMaxCount {
                    guard let data = try self.dataQueue.poll(bodyBytesMaxCount - bodyBytes.count, timeout: self.getTiemoutT8()) else {
                        throw HSMSError.timeoutT8
                    }
                    bodyBytes.append(data)
                }
                
                let message = HSMSMessageDecoder.shared.decode(header10Bytes: header10Bytes, secs2BodyData: bodyBytes)
                try self.hsmsMessageQueue.put(message)
            }
        }
    }
    
    internal class HSMSLinktest {
        
        private let condition = NSCondition()
        private var shutdowned: Bool

        internal init() {
            self.shutdowned = false
        }
        
        deinit {
            self.shutdown()
        }
        
        internal func shutdown() {
            self.condition.lock()
            if !self.shutdowned {
                self.shutdowned = true
                self.condition.broadcast()
            }
            self.condition.unlock()
        }
        
        internal func getDoLinktest() -> Bool {
            fatalError("must override")
        }
        
        internal func getLinktestCycle() -> Double {
            fatalError("must override")
        }
        
        internal func reset() {
            self.condition.lock()
            self.condition.broadcast()
            self.condition.unlock()
        }
        
        internal func start(linktest: @escaping () -> Void) {
            
            weak let weakSelf = self
            let condition = self.condition
            
            DispatchQueue.global().async {
                condition.lock()
                defer {
                    condition.unlock()
                }
                while true {
                    guard let ws = weakSelf else {
                        break
                    }
                    guard !ws.shutdowned else {
                        break;
                    }
                    
                    if ws.getDoLinktest() {
                        if !condition.wait(until: Date().addingTimeInterval(ws.getLinktestCycle())) {
                            linktest()
                        }
                    } else {
                        condition.wait()
                    }
                }
            }
        }
    }
    
    public class HSMSSession {
        
        private let stateSemaphore = DispatchSemaphore(value: 1)
        internal weak var transaction: HSMSMessageTransaction?
        
        private let hsmsConnectionStateChangeNotifier = StateChangeNotifier<HSMSConnectionState>(.notStarted)
        
        public var stateUpdateHandler: (@Sendable (_ state: HSMSCommunicator.HSMSConnectionState) -> Void)?
        
        internal let receiveHSMSMessageNotifier = BlockingQueueAndNotifier<HSMSMessage>()
        
        public var primaryMessageReceiveHandler: (@Sendable (_ message: HSMSMessage) -> Void)?
        
        internal init() {
            self.transaction = nil
            self.stateUpdateHandler = nil
            self.primaryMessageReceiveHandler = nil
            
            self.hsmsConnectionStateChangeNotifier.append {
                self.stateUpdateHandler?($0)
            }
            self.receiveHSMSMessageNotifier.append {
                self.primaryMessageReceiveHandler?($0)
            }
        }
        
        deinit {
            self.shutdown()
        }
        
        internal func shutdown() {
            self.transaction = nil
            self.stateUpdateHandler = nil
            self.primaryMessageReceiveHandler = nil
        }
        
        public var sessionId: UInt16 {
            fatalError("Must override")
        }
        
        public var connectionState: HSMSConnectionState {
            stateSemaphore.wait()
            defer {
                stateSemaphore.signal()
            }
            return self.hsmsConnectionStateChangeNotifier.state
        }
        
        @discardableResult
        public func waitUntilSelected() -> Bool {
            do {
                try self.hsmsConnectionStateChangeNotifier.waitUntil(.selected)
                return true
            }
            catch {
                return false
            }
        }
        
        @discardableResult
        public func waitUntilSelected(timeout: Double) -> Bool {
            do {
                return try self.hsmsConnectionStateChangeNotifier.waitUntil(.selected, timeout: timeout)
            }
            catch {
                return false
            }
        }
        
        @discardableResult
        public func waitUntilNotSelected() -> Bool {
            do {
                try self.hsmsConnectionStateChangeNotifier.waitUntilNot(.selected)
                return true
            }
            catch {
                return false
            }
        }
        
        @discardableResult
        public func waitUntilNotSelected(timeout: Double) -> Bool {
            do {
                return try self.hsmsConnectionStateChangeNotifier.waitUntilNot(.selected, timeout: timeout)
            }
            catch {
                return false
            }
        }
        
        internal func set(connectionState: HSMSConnectionState) {
            stateSemaphore.wait()
            self.hsmsConnectionStateChangeNotifier.set(connectionState)
            self.putDebugLog(connectionState: connectionState)
            stateSemaphore.signal()
        }
        
        internal func set(connectionState: HSMSConnectionState, transaction: HSMSMessageTransaction?) {
            stateSemaphore.wait()
            self.transaction = transaction
            self.hsmsConnectionStateChangeNotifier.set(connectionState)
            self.putDebugLog(connectionState: connectionState)
            stateSemaphore.signal()
        }
        
        internal func trySet(transaction: HSMSMessageTransaction) -> Bool {
            stateSemaphore.wait()
            defer {
                stateSemaphore.signal()
            }
            if self.transaction == nil {
                self.transaction = transaction
                return true
            } else {
                return false
            }
        }
        
        internal func putDebugLog(connectionState: HSMSConnectionState) {
            fatalError("must override")
        }
        
        internal var messageBuilder: any HSMSMessageBuildable {
            fatalError("Must override")
        }
        
        @discardableResult
        public func send(hsmsMessage: HSMSMessage) throws -> HSMSMessage? {
            fatalError("Must override")
        }
        
        @discardableResult
        public func asyncSend(hsmsMessage: HSMSMessage) async -> Result<HSMSMessage?, Error> {
            do {
                return Result.success(try self.send(hsmsMessage: hsmsMessage))
            }
            catch {
                return  Result.failure(error)
            }
        }
        
        @discardableResult
        public func send(stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2Body)?) throws -> HSMSMessage? {
            let smlMessage = SMLMessage(stream: stream, function: function, wbit: wbit, secs2Body: secs2Body)
            return try self.send(smlMessage: smlMessage)
        }
        
        @discardableResult
        public func send(smlMessage: SMLMessage) throws -> HSMSMessage? {
            let primaryMessage = self.messageBuilder.buildPrimaryData(sessionId: self.sessionId, smlMessage: smlMessage)
            if let r = try self.send(hsmsMessage: primaryMessage) {
                if r.messageType == .rejectRequest {
//                    throw HSMSError.rejectRequest(primaryMessage: primaryMessage, rejectRequestMessage: r)
                }
                return r;
            } else {
                return nil
            }
        }
        
        @discardableResult
        public func asyncSend(stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2Body)?) async -> Result<HSMSMessage?, Error> {
            let smlMessage = SMLMessage(stream: stream, function: function, wbit: wbit, secs2Body: secs2Body)
            return await self.asyncSend(smlMessage: smlMessage)
        }
        
        @discardableResult
        public func asyncSend(smlMessage: SMLMessage) async -> Result<HSMSMessage?, Error> {
            return await self.asyncSend(hsmsMessage: self.messageBuilder.buildPrimaryData(sessionId: self.sessionId, smlMessage: smlMessage) )
        }
        
        public func reply(primaryMessage: HSMSMessage, stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2Body)?) throws {
            let smlMessage = SMLMessage(stream: stream, function: function, wbit: wbit, secs2Body: secs2Body)
            try self.reply(primaryMessage: primaryMessage, smlMessage: smlMessage)
        }
        
        public func reply(primaryMessage: HSMSMessage, smlMessage: SMLMessage) throws {
            try self.send(hsmsMessage: self.messageBuilder.buildResponseData(primaryMessage: primaryMessage, smlMessage: smlMessage))
        }
        
        @discardableResult
        public func asyncReply(primaryMessage: HSMSMessage, stream: UInt8, function: UInt8, wbit: Bool, secs2Body: (any SECS2Body)?) async -> Result<HSMSMessage?, Error> {
            let smlMessage = SMLMessage(stream: stream, function: function, wbit: wbit, secs2Body: secs2Body)
            return await self.asyncReply(primaryMessage: primaryMessage, smlMessage: smlMessage)
        }
        
        public func asyncReply(primaryMessage: HSMSMessage, smlMessage: SMLMessage) async -> Result<HSMSMessage?, Error> {
            return await self.asyncSend(hsmsMessage: self.messageBuilder.buildResponseData(primaryMessage: primaryMessage, smlMessage: smlMessage))
        }
        
        
        public func sendSelectRequest() throws -> HSMSMessage? {
            return try self.send(hsmsMessage: self.messageBuilder.buildSelectRequest(sessionId: self.sessionId) )
        }
        
        @discardableResult
        public func asyncSendSelectRequest() async -> Result<HSMSMessage?, Error> {
            return await self.asyncSend(hsmsMessage: self.messageBuilder.buildSelectRequest(sessionId: self.sessionId))
        }
        
        public func replySelectResponse(primaryMessage: HSMSMessage, status: HSMSMessage.SelectStatus) throws {
            try self.send(hsmsMessage: self.messageBuilder.buildSelectResponse(selectRequest: primaryMessage, selectStatus: status))
        }
        
        @discardableResult
        public func asyncReplySelectResponse(primaryMessage: HSMSMessage, status: HSMSMessage.SelectStatus) async -> Result<HSMSMessage?, Error> {
            return await self.asyncSend(hsmsMessage: self.messageBuilder.buildSelectResponse(selectRequest: primaryMessage, selectStatus: status))
        }
        
        @discardableResult
        public func sendDeselectRequest() throws -> HSMSMessage? {
            return try self.send(hsmsMessage: self.messageBuilder.buildDeselectRequest(sessionId: self.sessionId))
        }
        
        @discardableResult
        public func asyncSendDeselectRequest() async -> Result<HSMSMessage?, Error> {
            return await self.asyncSend(hsmsMessage: self.messageBuilder.buildDeselectRequest(sessionId: self.sessionId))
        }
        
        public func replyDeselectResponse(primaryMessage: HSMSMessage, status: HSMSMessage.DeselectStatus) throws {
            try self.send(hsmsMessage: self.messageBuilder.buildDeselectResponse(deselectRequest: primaryMessage, deselectStatus: status))
        }
        
        @discardableResult
        public func asyncReplyDeselectResponse(primaryMessage: inout HSMSMessage, status: HSMSMessage.DeselectStatus) async -> Result<HSMSMessage?, Error> {
            return await self.asyncSend(hsmsMessage: self.messageBuilder.buildDeselectResponse(deselectRequest: primaryMessage, deselectStatus: status))
        }
        
        @discardableResult
        public func sendLinktestRequest() throws -> HSMSMessage? {
            do {
                let primaryMessage = self.messageBuilder.buildLinktestRequest(sessionId: self.sessionId)
                if let r = try self.send(hsmsMessage: primaryMessage) {
                    if r.messageType == .rejectRequest {
//                        throw HSMSError.rejectRequest(primaryMessage: primaryMessage, rejectRequestMessage: r)
                    }
                    return r
                } else {
                    return nil
                }
            }
            catch {
                throw error
            }
        }
        
        @discardableResult
        public func asyncSendLinktestRequest() async -> Result<HSMSMessage?, Error> {
            return await self.asyncSend(hsmsMessage: self.messageBuilder.buildLinktestRequest(sessionId: self.sessionId))
        }
        
        public func replyLinktestResponse(primaryMessage: inout HSMSMessage) throws {
            try self.send(hsmsMessage: self.messageBuilder.buildLinktestResponse(linktestRequest: primaryMessage) )
        }
        
        @discardableResult
        public func asyncReplyLinktestResponse(primaryMessage: inout HSMSMessage) async -> Result<HSMSMessage?, Error> {
            return await self.asyncSend(hsmsMessage: self.messageBuilder.buildLinktestResponse(linktestRequest: primaryMessage))
        }
        
        @discardableResult
        public func sendRejectRequest(primaryMessage: inout HSMSMessage, reason: HSMSMessage.RejectReason, byte2: UInt8) throws -> HSMSMessage? {
            return try self.send(hsmsMessage: self.messageBuilder.buildRejectRequest(referenceMessage: primaryMessage, rejectReason: reason, byte2: byte2))
        }
        
        public func asyncSendRejectRequest(primaryMessage: inout HSMSMessage, reason: HSMSMessage.RejectReason, byte2: UInt8) async -> Result<HSMSMessage?, Error> {
            return await self.asyncSend(hsmsMessage: self.messageBuilder.buildRejectRequest(referenceMessage: primaryMessage, rejectReason: reason, byte2: byte2))
        }
        
        @discardableResult
        public func sendSeparateRequest() throws -> HSMSMessage? {
            return try self.send(hsmsMessage: self.messageBuilder.buildSeparateRequest(sessionId: self.sessionId))
        }
        
        @discardableResult
        public func asyncSendSeparateRequest() async -> Result<HSMSMessage?, Error> {
            return await self.asyncSend(hsmsMessage: self.messageBuilder.buildSeparateRequest(sessionId: self.sessionId))
        }
        
    }
    
    internal override init(label: String?) {
        super.init(label: label)
    }
    
}
