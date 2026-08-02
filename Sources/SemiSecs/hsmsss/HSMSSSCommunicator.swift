//
//  HSMSSSCommunicator.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Foundation
import os
import Network

/// HSMS-SS-Communicator
public final class HSMSSSCommunicator: HSMSCommunicator, HSMSMessageSendable, SECSMessageReceivable, HSMSConnectionStateDetectable, Sendable {
    
    /// HSMS-SS communicator config.
    public struct HSMSSSCommunicatorConfig: HSMSCommunicatorConfig {
        
        private var _sessionId: UInt16
        private var _isEquipment: Bool
        private var _timeout: SECSCommunicatorTimeoutConfig
        private var _connectionMode: HSMSConnectionMode
        private var _ipAddress: NWEndpoint.Host?
        private var _port: NWEndpoint.Port
        private var _rebindDuration: Duration
        private var _doLinktest: Bool
        private var _linktestDuration: Duration
        
        internal init() {
            self._sessionId = 10
            self._isEquipment = true
            self._timeout = SECSCommunicatorTimeoutConfig()
            self._connectionMode = .passive
            self._ipAddress = nil
            self._port = 5000
            self._rebindDuration = .seconds(10.0)
            self._doLinktest = false
            self._linktestDuration = .seconds(120.0)
        }
        
        /// Session-ID.
        public var sessionId: UInt16 {
            get {
                return self._sessionId
            }
            set {
                guard newValue <= 0x7FFF else {
                    fatalError("Session-ID is 0...0x7FFF")
                }
                self._sessionId = newValue
            }
        }
        
        public var isEquipment: Bool {
            get {
                return self._isEquipment
            }
            set {
                self._isEquipment = newValue
            }
        }
        
        public var timeout: SECSCommunicatorTimeoutConfig {
            get {
                return self._timeout
            }
            set {
                self._timeout = newValue
            }
        }
        
        public var connectionMode: HSMSConnectionMode {
            get {
                return self._connectionMode
            }
            set {
                self._connectionMode = newValue
            }
        }
        
        public var ipAddress: NWEndpoint.Host? {
            get {
                return self._ipAddress
            }
            set {
                self._ipAddress = newValue
            }
        }
        
        public var port: NWEndpoint.Port {
            get {
                return self._port
            }
            set {
                self._port = newValue
            }
        }
        
        public var rebindDuration: Duration {
            get {
                return self._rebindDuration
            }
            set {
                guard newValue > .zero else {
                    fatalError("rebindDuration set value >0.0")
                }
                 self._rebindDuration = newValue
            }
        }
        
        public var autoLinktest: Bool {
            get {
                return self._doLinktest
            }
            set {
                self._doLinktest = newValue
            }
        }
        
