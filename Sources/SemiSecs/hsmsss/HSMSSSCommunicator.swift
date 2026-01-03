//
//  HSMSSSCommunicator.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Foundation
import Network

@available(macOS 10.15, *)
public class HSMSSSCommunicator: HSMSCommunicator, @unchecked Sendable {
    
    @available(macOS 10.15.0, *)
    internal class HSMSSSMessageBuilder: HSMSMessageBuilder {
        
        internal weak var communicator: HSMSSSCommunicator?
        
        internal override init() {
            self.communicator = nil
            super.init()
        }
        
        private func sessionId2Bytes(_ hsmsSession: HSMSSession) -> [UInt8] {
            let i = hsmsSession.sessionId
            return [
                UInt8((i >> 8) & 0x000000FF),
                UInt8(i & 0x000000FF)
            ]
        }
        
        private func system4Bytes(_ hsmsSession: HSMSSession) -> [UInt8] {
            let isEquip = self.communicator!.config.isEquipment
            return (isEquip ? self.sessionId2Bytes(hsmsSession) : [0x00, 0x00]) + super.incrementAndGetSystemLower2Bytes
        }
        
        internal override func buildSelectRequest(hsmsSession: HSMSSession) -> HSMSMessage {
            return HSMSMessage(sessionId2Bytes: [0xFF, 0xFF],
                               messageType: .selectRequest,
                               system4Bytes: self.system4Bytes(hsmsSession))
        }
        
        internal override func buildDeselectRequest(hsmsSession: HSMSSession) -> HSMSMessage {
            return HSMSMessage(sessionId2Bytes: [0xFF, 0xFF],
                               messageType: .deselectRequest,
                               system4Bytes: self.system4Bytes(hsmsSession))
        }
        
        internal override func buildLinktestRequest(hsmsSession: HSMSSession) -> HSMSMessage {
            return HSMSMessage(sessionId2Bytes: [0xFF, 0xFF],
                               messageType: .linktestRequest,
                               system4Bytes: self.system4Bytes(hsmsSession))
        }
        
        internal override func buildSeparateRequest(hsmsSession: HSMSSession) -> HSMSMessage {
            return HSMSMessage(sessionId2Bytes: [0xFF, 0xFF],
                               messageType: .separateRequest,
                               system4Bytes: self.system4Bytes(hsmsSession))
        }
        
        internal override func buildData(hsmsSession: HSMSSession, smlMessage: SMLMessage) -> HSMSMessage {
            return HSMSMessage(sessionId2Bytes: self.sessionId2Bytes(hsmsSession),
                               smlMessage: smlMessage,
                               system4Bytes: self.system4Bytes(hsmsSession))
        }
        
        internal override func buildData(primaryMessage: SECSMessage, smlMessage: SMLMessage) -> HSMSMessage {
            return HSMSMessage(primaryMessage: primaryMessage, smlMessage: smlMessage)
        }
        
    }
    
    internal class HSMSSSMessageTransaction: HSMSMessageTransaction, @unchecked Sendable {
        
        private weak var communicator: HSMSSSCommunicator?
        internal let willSendQueue = BlockingQueue<HSMSMessage>()
        internal let sendResultQueue = BlockingQueue<Result<HSMSMessage, Error>>()
        
        internal init(communicator: HSMSSSCommunicator) {
            self.communicator = communicator
            super.init()
        }
        
        internal override func put(receiveMessage: HSMSMessage) throws -> TransactionPutResult {
            self.putDebugLog(type: .receiveHSMSMessage, value: receiveMessage)
            return try super.put(receiveMessage: receiveMessage)
        }
        
        internal override func operateSend(message: HSMSMessage) throws {
            self.putDebugLog(type: .willSendHSMSMessage, value: message)
            do {
                try willSendQueue.put(message)
            }
            catch {
                let error = HSMSError.sendFailedByTransactionShutdown(message: message)
                self.putDebugLog(type: .errorHSMSSendTransactionShutdown, value: error)
                throw error
            }
        }
        
