//
//  HSMSSSCommunicator.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Foundation
import os
import Network
import Synchronization

/// HSMS-SS-Communicator
public final class HSMSSSCommunicator: HSMSCommunicator, HSMSMessageSendable, SECSMessageReceivable, HSMSConnectionStateDetectable, Sendable {
    
    /// HSMS-SS communicator config.
    public final class HSMSSSCommunicatorConfig: HSMSCommunicatorConfig, Sendable {
        
        private let _sessionId: Mutex<UInt16>
        private let _isEquipment: Mutex<Bool>
        private let _timeout: SECSCommunicatorTimeoutConfig
        private let _connectionMode: Mutex<HSMSConnectionMode>
        private let _ipAddress: Mutex<String>
        private let _port: Mutex<UInt16>
        private let _rebindDuration: Mutex<Duration>
        private let _doLinktest: Mutex<Bool>
        private let _linktestDuration: Mutex<Duration>
        
        internal init() {
            self._sessionId = Mutex<UInt16>(10)
            self._isEquipment = Mutex<Bool>(true)
            self._timeout = SECSCommunicatorTimeoutConfig()
            self._connectionMode = Mutex<HSMSConnectionMode>(.passive)
            self._ipAddress = Mutex<String>("")
            self._port = Mutex<UInt16>(5000)
            self._rebindDuration = Mutex<Duration>(.seconds(10.0))
            self._doLinktest = Mutex<Bool>(false)
            self._linktestDuration = Mutex<Duration>(.seconds(120.0))
        }
        
        /// Session-ID.
        public var sessionId: UInt16 {
            get {
                return self._sessionId.withLock { $0 }
            }
            set {
                guard newValue <= 0x7FFF else {
                    fatalError("Session-ID is 0...0x7FFF")
                }
                self._sessionId.withLock { $0 = newValue }
            }
        }
        
        public var isEquipment: Bool {
            get { self._isEquipment.withLock { $0 } }
            set { self._isEquipment.withLock { $0 = newValue } }
        }
        
        public var timeout: SECSCommunicatorTimeoutConfig {
            get { self._timeout }
        }
        
        public var connectionMode: HSMSConnectionMode {
            get { self._connectionMode.withLock { $0 } }
            set { self._connectionMode.withLock { $0 = newValue } }
        }
        
        public var ipAddress: String {
            get { self._ipAddress.withLock { $0 } }
            set { self._ipAddress.withLock { $0 = newValue } }
        }
        
        public var port: UInt16 {
            get { self._port.withLock { $0 } }
            set { self._port.withLock { $0 = newValue } }
        }
        
        public var rebindDuration: Duration {
            get {
                return self._rebindDuration.withLock { $0 }
            }
            set {
                guard newValue > .zero else {
                    fatalError("rebindDuration set value >0.0")
                }
                self._rebindDuration.withLock { $0 = newValue }
            }
        }
        
        public var autoLinktest: Bool {
            get { self._doLinktest.withLock { $0 } }
            set { self._doLinktest.withLock { $0 = newValue } }
        }
        
        public var linktestDuration: Duration {
            get {
                return self._linktestDuration.withLock { $0 }
            }
            set {
                guard newValue > .zero else {
                    fatalError("linktestTimeDuration set value >0.0")
                }
                self._linktestDuration.withLock { $0 = newValue }
            }
        }
    }
    
    // MARK: - let
    
    private let messageBuilder = HSMSSSMessageBuilder()
    private let session = HSMSSession()
    private let transactor = HSMSMessageTransactor()
    private let startAndShutdown = StartAndShutdown()
    private let (shutdownStream, shutdownContinuation) = AsyncStream.makeStream(of: Void.self)
    private let (receiveWholeHSMSMessageStream, receiveWholeHSMSMessageContinuation) = AsyncStream.makeStream(of: HSMSMessageAndNWConnection.self)
    private let (networkEventStream, networkEventContinuation) = AsyncStream.makeStream(of: HSMSNetworkEvent.self)
    
    // MARK: - var
    
    private let _config = HSMSSSCommunicatorConfig()
    
    /// Config
    public var config: HSMSSSCommunicatorConfig {
        get { self._config }
    }
    
