//
//  HSMSSession.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/04/04.
//

import Foundation
import os
import Network
import Synchronization

/// HSMS Session
public final class  HSMSSession: HSMSMessageSendable, SECSMessageReceivable, HSMSConnectionStateDetectable, Sendable {
    
    /// HSMS connection state
    public enum HSMSConnectionState: String, Sendable {
        case notConnected = "NOT_CONNECTED"
        case notSelected = "NOT_SELECTED"
        case selected = "SELECTED"
    }
    
    /// NWConnecgion and HSMSConnectionState
    internal struct NWConnectionAndHSMSConnectionState {
        
        internal var connection: NWConnection?
        internal let hsmsConnectionStateUpdateNotifier = StateUpdateNotifier<HSMSConnectionState>(state: .notConnected)
        
        internal init() {
            self.connection = nil
        }
        
        /// NWConnection and HSMSConnectionState getter.
        internal var bothValue: (connection: NWConnection?, state: HSMSConnectionState) {
            get { (self.connection , self.hsmsConnectionStateUpdateNotifier.lastState) }
        }
        
        internal mutating func shutdown() {
            self.connection = nil
            self.hsmsConnectionStateUpdateNotifier.shutdown()
        }
        
        /// set NWConnection and HSMSConnectionState
        ///
        /// - Returns: true if NWConnection is NOT already setted, otherwise false.
        @discardableResult
        internal mutating func set(connection: NWConnection, state: HSMSConnectionState...) -> Bool {
            guard self.connection == nil else { return false }
            self.connection = connection
            for s in state {
                self.hsmsConnectionStateUpdateNotifier.yield(s)
                self.logging(state: s)
            }
            return true
        }
        
        internal mutating func set(state: HSMSConnectionState...) {
            for s in state {
                self.hsmsConnectionStateUpdateNotifier.yield(s)
                self.logging(state: s)
            }
        }
        
        internal mutating func unset() {
            self.connection = nil
            self.set(state: .notConnected)
        }
        
        private func logging(state: HSMSConnectionState) {
            if let connection = self.connection {
                Logger.hsmsConnectionState.notice("state: \(state.rawValue), connection: \(String(describing: connection))")
            } else {
                Logger.hsmsConnectionState.notice("state: \(state.rawValue), connection: nil")
            }
        }
    }
    
    // MARK: - let
    
    private let _gem = GEM()
    private let communicatableNotifier = StateUpdateNotifier<Bool>(state: false)
    internal let (receiveHSMSMessageStream, receiveHSMSMessageCotinuation) = AsyncStream.makeStream(of: HSMSMessage.self)
    internal let connectionAndState = Mutex<NWConnectionAndHSMSConnectionState>(NWConnectionAndHSMSConnectionState())
    
    // MARK: - var
    
    private let _hsmsSessionId = Mutex<(@Sendable () -> UInt16)?>(nil)
    
    internal var hsmsSessionId: (@Sendable () -> UInt16)? {
        get { self._hsmsSessionId.withLock { $0 } }
        set { self._hsmsSessionId.withLock { $0 = newValue } }
    }
    
    private let _isEquipment = Mutex<(@Sendable () -> Bool)?>(nil)

    internal var isEquipment: (@Sendable () -> Bool)? {
        get { self._isEquipment.withLock { $0 } }
        set { self._isEquipment.withLock { $0 = newValue } }
    }
    
    private let _hsmsMessageBuilder = Mutex<(@Sendable () -> HSMSMessageBuildable)?>(nil)

    internal var hsmsMessageBuilder: (@Sendable () -> HSMSMessageBuildable)? {
        get { self._hsmsMessageBuilder.withLock { $0 } }
        set { self._hsmsMessageBuilder.withLock { $0 = newValue } }
    }
    
    private let _hsmsMessageTransactor = Mutex<(@Sendable () -> HSMSMessageTransactor)?>(nil)
    
    internal var hsmsMessageTransactor: (@Sendable () -> HSMSMessageTransactor)? {
        get { self._hsmsMessageTransactor.withLock { $0 } }
        set { self._hsmsMessageTransactor.withLock { $0 = newValue } }
    }
    
    // MARK: -
    
    internal init() {
        self._gem._communicator = { [weak self] in
            return self!
        }
        self._gem._deviceId = { [weak self] in
            return self!.hsmsSessionId!()
        }
        self._gem._isEquipment = { [weak self] in
            return self!.isEquipment!()
        }
    }
    