        internal override func operateWaitSendCompleted(message: HSMSMessage) throws {
            do {
                let result = try self.sendResultQueue.take()
                switch result {
                case .success:
                    return
                case .failure(let error):
                    throw error
                }
            }
            catch _ as ShutdownableBase.ShutdownError {
                
                #warning("TODO")
                
                let error = HSMSError.sendFailedByTransactionShutdown(message: message)
                self.putDebugLog(type: .errorHSMSSendTransactionShutdown, value: error)
                throw error
            }
            catch {
                throw error
            }
        }
        
        internal override func operateReceive(primaryMessage: HSMSMessage, receiveQueue: BlockingQueue<HSMSMessage>) throws -> HSMSMessage {
            do {
                switch primaryMessage.messageType {
                case .data:
                    if let r = try receiveQueue.poll(timeout: self.communicator!.config.timeout.t3) {
                        return r
                    } else {
                        let error = HSMSError.timeoutT3(primaryMessage: primaryMessage)
                        self.putDebugLog(type: .errorHSMSTimeoutT3, value: error)
                        throw error
                    }
                default:
                    if let r = try receiveQueue.poll(timeout: self.communicator!.config.timeout.t6) {
                        return r
                    } else {
                        let error = HSMSError.timeoutT6(primaryMessage: primaryMessage)
                        self.putDebugLog(type: .errorHSMSTimeoutT6, value: error)
                        throw error
                    }
                }
            }
            catch _ as ShutdownableBase.ShutdownError {
                
                #warning("TODO")
                
                let error = HSMSError.waitReplyFailedByTransactionShutdown(primaryMessage: primaryMessage)
                self.putDebugLog(type: .errorHSMSSendTransactionShutdown, value: error)
                throw error
            }
            catch {
                throw error
            }
        }
        
        internal func putDebugLog(type: SECSDebugLog.SECSDebugLogType, value: CustomDebugStringConvertible) {
            self.communicator?.putDebugLog(type: type, value: value)
        }
    }
    
    internal class HSMSSSMessageReceiver: HSMSMessageReceiver, @unchecked Sendable {
        
        private weak var comminicator: HSMSSSCommunicator?
        
        internal init(communicator: HSMSSSCommunicator) {
            self.comminicator = communicator
            super.init()
        }
        
        internal override func getTiemoutT8() -> Double {
            if let comm = self.comminicator {
                return comm.config.timeout.t8
            } else {
                return Double.greatestFiniteMagnitude
            }
        }
        
    }
    
    internal class HSMSSSLinktest: HSMSLinktest {
        
        private weak var communicator: HSMSSSCommunicator?
        
        internal init(communicator: HSMSSSCommunicator) {
            self.communicator = communicator
            super.init()
        }
        
        internal override func getDoLinktest() -> Bool {
            if let comm = self.communicator {
                return comm.config.doLinktest
            } else {
                return false
            }
        }
        
        internal override func getLinktestCycle() -> Double {
            if let comm = self.communicator {
                return comm.config.linktestCycle
            } else {
                return Double.greatestFiniteMagnitude
            }
        }
        
    }
    
    @available(macOS 10.15.0, *)
    internal class HSMSSSSession: HSMSSession {
        
        internal weak var communicator: HSMSSSCommunicator?
        
        internal override init() {
            self.communicator = nil
            super.init()
        }
        
        public override var sessionId: UInt16 {
            return self.communicator!.config.sessionId
        }
        
        internal override var messageBuilder: HSMSMessageBuilder {
            return self.communicator!.messageBuilder
        }
        
        @discardableResult
        public override func send(hsmsMessage: HSMSMessage) throws -> HSMSMessage? {
            guard let transaction = self.transaction else {
                throw HSMSError.sendFailedNotConnectedError(message: hsmsMessage)
            }
            return try transaction.send(message: hsmsMessage)
        }
        
        internal override func putDebugLog(connectionState: HSMSConnectionState) {
            if let comm = self.communicator {
                let value = "{\"state\": \"\(connectionState.rawValue)\", \"sessionId\": \(self.sessionId)}"
                comm.putDebugLog(type: .didChangeHSMSConnectionState, value: value)
            }
        }
    }
    