    /// Create HSMS-SS communicator instance.
    public init() {
        // messageBuilder
        self.messageBuilder.isEquipment = { [weak self] in
            return self!.config.isEquipment
        }
        
        // transactor
        self.transactor.timeoutT3 = { [weak self] in
            return self!.config.timeout.t3
        }
        self.transactor.timeoutT6 = { [weak self] in
            return self!.config.timeout.t6
        }
        
        // session
        self.session.hsmsSessionId = { [weak self] in
            return self!.config.sessionId
        }
        self.session.isEquipment = { [weak self] in
            return self!.config.isEquipment
        }
        self.session.hsmsMessageBuilder = { [weak self] in
            return self!.messageBuilder
        }
        self.session.hsmsMessageTransactor = { [weak self] in
            return self!.transactor
        }
    }
    
    deinit {
        self.shutdown()
    }
    
    /// Mark start, throws if already started or shutdown.
    ///
    /// - Throws:
    ///   - `StartAndShutdownError.alreadyShutdowned: if already shutdown.
    ///   - `StartAndShutdownError.alreadyStarted:  if already started.
    public func start() throws {
        try self.start(queue: DispatchQueue(label: "defaultDispatchQueueLabel"))
    }
    
    /// Mark start, throws if already started or shutdown.
    ///
    /// - Parameters:
    ///   - queue: the DispatchQueue
    /// - Throws:
    ///   - `StartAndShutdownError.alreadyShutdowned`: if already shutdown.
    ///   - `StartAndShutdownError.alreadyStarted`:  if already started.
    public func start(queue: DispatchQueue) throws {
        try self.startAndShutdown.start()
        
        // send HSMS-Message.
        queue.async { [weak self] in
            guard let self = self else { return }
            Task {
                let stream = self.transactor.willSendMessageStream()
                for await pair in stream {
                    pair.connection.send(content: pair.message.data, contentContext: .defaultMessage, isComplete: true, completion: .contentProcessed({ error in
                        Task {
                            self.transactor.yield(sendedMessage: pair.message, connection: pair.connection, error: error)
                            if let error = error {
                                Logger.nwConnection.error("\(error)")
                            } else {
                                self._didSendWholeHSMSMessage.accept(pair.message, pair.connection)
                                Logger.sendedHSMSMessage.notice("\(String(describing: pair.message))")
                            }
                        }
                    }))
                }
                
                Logger.communicator.debug("send HSMS-Message finished.")
            }
        }
        
        // receive Primary-HSMS-Message and NWConnection pair pass to HSMSSession
        Task { [weak self] in
            guard let self = self else { return }
            let stream = self.transactor.didReceiveMessageStream()
            for await pair in stream {
                switch self.config.connectionMode {
                case .active:
                    await self.session.receiveAsHSMSSSActive(message: pair.message, connection: pair.connection)
                case .passive:
                    await self.session.receiveAsHSMSSSPassive(message: pair.message, connection: pair.connection)
                }
            }
            
            Logger.communicator.debug("receive Primary-HSMS-Message and NWConnection pair pass to HSMSSession finished.")
        }
        
        Task { [weak self] in
            guard let self = self else { return }
            for await event in self.networkEventStream {
                self._newNetworkEvent.accept(event)
            }
            
            Logger.communicator.debug("HSMS Network Event finished.")
        }
        
        Task { [weak self] in
            guard let self = self else { return }
            
            // receive whole HSMS-Message.
            Task {
                let stream = self.receiveWholeHSMSMessageStream
                for await pair in stream {
                    self._didReceiveWholeHSMSMessage.accept(pair.message, pair.connection)
                    Logger.receiveHSMSMessage.notice("\(String(describing: pair.message))")
                }
                
                Logger.communicator.debug("receiveWholeHSMSMessageStream finished.")
            }
            
            self.session.start()
            
            let task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    while !Task.isCancelled {
                        switch self.config.connectionMode {
                        case .active:
                            Logger.communicator.notice("HSMS-SS Active perform start.")
                            try await self.performActive(queue: queue)
                            try Task.checkCancellation()
                            
                        case .passive:
                            Logger.communicator.notice("HSMS-SS Passive perform start.")
                            try await self.performPassive(queue: queue)
                            try Task.checkCancellation()
                        }
                        
                        switch self.config.connectionMode {
                        case .active:
                            Logger.communicator.notice("HSMS-SS Active sleep T5-Timeout: \(self.config.timeout.t5)")
                            
                            self.networkEventContinuation.yield(.activeSleepTimeoutT5(timeout: self.config.timeout.t5))
                            
                            try await Task.sleep(for: self.config.timeout.t5)
                            
                        case .passive:
                            Logger.communicator.notice("HSMS-SS Passive sleep rebind duration: \(self.config.rebindDuration)")
                            
                            self.networkEventContinuation.yield(.passiveSleepRebind(timeout: self.config.rebindDuration))
                            
                            try await Task.sleep(for: self.config.rebindDuration)
                        }
                    }
                }
                catch is CancellationError {
                    // ignore
                }
                catch {
                    Logger.communicator.error("\(error)")
                }
            }
            