    internal func start() {
        // HSMS-Connection-State notifier
        Task { [weak self] in
            guard let self = self else { return }
            let stream = self.connectionAndState.withLock { $0.hsmsConnectionStateUpdateNotifier.stateUpdateStream() }
            for await state in stream {
                self._didUpdateHSMSConnectionState.accept(state)
                self.communicatableNotifier.yield(state == .selected)
            }
        }
        // SECS-Communicate-State notifier
        Task { [weak self] in
            guard let self = self else { return  }
            let stream = self.communicatableNotifier.stateUpdateStream()
            for await state in stream {
                self._didUpdateCommunicationState.accept(state)
            }
        }
        // Receive SECS-Message observer
        Task { [weak self] in
            guard let self = self else { return }
            for await message in receiveHSMSMessageStream {
                self._didReceivePrimaryDataSECSMessage.accept(message)
            }
        }
        
    }
    
    internal func shutdown() {
        self.connectionAndState.withLock { $0.shutdown() }
        self.communicatableNotifier.shutdown()
        self.receiveHSMSMessageCotinuation.finish()
    }
    
    /// Session-ID
    public var sessionId: UInt16 {
        get { self.hsmsSessionId!() }
    }
    
    // MARK: - HSMSConnectionStateDetectable
    
    private let _didUpdateCommunicationState = MutexConsumerWrapper<Bool>()

    public var didUpdateCommunicationState: ((Bool) -> Void)? {
        get { self._didUpdateCommunicationState.consumer }
        set { self._didUpdateCommunicationState.consumer = newValue }
    }
    
    private let _didUpdateHSMSConnectionState = MutexConsumerWrapper<HSMSConnectionState>()
    
    public var didUpdateHSMSConnectionState: ((HSMSConnectionState) -> Void)? {
        get { self._didUpdateHSMSConnectionState.consumer }
        set { self._didUpdateHSMSConnectionState.consumer = newValue }
    }
    
    public func until(connectionState: HSMSConnectionState) async throws {
        let notifier = self.connectionAndState.withLock { $0.hsmsConnectionStateUpdateNotifier }
        Logger.hsmsConnectionState.notice("wait until HSMS-Connection-state: \(connectionState.rawValue)")
        try await notifier.until(connectionState)
    }
    
    public func untilNot(connectionState: HSMSConnectionState) async throws {
        let notifier = self.connectionAndState.withLock { $0.hsmsConnectionStateUpdateNotifier }
        Logger.hsmsConnectionState.notice("wait until NOT HSMS-Connection-state: \(connectionState.rawValue)")
        try await notifier.untilNot(connectionState)
    }
    
    @discardableResult
    public func until(connectionState: HSMSConnectionState, timeout: Duration) async throws -> Bool {
        let notifier = self.connectionAndState.withLock { $0.hsmsConnectionStateUpdateNotifier }
        Logger.hsmsConnectionState.notice("wait until HSMS-Connection-state: \(connectionState.rawValue), timeout: \(timeout)")
        return try await notifier.until(connectionState, timeout: timeout)
    }
    
    @discardableResult
    public func untilNot(connectionState: HSMSConnectionState, timeout: Duration) async throws -> Bool {
        let notifier = self.connectionAndState.withLock { $0.hsmsConnectionStateUpdateNotifier }
        Logger.hsmsConnectionState.notice("wait until NOT HSMS-Connection-state: \(connectionState.rawValue), timeout: \(timeout)")
        return try await notifier.untilNot(connectionState, timeout: timeout)
    }
    
    // MARK: - SECSMessageReceivable
    
//    private let _didReceivePrimaryDataSECSMessage = Mutex<(@Sendable (any SECSMessage) -> Void)?>(nil)
    private let _didReceivePrimaryDataSECSMessage = MutexConsumerWrapper<any SECSMessage>()
    
    public var didReceivePrimaryDataSECSMessage: ((any SECSMessage) -> Void)? {
        get { self._didReceivePrimaryDataSECSMessage.consumer }
        set { self._didReceivePrimaryDataSECSMessage.consumer = newValue }
    }
    
    // MARK: - HSMSMessageSendable
    
    private func messageBuilderOrThrowing() throws -> HSMSMessageBuildable {
        guard let builder = self.hsmsMessageBuilder?() else {
            throw HSMSSendError.sendFailedByCommunicatorShutdowned(message: nil, connection: nil)
        }
        return builder
    }
    
    private func interSendAndAwaitResponse(message: HSMSMessage) async throws -> HSMSMessage? {
        let connection = self.connectionAndState.withLock { $0.connection }
        guard let connection = connection else {
            throw HSMSSendError.sendFailedByNotConnected(message: message)
        }
        return try await self.hsmsMessageTransactor!().sendAndAwaitResponse(message: message, connection: connection)
    }
    