    @available(macOS 10.15, *)
    public struct HSMSSSCommunicatorConfig {
        
        public var ipAddress: NWEndpoint.Host?
        public var port: NWEndpoint.Port
        
        private var _sessionId: UInt16
        public var sessionId: UInt16 {
            get {
                return self._sessionId
            }
            set {
                guard (0...0x7FFF).contains(newValue) else {
                    fatalError("sessionId set value in (0...0x7FFF). sessionId: \"\(newValue)\"")
                }
                self._sessionId = newValue
            }
        }
        
        public var connectionMode: HSMSConnectionMode
        public var isEquipment: Bool
        public var timeout: SECSCommunicatorTimeoutConfig = SECSCommunicatorTimeoutConfig()
        
        private var _rebindTimeIntervalIfPassiveMode: Double
        public var rebindTimeIntervalIfPassiveMode: Double {
            get {
                return self._rebindTimeIntervalIfPassiveMode
            }
            set {
                guard newValue > 0.0 else {
                    fatalError("rebindTimeIntervalIfPassiveMode set value >0.0")
                }
                self._rebindTimeIntervalIfPassiveMode = newValue
            }
        }
        
        public var doLinktest: Bool
        
        private var _linktestCycle: Double
        public var linktestCycle: Double {
            get {
                return self._linktestCycle
            }
            set {
                guard newValue > 0.0 else {
                    fatalError("linktestCycle set value >0.0")
                }
                self._linktestCycle = newValue
            }
        }
        
        public init() {
            self.ipAddress = nil
            self.port = 5000
            self._sessionId = 10
            self.connectionMode = .passive
            self.isEquipment = true
            self._rebindTimeIntervalIfPassiveMode = 10.0
            self.doLinktest = false
            self._linktestCycle = 120.0
        }
    }
    
    
    private let condition = NSCondition()
    private var isDidStart: Bool
    private var isDidCancel: Bool
    
    public var config: HSMSSSCommunicatorConfig = HSMSSSCommunicatorConfig()
    fileprivate let messageBuilder: HSMSSSMessageBuilder = HSMSSSMessageBuilder()
    fileprivate let hsmsSession: HSMSSSSession = HSMSSSSession()
    
    
    public override init(label: String? = nil) {
        self.isDidStart = false
        self.isDidCancel = false
        super.init(label: label)
        self.messageBuilder.communicator = self
        self.hsmsSession.communicator = self;
    }
    
    /**
     notify HSMS-State update
     */
    public var stateUpdateHandler: (@Sendable (_ state: HSMSCommunicator.HSMSConnectionState) -> Void)? {
        get {
            return self.hsmsSession.stateUpdateHandler
        }
        set {
            self.hsmsSession.stateUpdateHandler = newValue
        }
    }
    
    public var primaryMessageReceiveHandler: (@Sendable (_ message: HSMSMessage) -> Void)? {
        get {
            return self.hsmsSession.primaryMessageReceiveHandler
        }
        set {
            self.hsmsSession.primaryMessageReceiveHandler = newValue
        }
    }
    
    public func send(hsmsMessage: HSMSMessage) throws -> HSMSMessage? {
        return try self.hsmsSession.send(hsmsMessage: hsmsMessage)
    }
    
    public func asyncSend(hsmsMessage: HSMSMessage) async -> Result<HSMSMessage?, Error> {
        return await self.hsmsSession.asyncSend(hsmsMessage: hsmsMessage)
    }
    
    public func send(stream: UInt8, function: UInt8, wbit: Bool, secs2Body: SECS2Body = SECS2Body()) throws -> HSMSMessage? {
        return try self.hsmsSession.send(stream: stream, function: function, wbit: wbit, secs2Body: secs2Body)
    }
    
    public func send(smlMessage: SMLMessage) throws -> HSMSMessage? {
        return try self.hsmsSession.send(smlMessage: smlMessage)
    }
    