            // waiting until shutdown called.
            for await _ in self.shutdownStream {
            }
            task.cancel()
            
            self.startAndShutdown.shutdown()
            
            self.networkEventContinuation.yield(.shutdown)
            self.networkEventContinuation.finish()
            self.receiveWholeHSMSMessageContinuation.finish()
            self.transactor.shutdown()
            self.session.shutdown()
            
            Logger.communicator.debug("start-task finished.")
        }
    }
    
    public func shutdown() {
        guard self.startAndShutdown.shutdown() == false else { return }
        Logger.communicator.debug("shutdown called.")
        self.shutdownContinuation.finish()
    }
    
    /// Linktest, Returns true if linktest success, otherwise false.
    ///
    /// - Returns: true if linktest success, otherwise false.
    public func linktest() async -> Bool {
        do {
            if let response = try await self.sendLinktestRequest() {
                if case .linktestResponse = response.messageType {
                    return true
                }
            }
        }
        catch {
        }
        
        return false
    }
    
    // MARK: - HSMSConnectionStateDetectable
    
    public var didUpdateCommunicationState: ((Bool) -> Void)? {
        get { self.session.didUpdateCommunicationState }
        set { self.session.didUpdateCommunicationState = newValue }
    }
    
    public var didUpdateHSMSConnectionState: ((HSMSSession.HSMSConnectionState) -> Void)? {
        get { self.session.didUpdateHSMSConnectionState }
        set { self.session.didUpdateHSMSConnectionState = newValue }
    }
    
    public func until(connectionState: HSMSSession.HSMSConnectionState) async throws {
        try await self.session.until(connectionState: connectionState)
    }
    
    public func untilNot(connectionState: HSMSSession.HSMSConnectionState) async throws {
        try await self.session.untilNot(connectionState: connectionState)
    }
    
    @discardableResult
    public func until(connectionState: HSMSSession.HSMSConnectionState, timeout: Duration) async throws -> Bool {
        return try await self.session.until(connectionState: connectionState, timeout: timeout)
    }
    
    @discardableResult
    public func untilNot(connectionState: HSMSSession.HSMSConnectionState, timeout: Duration) async throws -> Bool {
        return try await self.session.untilNot(connectionState: connectionState, timeout: timeout)
    }
    
    // MARK: - SECSMessageReceivable
    
    public var didReceivePrimaryDataSECSMessage: ((any SECSMessage) -> Void)? {
        get { self.session.didReceivePrimaryDataSECSMessage }
        set { self.session.didReceivePrimaryDataSECSMessage = newValue }
    }
    
    // MARK: - HSMSMessageReceivable
    
    private let _didReceiveWholeHSMSMessage = MutexBiConsumerWrapper<HSMSMessage, NWConnection>()
    
    public var didReceiveWholeHSMSMessage: ((HSMSMessage, NWConnection) -> Void)? {
        get { self._didReceiveWholeHSMSMessage.biConsumer }
        set { self._didReceiveWholeHSMSMessage.biConsumer = newValue }
    }
    
    // MARK: - HSMSMessageSendable
    
    public func send(message: HSMSMessage) async throws -> HSMSMessage? {
        return try await self.session.send(message: message)
    }
    
    @discardableResult
    public func send(smlMessage: SMLMessage) async throws -> (any SECSMessage)? {
        return try await self.session.send(smlMessage: smlMessage)
    }
    
    public func reply(primaryMessage: any SECSMessage, smlMessage: SMLMessage) async throws {
        try await self.session.reply(primaryMessage: primaryMessage, smlMessage: smlMessage)
    }
    
    public func sendSelectRequest() async throws -> HSMSMessage? {
        return try await self.session.sendSelectRequest()
    }
    
    public func replySelectResponse(selectRequest: HSMSMessage, selectStatus: HSMSMessage.SelectStatus) async throws {
        try await self.session.replySelectResponse(selectRequest: selectRequest, selectStatus: selectStatus)
    }
    
    public func sendDeselectRequest() async throws -> HSMSMessage? {
        return try await self.session.sendDeselectRequest()
    }
    
    public func replyDeselectResponse(deselectRequest: HSMSMessage, deselectStatus: HSMSMessage.DeselectStatus) async throws {
        try await self.session.replyDeselectResponse(deselectRequest: deselectRequest, deselectStatus: deselectStatus)
    }
    
    public func sendLinktestRequest() async throws -> HSMSMessage? {
        return try await self.session.sendLinktestRequest()
    }
    
    public func replyLinktestResponse(linktestRequest: HSMSMessage) async throws {
        try await self.session.replyLinktestResponse(linktestRequest: linktestRequest)
    }
    
    public func replyRejectRequest(referenceMessage: HSMSMessage, rejectReason: HSMSMessage.RejectReason, byte2: UInt8) async throws {
        try await self.session.replyRejectRequest(referenceMessage: referenceMessage, rejectReason: rejectReason, byte2: byte2)
    }
    
    public func sendSeparateRequest() async throws {
        try await self.session.sendSeparateRequest()
    }
    
    public var gem: GEM {
        get { self.session.gem }
    }
    
    private let _didSendWholeHSMSMessage = MutexBiConsumerWrapper<HSMSMessage, NWConnection>()
    
    /// Whole HSMSMessage send
    public var didSendWholeHSMSMessage: ((HSMSMessage, NWConnection) -> Void)? {
        get { self._didSendWholeHSMSMessage.biConsumer }
        set { self._didSendWholeHSMSMessage.biConsumer = newValue }
    }
    
    // MARK: - NetworkEvent
    
    private let _newNetworkEvent = MutexConsumerWrapper<HSMSNetworkEvent>()
    
    /// newNetworkEvent
    public var newNetworkEvent: ((HSMSNetworkEvent) -> Void)? {
        get { self._newNetworkEvent.consumer }
        set { self._newNetworkEvent.consumer = newValue }
    }
    
    // MARK: - Active
    
    private func performActive(queue: DispatchQueue) async throws {
        let ipAddress = self.config.ipAddress
        let port = self.config.port
        let nwIpAddress = NWEndpoint.Host(ipAddress)
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            fatalError("NWEndpoint.Port: \(port)")
        }
        
        let connection = NWConnection(host: nwIpAddress, port: nwPort, using: .tcp)
        let pipeline = self.newPipeline(connection: connection)
        
        defer {
            pipeline.shutdown()
            if connection.state != .cancelled {
                connection.cancel()
            }
        }
        
        do {
            self.networkEventContinuation.yield(.activeConnectStart(ipAddress: ipAddress, port: port))
            
            try await connection.connect(queue: queue)
            
            self.networkEventContinuation.yield(.activeConnectSuccess(ipAddress: ipAddress, port: port))
            
            let setConnectionAndStateResult = self.session.connectionAndState.withLock {
                $0.set(connection: connection, state: .notSelected)
            }
            guard setConnectionAndStateResult else {
                Logger.communicator.fault("NWConnection already setted.")
                fatalError("NWConnection already setted.")
            }

            let linktestTimer = self.newLinktestTimer()
            
            await withTaskGroup(of: Void.self) { group in
                // HSMS-Message pipeline
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    let stream = pipeline.hsmsMessageAndNWConnectionStream()
                    for await result in stream {
                        switch result {
                        case .success(let pair):
                            self.receiveWholeHSMSMessageContinuation.yield(pair)
                            self.transactor.yield(receiveMessage: pair.message, connection: pair.connection)
                            linktestTimer.reset()
                        case .failure(let error):
                            Logger.communicator.error("\(error)")
                        }
                    }
                    
                    Logger.communicator.debug("pipeline.hsmsMessageAndNWConnectionStream finished.")
                }
                
                // receive dataStream
                group.addTask {
                    let dataStream = connection.dataStream()
                    for await result in dataStream {
                        switch result {
                        case .success(let data):
                            pipeline.yield(data: data)
                        case .failure(let error):
                            Logger.nwConnection.error("\(error)")
                        }
                    }
                    
                    self.networkEventContinuation.yield(.activeConnectCancelled(ipAddress: ipAddress, port: port))
                    
                    Logger.communicator.debug("NWConnection.dataStream finished.")
                }
                
                // session-state
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    do {
                        // SELECT.req
                        guard let selectResponse = try await self.session.sendSelectRequest() else { return }
                        let selectStatus = HSMSMessage.SelectStatus(hsmsSelectRespnseMessage: selectResponse)
                        switch selectStatus {
                        case .success, .actived:
                            // select success
                            self.session.connectionAndState.withLock {
                                $0.set(state: .selected)
                            }
                        default:
                            // select failed
                            return
                        }
                        
                        // Linktest
                        linktestTimer.linktest = { [weak self] in
                            guard let self = self else { return }
                            Task {
                                guard await self.linktest() else {
                                    self.session.connectionAndState.withLock {
                                        $0.unset()
                                    }
                                    return
                                }
                            }
                        }
                        linktestTimer.start()
                        
                        let notifier = self.session.connectionAndState.withLock { $0.hsmsConnectionStateUpdateNotifier }
                        try await notifier.untilNot(.selected)
                    }
                    catch is CancellationError {
                        // ignore
                    }
                    catch {
                        // ignore
                    }
                }
                
                await group.next()
                group.cancelAll()
                linktestTimer.shutdown()
                
                self.session.connectionAndState.withLock {
                    $0.unset()
                }
            }
        }
        catch let error as CancellationError {
            throw error
        }
        catch {
            self.networkEventContinuation.yield(.activeConnectFailed(ipAddress: ipAddress, port: port, error: error))
            
            Logger.nwConnection.error("\(error)")
        }
    }
    
    // MARK: - Passive
    
    private func performPassive(queue: DispatchQueue) async throws {
        guard let port = NWEndpoint.Port(rawValue: self.config.port) else {
            fatalError("NWEndpoint.Port: \(self.config.port)")
        }
        
        do {
            let listener = try NWListenerStreamWrapper(using: .tcp, on: port)
            defer {
                listener.cancel()
                self.networkEventContinuation.yield(.passiveBindCancelled(port: self.config.port))
            }
            
            self.networkEventContinuation.yield(.passiveBindStart(port: self.config.port))
            
            try listener.start(queue: queue)
            
            self.networkEventContinuation.yield(.passiveBindSuccess(port: self.config.port))
            
            let stream = listener.connectionAndQueueStream()
            for await result in stream {
                switch result {
                case .success(let pair):
                    Task.detached {
                        await self.performPassiveAccept(connection: pair.connection, queue: pair.queue)
                    }
                case .failure(let error):
                    throw error
                }
            }
        }
        catch let error as CancellationError {
            throw error
        }
        catch {
            self.networkEventContinuation.yield(.passiveBindFailed(port: self.config.port, error: error))
            
            Logger.nwConnection.error("\(error)")
        }
    }
    
    private func performPassiveAccept(connection: NWConnection, queue: DispatchQueue) async {
        guard let (ipAddress, port) = connection.clientIPAddressAndPort else {
            return
        }
        
        let pipeline = self.newPipeline(connection: connection)
        
        do {
            self.networkEventContinuation.yield(.passiveAcceptStart(ipAddress: ipAddress, port: port))
            
            try await connection.connect(queue: queue)
            
            self.networkEventContinuation.yield(.passiveAcceptSuccess(ipAddress: ipAddress, port: port))
            
            await withTaskGroup(of: Void.self) { group in
                // receive dataStream
                group.addTask {
                    let dataStream = connection.dataStream()
                    for await result in dataStream {
                        switch result {
                        case .success(let data):
                            pipeline.yield(data: data)
                        case .failure(let error):
                            Logger.nwConnection.error("\(error)")
                        }
                    }
                    
                    self.networkEventContinuation.yield(.passiveAcceptCancelled(ipAddress: ipAddress, port: port))
                    
                    Logger.communicator.debug("NWConnection.dataStream finished.")
                }
                
                // session-state
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    
                    let pipelineStream = pipeline.hsmsMessageAndNWConnectionStream()
                    
                    do {
                        guard let firstRequestResult = try await pipelineStream.poll(timeout: self.config.timeout.t7) else {
                            Logger.communicator.error("HSMS-SS-Passive Timeout-T7")
                            return
                        }
                        
                        switch firstRequestResult {
                        case .success(let pair):
                            self.receiveWholeHSMSMessageContinuation.yield(pair)
                            
                            switch pair.message.messageType {
                            case .selectRequest:
                                // accept type
                                break
                                
                            case .selectResponse, .deselectResponse, .linktestResponse:
                                // reject not-open-transaction
                                let responseMessage = self.messageBuilder.buildRejectRequest(referenceMessage: pair.message, rejectReason: .transactionNotOpen, byte2: pair.message.header10Bytes[5])
                                try await self.transactor.send(message: responseMessage, connection: pair.connection)
                                return
                                
                            case .rejectRequest, .separateRequest:
                                // ignore type
                                return
                                
                            default:
                                // reject not-support-type
                                if HSMSMessage.MessageType.hasPType(hsmsMessage: pair.message) {
                                    let responseMessage = self.messageBuilder.buildRejectRequest(referenceMessage: pair.message, rejectReason: .notSupportTypeS, byte2: pair.message.header10Bytes[5])
                                    try await self.transactor.send(message: responseMessage, connection: pair.connection)
                                } else {
                                    let responseMessage = self.messageBuilder.buildRejectRequest(referenceMessage: pair.message, rejectReason: .notSupportTypeP, byte2: pair.message.header10Bytes[4])
                                    try await self.transactor.send(message: responseMessage, connection: pair.connection)
                                }
                                return
                            }
                            
                            let setConnectionAndStateResult = self.session.connectionAndState.withLock {
                                $0.set(connection: pair.connection, state: .notSelected, .selected)
                            }
                            guard setConnectionAndStateResult else {
                                Logger.communicator.info("NWConnection already setted.")
                                
                                let responseMessage = self.messageBuilder.buildSelectResponse(selectRequest: pair.message, selectStatus: .alreadyUsed)
                                try await self.transactor.send(message: responseMessage, connection: pair.connection)
                                return
                            }
                            
                            // success selected.
                            do {
                                try await self.session.replySelectResponse(selectRequest: pair.message, selectStatus: .success)
                            }
                            catch {
                                self.session.connectionAndState.withLock {
                                    $0.unset()
                                }
                                throw error
                            }
                            
                        case .failure(let error):
                            Logger.communicator.error("\(error)")
                            return
                        }
                    }
                    catch is CancellationError {
                        // ignore
                        return
                    }
                    catch {
                        Logger.communicator.error("\(error)")
                        return
                    }
                    
                    let linktestTimer = self.newLinktestTimer()
                    
                    await withTaskGroup(of: Void.self) { innerGroup in
                        // HSMS-Message pipeline
                        innerGroup.addTask {
                            for await result in pipelineStream {
                                switch result {
                                case .success(let pair):
                                    self.receiveWholeHSMSMessageContinuation.yield(pair)
                                    self.transactor.yield(receiveMessage: pair.message, connection: pair.connection)
                                    linktestTimer.reset()
                                case .failure(let error):
                                    Logger.communicator.error("\(error)")
                                }
                            }
                            
                            Logger.communicator.debug("pipeline.hsmsMessageAndNWConnectionStream finished.")
                        }
                        
                        // inner-session-state
                        innerGroup.addTask {
                            do {
                                // Linktest
                                linktestTimer.linktest = { [weak self] in
                                    guard let self = self else { return }
                                    Task {
                                        guard await self.linktest() else {
                                            self.session.connectionAndState.withLock {
                                                $0.unset()
                                            }
                                            return
                                        }
                                    }
                                }
                                linktestTimer.start()
                                
                                let notifier = self.session.connectionAndState.withLock {
                                    $0.hsmsConnectionStateUpdateNotifier
                                }
                                try await notifier.until(.notConnected)
                            }
                            catch is CancellationError {
                                // ignore
                            }
                            catch {
                                Logger.communicator.error("\(error)")
                            }
                        }
                        
                        await innerGroup.next()
                        innerGroup.cancelAll()
                        linktestTimer.shutdown()
                        
                        self.session.connectionAndState.withLock {
                            $0.unset()
                        }
                    }
                }
                
                await group.next()
                group.cancelAll()
            }
        }
        catch _ as CancellationError {
            // ignore
        }
        catch {
            self.networkEventContinuation.yield(.passiveAcceptFailed(ipAddress: ipAddress, port: port, error: error))
            
            Logger.nwConnection.error("\(error)")
        }
        
        pipeline.shutdown()
    }
    
    // MARK: -
    
    private func newPipeline(connection: NWConnection) -> HSMSMessagePipeline {
        let instance = HSMSMessagePipeline(connection: connection)
        instance.timeoutT8 = { [weak self] in
            guard let self = self else {
                return .seconds(6.0)
            }
            return self.config.timeout.t8
        }
        return instance
    }
    
    private func newLinktestTimer() -> HSMSLinktestTimer {
        let instance = HSMSLinktestTimer()
        instance.autoLinktest = { [weak self] in
            guard let self = self else {
                return false
            }
            return self.config.autoLinktest
        }
        instance.linktestDuration = { [weak self] in
            guard let self = self else {
                return .seconds(120.0)
            }
            return self.config.linktestDuration
        }
        return instance
    }

}