        public var linktestDuration: Duration {
            get {
                return self._linktestDuration
            }
            set {
                guard newValue > .zero else {
                    fatalError("linktestTimeDuration set value >0.0")
                }
                self._linktestDuration = newValue
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
    
    // MARK: - var
    
    private nonisolated(unsafe) var _didReceiveWholeHSMSMessage: ((HSMSMessage, NWConnection) -> Void)?
    
    public nonisolated(unsafe) var config = HSMSSSCommunicatorConfig()
    
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
        self.session.hsmsMessageBuilder = { [weak self] in
            return self!.messageBuilder
        }
        self.session.hsmsMessageTransactor = { [weak self] in
            return self!.transactor
        }
        
        self._didReceiveWholeHSMSMessage = nil
    }
    
    deinit {
        self.shutdown()
    }
    
    /// Mark start, throws if already started or shutdown.
    ///
    /// - Throws:
    ///   - SECSCommunicatorStartAndShutdownError.alreadyShutdowned: if already shutdown.
    ///   - SECSCommunicatorStartAndShutdownError.alreadyStarted:  if already started.
    public func start() throws {
        try self.start(queue: DispatchQueue(label: "defaultDispatchQueueLabel"))
    }
    
    /// Mark start, throws if already started or shutdown.
    ///
    /// - Parameters:
    ///   - queue: the DispatchQueue
    /// - Throws:
    ///   - SECSCommunicatorStartAndShutdownError.alreadyShutdowned: if already shutdown.
    ///   - SECSCommunicatorStartAndShutdownError.alreadyStarted:  if already started.
    public func start(queue: DispatchQueue) throws {
        try self.startAndShutdown.start()
        
        // send HSMS-Message.
        queue.async { [weak self] in
            guard let self = self else { return }
            Task {
                let stream = await self.transactor.willSendMessageStream()
                for await pair in stream {
                    pair.connection.send(content: pair.message.data, contentContext: .defaultMessage, isComplete: true, completion: .contentProcessed({ error in
                        Task {
                            await self.transactor.yield(sendedMessage: pair.message, connection: pair.connection, error: error)
                            if let error = error {
                                Logger.nwConnection.error("\(error)")
                            } else {
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
            guard let self = self else { return  }
            let stream = await self.transactor.didReceiveMessageStream()
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
            
            // receive whole HSMS-Message.
            Task {
                let stream = self.receiveWholeHSMSMessageStream
                for await pair in stream {
                    self._didReceiveWholeHSMSMessage?(pair.message, pair.connection)
                    Logger.receiveHSMSMessage.notice("\(String(describing: pair.message))")
                }
                
                Logger.communicator.debug("receiveWholeHSMSMessageStream finished.")
            }
            
            await self.session.start()
            
            let task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    while !Task.isCancelled {
                        switch self.config.connectionMode {
                        case .active:
                            Logger.communicator.notice("HSMS-SS Active perform start.")
                            try await self.performActive(queue: queue)
                            try Task.checkCancellation()
                            
                            Logger.communicator.notice("HSMS-SS Active sleep T5-Timeout: \(self.config.timeout.t5)")
                            try await Task.sleep(for: self.config.timeout.t5)
                            
                        case .passive:
                            Logger.communicator.notice("HSMS-SS Passive perform start.")
                            try await self.performPassive(queue: queue)
                            try Task.checkCancellation()
                            
                            Logger.communicator.notice("HSMS-SS Passive sleep rebind duration: \(self.config.rebindDuration)")
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
            
            self._didReceiveWholeHSMSMessage = nil
            self.receiveWholeHSMSMessageContinuation.finish()
            await self.transactor.shutdown()
            await self.session.shutdown()
            
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
        get {
            return self.session.didUpdateCommunicationState
        }
        set {
            self.session.didUpdateCommunicationState = newValue
        }
    }
    
    public var didUpdateHSMSConnectionState: ((HSMSSession.HSMSConnectionState) -> Void)? {
        get {
            return self.session.didUpdateHSMSConnectionState
        }
        set {
            self.session.didUpdateHSMSConnectionState = newValue
        }
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
        get {
            return self.session.didReceivePrimaryDataSECSMessage
        }
        set {
            self.session.didReceivePrimaryDataSECSMessage = newValue
        }
    }
    
    // MARK: - HSMSMessageReceivable
    
    public var didReceiveWholeHSMSMessage: ((HSMSMessage, NWConnection) -> Void)? {
        get {
            return self._didReceiveWholeHSMSMessage
        }
        set {
            self._didReceiveWholeHSMSMessage = newValue
        }
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
    
    // MARK: - Active
    
    private func performActive(queue: DispatchQueue) async throws {
        guard let activeIpAddress = self.config.ipAddress else {
            fatalError("IP-Address not setted")
        }
        let connection = NWConnection(host: activeIpAddress, port: self.config.port, using: .tcp)
        let pipeline = self.newPipeline(connection: connection)
        
        defer {
            pipeline.shutdown()
            if connection.state != .cancelled {
                connection.cancel()
            }
        }
        
        do {
            try await connection.connect(queue: queue)
            
            guard await self.session.connectionAndState.set(connection: connection, state: .notSelected) else {
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
                            await self.transactor.yield(receiveMessage: pair.message, connection: pair.connection)
                            await linktestTimer.reset()
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
                            await self.session.connectionAndState.set(state: .selected)
                        default:
                            // select failed
                            return
                        }
                        
                        // Linktest
                        linktestTimer.linktest = { [weak self] in
                            guard let self = self else { return }
                            Task {
                                guard await self.linktest() else {
                                    await self.session.connectionAndState.unset()
                                    return
                                }
                            }
                        }
                        await linktestTimer.start()
                        
                        try await self.session.connectionAndState.hsmsConnectionStateUpdateNotifier.untilNot(.selected)
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
                await linktestTimer.shutdown()
                
                await self.session.connectionAndState.unset()
            }
        }
        catch let error as CancellationError {
            throw error
        }
        catch {
            Logger.nwConnection.error("\(error)")
        }
    }
    
    // MARK: - Passive
    
    private func performPassive(queue: DispatchQueue) async throws {
        do {
            let listener = try NWListenerStreamWrapper(using: .tcp, on: config.port)
            defer {
                listener.cancel()
            }
            
            try listener.start(queue: queue)
            
            let stream = listener.connectionAndQueueStream()
            for await result in stream {
                switch result {
                case .success(let pair):
                    Task {
                        do {
                            try await self.performPassiveConnection(connection: pair.connection, queue: pair.queue)
                        }
                        catch {
                            Logger.nwConnection.error("\(error)")
                        }
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
            Logger.nwConnection.error("\(error)")
        }
    }
    
    private func performPassiveConnection(connection: NWConnection, queue: DispatchQueue) async throws {
        let pipeline = self.newPipeline(connection: connection)
        
        defer {
            pipeline.shutdown()
            if connection.state != .cancelled {
                connection.cancel()
            }
        }
        
        try await connection.connect(queue: queue)
        
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
                        
                        guard await self.session.connectionAndState.set(connection: pair.connection, state: .notSelected, .selected) else {
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
                            await self.session.connectionAndState.unset()
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
                                await self.transactor.yield(receiveMessage: pair.message, connection: pair.connection)
                                await linktestTimer.reset()
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
                                        await self.session.connectionAndState.unset()
                                        return
                                    }
                                }
                            }
                            await linktestTimer.start()
                            
                            try await self.session.connectionAndState.hsmsConnectionStateUpdateNotifier.until(.notConnected)
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
                    await linktestTimer.shutdown()
                    
                    await self.session.connectionAndState.unset()
                }
            }
            
            await group.next()
            group.cancelAll()
        }
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