    public func asyncSend(stream: UInt8, function: UInt8, wbit: Bool, secs2Body: SECS2Body = SECS2Body()) async -> Result<HSMSMessage?, Error> {
        return await self.hsmsSession.asyncSend(stream: stream, function: function, wbit: wbit, secs2Body: secs2Body)
    }
    
    public func asyncSend(smlMessage: SMLMessage) async -> Result<HSMSMessage?, Error> {
        return await self.hsmsSession.asyncSend(smlMessage: smlMessage)
    }
    
    public func reply(primaryMessage: SECSMessage, stream: UInt8, function: UInt8, wbit: Bool, secs2Body: SECS2Body = SECS2Body()) throws {
        try self.hsmsSession.reply(primaryMessage: primaryMessage, stream: stream, function: function, wbit: wbit, secs2Body: secs2Body)
    }
    
    public func reply(primaryMessage: SECSMessage, smlMessage: SMLMessage) throws {
        try self.hsmsSession.reply(primaryMessage: primaryMessage, smlMessage: smlMessage)
    }
    
    public func asyncReply(primaryMessage: SECSMessage, stream: UInt8, function: UInt8, wbit: Bool, secs2Body: SECS2Body = SECS2Body()) async -> Result<HSMSMessage?, Error> {
        return await self.hsmsSession.asyncReply(primaryMessage: primaryMessage, stream: stream, function: function, wbit: wbit, secs2Body: secs2Body)
    }
    
    public func asyncReply(primaryMessage: SECSMessage, smlMessage: SMLMessage) async -> Result<HSMSMessage?, Error> {
        return await self.hsmsSession.asyncReply(primaryMessage: primaryMessage, smlMessage: smlMessage)
    }
    
    public func sendLinktestRequest() throws -> HSMSMessage? {
        return try self.hsmsSession.sendLinktestRequest()
    }
    
    public func asyncSendLinktestRequest() async -> Result<HSMSMessage?, Error> {
        return await self.hsmsSession.asyncSendLinktestRequest()
    }
    
    public func start() {
        
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        
        guard !self.isDidCancel else {
            //TODO throw error
            return
        }
        guard !self.isDidStart else {
            //TODO throw error
            return
        }
        self.isDidStart = true
        
        DispatchQueue.global().async {
            
            self.hsmsSession.set(connectionState: .notConnected)
            
            while !self.isDidCancel {
                
                switch self.config.connectionMode {
                case .active:
                    self.runActiveTask()
                    
                    do {
                        self.condition.lock()
                        defer {
                            self.condition.unlock()
                        }
                        
                        guard !self.isDidCancel else {
                            return
                        }
                        
                        print("WAIT-T5")
                        
                        self.condition.wait(until: Date().addingTimeInterval(self.config.timeout.t5))
                        
                        guard !self.isDidCancel else {
                            return
                        }
                    }
                    
                case .passive:
                    self.runPassiveTask()
                    
                    do {
                        self.condition.lock()
                        defer {
                            self.condition.unlock()
                        }
                        
                        guard !self.isDidCancel else {
                            return
                        }
                        
                        print("WAIT-passive")
                        self.condition.wait(until: Date().addingTimeInterval(self.config.rebindTimeIntervalIfPassiveMode))
                        
                        guard !self.isDidCancel else {
                            return
                        }
                    }
                }
            }
        }
    }
    
    public func cancel() {
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        
        guard !self.isDidCancel else {
            return
        }
        
        self.isDidCancel = true
        self.condition.broadcast()
    }
    
    @discardableResult
    public func waitUntilSelected() -> Bool {
        return self.hsmsSession.waitUntilSelected()
    }
    
    @discardableResult
    public func waitUntilSelected(timeout: Double) -> Bool {
        return self.hsmsSession.waitUntilSelected(timeout: timeout)
    }
    
    @discardableResult
    public func waitUntilNotSelected() -> Bool {
        return self.hsmsSession.waitUntilNotSelected()
    }
    
    @discardableResult
    public func waitUntilNotSelected(timeout: Double) -> Bool {
        return self.hsmsSession.waitUntilNotSelected(timeout: timeout)
    }
    