    private func interSend(message: HSMSMessage) async throws {
        let connection = self.connectionAndState.withLock { $0.connection }
        guard let connection = connection else {
            throw HSMSSendError.sendFailedByNotConnected(message: message)
        }
        try await self.hsmsMessageTransactor!().send(message: message, connection: connection)
    }
    
    @discardableResult
    public func send(message: HSMSMessage) async throws -> HSMSMessage? {
        do {
            return try await self.interSendAndAwaitResponse(message: message)
        }
        catch {
            Logger.communicator.error("\(error)")
            throw error
        }
    }
    
    @discardableResult
    public func send(smlMessage: SMLMessage) async throws -> SECSMessage? {
        do {
            let builder = try self.messageBuilderOrThrowing()
            let message = builder.buildPrimaryData(sessionId: self.sessionId, smlMessage: smlMessage)
            return try await self.interSendAndAwaitResponse(message: message)
        }
        catch {
            Logger.communicator.error("\(error)")
            throw error
        }
    }
    
    public func reply(primaryMessage: SECSMessage, smlMessage: SMLMessage) async throws {
        do {
            let builder = try self.messageBuilderOrThrowing()
            let message = builder.buildResponseData(primaryMessage: primaryMessage, smlMessage: smlMessage)
            try await self.interSend(message: message)
        }
        catch {
            Logger.communicator.error("\(error)")
            throw error
        }
    }
    
    @discardableResult
    public func sendSelectRequest() async throws -> HSMSMessage? {
        do {
            let builder = try self.messageBuilderOrThrowing()
            let message = builder.buildSelectRequest(sessionId: self.sessionId)
            return try await self.interSendAndAwaitResponse(message: message)
        }
        catch {
            Logger.communicator.error("\(error)")
            throw error
        }
    }
    
    public func replySelectResponse(selectRequest: HSMSMessage, selectStatus: HSMSMessage.SelectStatus) async throws {
        do {
            let builder = try self.messageBuilderOrThrowing()
            let message = builder.buildSelectResponse(selectRequest: selectRequest, selectStatus: selectStatus)
            try await self.interSend(message: message)
        }
        catch {
            Logger.communicator.error("\(error)")
            throw error
        }
    }
    
    @discardableResult
    public func sendDeselectRequest() async throws -> HSMSMessage? {
        do {
            let builder = try self.messageBuilderOrThrowing()
            let message = builder.buildDeselectRequest(sessionId: self.sessionId)
            return try await self.interSendAndAwaitResponse(message: message)
        }
        catch {
            Logger.communicator.error("\(error)")
            throw error
        }
    }
    
    public func replyDeselectResponse(deselectRequest: HSMSMessage, deselectStatus: HSMSMessage.DeselectStatus) async throws {
        do {
            let builder = try self.messageBuilderOrThrowing()
            let message = builder.buildDeselectResponse(deselectRequest: deselectRequest, deselectStatus: deselectStatus)
            try await self.interSend(message: message)
        }
        catch {
            Logger.communicator.error("\(error)")
            throw error
        }
    }
    
    @discardableResult
    public func sendLinktestRequest() async throws -> HSMSMessage? {
        do {
            let builder = try self.messageBuilderOrThrowing()
            let message = builder.buildLinktestRequest(sessionId: self.sessionId)
            return try await self.interSendAndAwaitResponse(message: message)
        }
        catch {
            Logger.communicator.error("\(error)")
            throw error
        }
    }
    
    public func replyLinktestResponse(linktestRequest: HSMSMessage) async throws {
        do {
            let builder = try self.messageBuilderOrThrowing()
            let message = builder.buildLinktestResponse(linktestRequest: linktestRequest)
            try await self.interSend(message: message)
        }
        catch {
            Logger.communicator.error("\(error)")
            throw error
        }
    }
    
    public func replyRejectRequest(referenceMessage: HSMSMessage, rejectReason: HSMSMessage.RejectReason, byte2: UInt8) async throws {
        do {
            let builder = try self.messageBuilderOrThrowing()
            let message = builder.buildRejectRequest(referenceMessage: referenceMessage, rejectReason: rejectReason, byte2: byte2)
            try await self.interSend(message: message)
        }
        catch {
            Logger.communicator.error("\(error)")
            throw error
        }
    }
    
    public func sendSeparateRequest() async throws {
        do {
            let builder = try self.messageBuilderOrThrowing()
            let message = builder.buildSeparateRequest(sessionId: self.sessionId)
            try await self.interSend(message: message)
        }
        catch {
            Logger.communicator.error("\(error)")
            throw error
        }
    }
    
    public var gem: GEM {
        get {
            return self._gem
        }
    }
    
}