    @discardableResult
    func startAndWaitUntilSelected() -> Bool {
        start()
        return self.waitUntilSelected()
    }
    
    private var alreadyConnectionDidCancel = false
    
    private func runActiveTask() {
        
        guard let ipAddress = self.config.ipAddress else {
            return
        }
        
        self.alreadyConnectionDidCancel = false
        
        let connectionStateChangeNotifier = StateChangeNotifier<NWConnection.State>(.preparing)
        let hsmsMessageReceiver = HSMSSSMessageReceiver(communicator: self)
        let receiveHSMSMessageQueue = BlockingQueue<HSMSMessage>()
        let hsmsLinktest = HSMSSSLinktest(communicator: self)
        
        @Sendable func cancelConnection() {
            self.condition.lock()
            if !self.alreadyConnectionDidCancel {
                self.condition.broadcast()
            }
            self.condition.unlock()
        }
        
        self.condition.lock()
        defer {
            self.alreadyConnectionDidCancel = true
            self.hsmsSession.set(connectionState: .notConnected, transaction: nil)
            
            connectionStateChangeNotifier.shutdown()
            hsmsMessageReceiver.shutdown()
            receiveHSMSMessageQueue.shutdown()
            hsmsLinktest.shutdown()
            
            self.condition.unlock()
        }
        
        DispatchQueue.global().async {
            
            let nwConnectionQueue = DispatchQueue.global()
            let transaction = HSMSSSMessageTransaction(communicator: self)
            
            let connection = NWConnection(host: ipAddress, port: self.config.port, using: .tcp)
            defer {
                connection.cancel()
            }
            
            @Sendable func connectionReceiving() {
                connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, context, isComplete, error in
                    
                    if let _ = error {
                        cancelConnection()
                        return
                    }
                    if let data = data {
                        do {
                            try hsmsMessageReceiver.put(data)
                            connectionReceiving()
                        }
                        catch {
                            cancelConnection()
                        }
                    } else {
                        cancelConnection()
                    }
                }
            }
            
            DispatchQueue.global().async {
                do {
                    while true {
                        let message = try hsmsMessageReceiver.take()

                        let putResult = try transaction.put(receiveMessage: message)
                        switch putResult {
                        case .existReplyMeessage:
                            break
                        case .primaryMessage:
                            try receiveHSMSMessageQueue.put(message)
                        }
                        
                        hsmsLinktest.reset()
                    }
                }
                catch {
                    /* Nothing */
                }

            }
            
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connectionStateChangeNotifier.set(state)
                    
                    DispatchQueue.global().async {
                        connectionReceiving()
                    }
                    
                default:
                    connectionStateChangeNotifier.set(state)
                }
            }
            
            self.putDebugLog(type: .startHSMSNWConnection, value: "{ip: \(ipAddress), port: \(self.config.port), sessionId: \(self.hsmsSession.sessionId)}")
            
            connection.start(queue: nwConnectionQueue)
            
            @Sendable func connectionSending() {
                do {
                    let message = try transaction.willSendQueue.take()
                    nwConnectionQueue.async {
                        connection.send(content: message.data, completion: .contentProcessed({ error in
                            
                            do {
                                if let error = error {
                                    let sendError = HSMSError.sendFailed(message: message, cause: error)
                                    self.putDebugLog(type: .errorSendHSMSMessageFailed, value: sendError)
                                    try transaction.sendResultQueue.put(Result.failure(sendError))
                                } else {
                                    self.putDebugLog(type: .didSendHSMSMessage, value: message)
                                    try transaction.sendResultQueue.put(Result.success(message))
                                }
                                
                                DispatchQueue.global().async {
                                    connectionSending()
                                }
                            }
                            catch {
                                cancelConnection()
                            }
                        }))
                    }
                }
                catch {
                    cancelConnection()
                }
            }
            
            DispatchQueue.global().async {
                connectionSending()
            }
            
            // wait until NWConnection is .ready
            do {
                try connectionStateChangeNotifier.waitUntil(.ready)
            }
            catch {
                cancelConnection();
                return
            }
            
            DispatchQueue.global().async {
                do {
                    try connectionStateChangeNotifier.waitUntilNot(.ready)
                }
                catch {
                    /* Nothin */
                }
                
                cancelConnection();
            }
            
            self.hsmsSession.set(connectionState: .notSelected, transaction: transaction)
            
            // send SELECT.req and SELECT.rsp is success.
            do {
                guard let r = try self.hsmsSession.sendSelectRequest() else {
                    cancelConnection()
                    return
                }

                let selectStatus = HSMSMessage.SelectStatus.get(hsmsSelectRespnseMessage: r)
                switch selectStatus {
                case .success:
                    // success
                    break
                case .actived:
                    // success
                    break
                default:
                    cancelConnection()
                    return;
                }
            }
            catch {
                cancelConnection()
                return;
            }
            
            self.hsmsSession.set(connectionState: .selected)
            
            // linktest
            hsmsLinktest.start(linktest: {
                do {
                    guard let _ = try self.hsmsSession.sendLinktestRequest() else {
                        cancelConnection()
                        return
                    }
                }
                catch {
                    cancelConnection()
                }
            })
            
            // receiving HSMS-Message
            do {
                while !self.alreadyConnectionDidCancel {
                    let message = try receiveHSMSMessageQueue.take()
                    
                    switch message.messageType {
                    case .data:
                        try self.hsmsSession.receiveHSMSMessageNotifier.put(message)
                    case .selectRequest:
                        try self.hsmsSession.replySelectResponse(primaryMessage: message, status: .actived)
                    case .selectResponse:
                        try self.hsmsSession.sendRejectRequest(primaryMessage: message, reason: .transactionNotOpen, byte2: message.header10Bytes[5])
                    case .deselectRequest:
                        try self.hsmsSession.sendRejectRequest(primaryMessage: message, reason: .notSupportTypeS, byte2: message.header10Bytes[5])
                    case .deselectResponse:
                        try self.hsmsSession.sendRejectRequest(primaryMessage: message, reason: .transactionNotOpen, byte2: message.header10Bytes[5])
                    case .linktestRequest:
                        try self.hsmsSession.replyLinktestResponse(primaryMessage: message)
                    case .linktestResponse:
                        try self.hsmsSession.sendRejectRequest(primaryMessage: message, reason: .transactionNotOpen, byte2: message.header10Bytes[5])
                    case .rejectRequest:
                        /* Nothing */
                        break
                    case .separateRequest:
                        cancelConnection()
                        return
                    default:
                        if HSMSMessage.MessageType.hasPType(hsmsMessage: message) {
                            try self.hsmsSession.sendRejectRequest(primaryMessage: message, reason: .notSupportTypeS, byte2: message.header10Bytes[5])
                        } else {
                            try self.hsmsSession.sendRejectRequest(primaryMessage: message, reason: .notSupportTypeP, byte2: message.header10Bytes[4])
                        }
                    }
                }
            }
            catch {
                /* Nothing */
            }
            
            cancelConnection()
        }
        
        if !alreadyConnectionDidCancel {
            self.condition.wait()
        }
    }
    

    private func runPassiveTask() {
        
        do {
            var conditions: [NSCondition] = []
            let nwListener = try NWListener(using: .tcp, on: self.config.port)
            nwListener.newConnectionHandler = { connection in
                DispatchQueue.global().async {
                    let condition = NSCondition()
                    conditions.append(condition)
                    self.passiveConenction(connection: connection, condition: condition)
                    connection.cancel()
                    conditions.removeAll { $0 === condition }
                }
            }
            nwListener.start(queue: DispatchQueue.global())
            self.condition.wait()
            nwListener.cancel()
            for condition in conditions {
                condition.lock()
                condition.broadcast()
                condition.unlock()
            }
            self.condition.unlock()
        }
        catch {
        }
    }
    
    private func passiveConenction(connection: NWConnection, condition: NSCondition) {
        
        let connectionStateChangeNotifier = StateChangeNotifier<NWConnection.State>(.preparing)
        let hsmsMessageReceiver = HSMSSSMessageReceiver(communicator: self)
        let receiveHSMSMessageQueue = BlockingQueue<HSMSMessage>()
        let hsmsLinktest = HSMSSSLinktest(communicator: self)
        
        @Sendable func cancelConnection() {
            condition.lock()
            if !alreadyConnectionDidCancel {
                condition.broadcast()
            }
            condition.unlock()
        }
        
        condition.lock()
        defer {
            alreadyConnectionDidCancel = true
            
            connectionStateChangeNotifier.shutdown()
            hsmsMessageReceiver.shutdown()
            receiveHSMSMessageQueue.shutdown()
            hsmsLinktest.shutdown()
            
            condition.unlock()
        }
        
        DispatchQueue.global().async {
            
            let nwConnectionQueue = DispatchQueue.global()
            let transaction = HSMSSSMessageTransaction(communicator: self)
            
            @Sendable func connectionReceiving() {
                connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, context, isComplete, error in
                    
                    if let _ = error {
                        cancelConnection()
                        return
                    }
                    if let data = data {
                        do {
                            try hsmsMessageReceiver.put(data)
                            connectionReceiving()
                        }
                        catch {
                            cancelConnection()
                        }
                    } else {
                        cancelConnection()
                    }
                }
            }
            
            DispatchQueue.global().async {
                do {
                    while true {
                        let message = try hsmsMessageReceiver.take()

                        let putResult = try transaction.put(receiveMessage: message)
                        switch putResult {
                        case .existReplyMeessage:
                            break
                        case .primaryMessage:
                            try receiveHSMSMessageQueue.put(message)
                        }
                        
                        hsmsLinktest.reset()
                    }
                }
                catch {
                    /* Nothing */
                }
            }
            
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connectionStateChangeNotifier.set(state)
                    
                    DispatchQueue.global().async {
                        connectionReceiving()
                    }
                    
                default:
                    connectionStateChangeNotifier.set(state)
                }
            }
            
            // start connection
            connection.start(queue: nwConnectionQueue)
            
            @Sendable func connectionSending() {
                do {
                    let message = try transaction.willSendQueue.take()
                    nwConnectionQueue.async {
                        connection.send(content: message.data, completion: .contentProcessed({ error in
                            
                            do {
                                if let error = error {
                                    let sendError = HSMSError.sendFailed(message: message, cause: error)
                                    self.putDebugLog(type: .errorSendHSMSMessageFailed, value: sendError)
                                    try transaction.sendResultQueue.put(Result.failure(sendError))
                                } else {
                                    self.putDebugLog(type: .didSendHSMSMessage, value: message)
                                    try transaction.sendResultQueue.put(Result.success(message))
                                }
                                
                                DispatchQueue.global().async {
                                    connectionSending()
                                }
                            }
                            catch {
                                cancelConnection()
                            }
                        }))
                    }
                }
                catch {
                    cancelConnection()
                }
            }
            
            DispatchQueue.global().async {
                connectionSending()
            }
            
            // wait until NWConnection is .ready
            do {
                try connectionStateChangeNotifier.waitUntil(.ready)
            }
            catch {
                cancelConnection();
                return
            }
            
            DispatchQueue.global().async {
                do {
                    try connectionStateChangeNotifier.waitUntilNot(.ready)
                }
                catch {
                    /* Nothin */
                }
                
                cancelConnection();
            }
            
            // wait SELECT.req
            selectRequestLoop: do {
                while !self.alreadyConnectionDidCancel {
                    let message = try receiveHSMSMessageQueue.take()
                    
                    switch message.messageType {
                    case .data:
                        try transaction.send(message: self.messageBuilder.buildRejectRequest(primaryMessage: message, reason: .transactionNotOpen, byte2: message.header10Bytes[5]))
                    case .selectRequest:
                        if self.hsmsSession.trySet(transaction: transaction) {
                            self.hsmsSession.set(connectionState: .selected)
                            try self.hsmsSession.replySelectResponse(primaryMessage: message, status: .success)
                            break selectRequestLoop
                        } else {
                            try transaction.send(message: self.messageBuilder.buildSelectResponse(primaryMessage: message, status: .alreadyUsed))
                        }
                    case .selectResponse:
                        try transaction.send(message: self.messageBuilder.buildRejectRequest(primaryMessage: message, reason: .transactionNotOpen, byte2: message.header10Bytes[5]))
                    case .deselectRequest:
                        try transaction.send(message: self.messageBuilder.buildRejectRequest(primaryMessage: message, reason: .notSupportTypeS, byte2: message.header10Bytes[5]))
                    case .deselectResponse:
                        try transaction.send(message: self.messageBuilder.buildRejectRequest(primaryMessage: message, reason: .transactionNotOpen, byte2: message.header10Bytes[5]))
                    case .linktestRequest:
                        try transaction.send(message: self.messageBuilder.buildLinktestResponse(primaryMessage: message))
                    case .linktestResponse:
                        try transaction.send(message: self.messageBuilder.buildRejectRequest(primaryMessage: message, reason: .transactionNotOpen, byte2: message.header10Bytes[5]))
                    case .rejectRequest:
                        /* Nothing */
                        break
                    case .separateRequest:
                        cancelConnection()
                        return
                    default:
                        if HSMSMessage.MessageType.hasPType(hsmsMessage: message) {
                            try transaction.send(message: self.messageBuilder.buildRejectRequest(primaryMessage: message, reason: .notSupportTypeS, byte2: message.header10Bytes[5]))
                        } else {
                            try transaction.send(message: self.messageBuilder.buildRejectRequest(primaryMessage: message, reason: .notSupportTypeP, byte2: message.header10Bytes[4]))
                        }
                    }
                }
            }
            catch {
                cancelConnection()
                return
            }
            
            // linktest
            hsmsLinktest.start(linktest: {
                do {
                    guard let _ = try self.hsmsSession.sendLinktestRequest() else {
                        cancelConnection()
                        return
                    }
                }
                catch {
                    cancelConnection()
                }
            })
            
            do {
                defer {
                    self.hsmsSession.set(connectionState: .notConnected, transaction: nil)
                }
                
                while !self.alreadyConnectionDidCancel {
                    let message = try receiveHSMSMessageQueue.take()
                    
                    switch message.messageType {
                    case .data:
                        try self.hsmsSession.receiveHSMSMessageNotifier.put(message)
                    case .selectRequest:
                        try self.hsmsSession.replySelectResponse(primaryMessage: message, status: .actived)
                    case .selectResponse:
                        try self.hsmsSession.sendRejectRequest(primaryMessage: message, reason: .transactionNotOpen, byte2: message.header10Bytes[5])
                    case .deselectRequest:
                        try self.hsmsSession.sendRejectRequest(primaryMessage: message, reason: .notSupportTypeS, byte2: message.header10Bytes[5])
                    case .deselectResponse:
                        try self.hsmsSession.sendRejectRequest(primaryMessage: message, reason: .transactionNotOpen, byte2: message.header10Bytes[5])
                    case .linktestRequest:
                        try self.hsmsSession.replyLinktestResponse(primaryMessage: message)
                    case .linktestResponse:
                        try self.hsmsSession.sendRejectRequest(primaryMessage: message, reason: .transactionNotOpen, byte2: message.header10Bytes[5])
                    case .rejectRequest:
                        /* Nothing */
                        break
                    case .separateRequest:
                        cancelConnection()
                        return
                    default:
                        if HSMSMessage.MessageType.hasPType(hsmsMessage: message) {
                            try self.hsmsSession.sendRejectRequest(primaryMessage: message, reason: .notSupportTypeS, byte2: message.header10Bytes[5])
                        } else {
                            try self.hsmsSession.sendRejectRequest(primaryMessage: message, reason: .notSupportTypeP, byte2: message.header10Bytes[4])
                        }
                    }
                }
            }
            catch {
                /* Nothing */
            }
            
            cancelConnection()
        }
        
        if !alreadyConnectionDidCancel {
            condition.wait()
        }
    }
}
