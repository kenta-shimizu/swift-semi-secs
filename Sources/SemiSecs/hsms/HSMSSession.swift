//
//  HSMSSession.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/04/04.
//

import Foundation
import os
import Network

/// HSMS Session
public final class  HSMSSession: HSMSMessageSendable, SECSMessageReceivable, HSMSConnectionStateDetectable, Sendable {
    
    /// HSMS connection state
    public enum HSMSConnectionState: String, Sendable {
        case notConnected = "NOT_CONNECTED"
        case notSelected = "NOT_SELECTED"
        case selected = "SELECTED"
    }
    
    internal actor NWConnectionAndHSMSConnectionState {
        
        internal var connection: NWConnection?
        internal let hsmsConnectionStateUpdateNotifier: StateUpdateNotifier<HSMSConnectionState>
        
        internal init() {
            self.connection = nil
            self.hsmsConnectionStateUpdateNotifier = StateUpdateNotifier<HSMSConnectionState>(state: .notConnected)
        }
        
        internal func shutdown() async {
            self.connection = nil
            await self.hsmsConnectionStateUpdateNotifier.shutdown()
        }
        
        @discardableResult
        internal func set(connection: NWConnection, state: HSMSConnectionState...) async -> Bool {
            guard self.connection == nil else { return false }
            self.connection = connection
            for s in state {
                await self.hsmsConnectionStateUpdateNotifier.yield(s)
                self.logging(state: s)
            }
            return true
        }
        
        internal func set(state: HSMSConnectionState...) async {
            for s in state {
                await self.hsmsConnectionStateUpdateNotifier.yield(s)
                self.logging(state: s)
            }
        }
        
        internal func unset() async {
            self.connection = nil
            await self.set(state: .notConnected)
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
    
    internal let connectionAndState = NWConnectionAndHSMSConnectionState()
    private let communicatableNotifier = StateUpdateNotifier<Bool>(state: false)
    internal let (receiveHSMSMessageStream, receiveHSMSMessageCotinuation) = AsyncStream.makeStream(of: HSMSMessage.self)
    
    // MARK: - var
    
    internal nonisolated(unsafe) var hsmsSessionId: (() -> UInt16)?
    internal nonisolated(unsafe) var hsmsMessageBuilder: (() -> HSMSMessageBuildable)?
    internal nonisolated(unsafe) var hsmsMessageTransactor: (() -> HSMSMessageTransactor)?
    
    private nonisolated(unsafe) var _didUpdateHSMSConnectionState: ((HSMSConnectionState) -> Void)?
    
    private nonisolated(unsafe) var _didUpdateCommunicationState: ((Bool) -> Void)?
    
    private nonisolated(unsafe) var _didReceivePrimaryDataSECSMessage: ((any SECSMessage) -> Void)?
    
    // MARK: -
    
    internal init() {
        self.hsmsMessageBuilder = nil
        self.hsmsMessageTransactor = nil
        self.hsmsSessionId = nil
        
        self._didUpdateHSMSConnectionState = nil
        self._didUpdateCommunicationState = nil
        self._didReceivePrimaryDataSECSMessage = nil
    }
    
    internal func start() async {
        // HSMS-Connection-State notifier
        Task { [weak self] in
            guard let self = self else { return }
            let stream = self.connectionAndState.hsmsConnectionStateUpdateNotifier.stateUpdateStream()
            for await state in stream {
                self._didUpdateHSMSConnectionState?(state)
                await self.communicatableNotifier.yield(state == .selected)
            }
        }
        // SECS-Communicate-State notifier
        Task { [weak self] in
            guard let self = self else { return  }
            let stream = self.communicatableNotifier.stateUpdateStream()
            for await state in stream {
                self._didUpdateCommunicationState?(state)
            }
        }
        // Receive SECS-Message observer
        Task { [weak self] in
            guard let self = self else { return }
            for await message in receiveHSMSMessageStream {
                self._didReceivePrimaryDataSECSMessage?(message)
            }
        }
        
    }
    
    internal func shutdown() async {
        self.hsmsMessageBuilder = nil
        self.hsmsMessageTransactor = nil
        self.hsmsSessionId = nil
        self._didUpdateHSMSConnectionState = nil
        self._didUpdateCommunicationState = nil
        self._didReceivePrimaryDataSECSMessage = nil
        
        await self.connectionAndState.shutdown()
        await self.communicatableNotifier.shutdown()
        self.receiveHSMSMessageCotinuation.finish()
    }
    
    /// Session-ID
    public var sessionId: UInt16 {
        get {
            return self.hsmsSessionId!()
        }
    }
    
    // MARK: - HSMSConnectionStateDetectable
    
    public var didUpdateCommunicationState: ((Bool) -> Void)? {
        get {
            return self._didUpdateCommunicationState
        }
        set {
            self._didUpdateCommunicationState = newValue
        }
    }
    
    public var didUpdateHSMSConnectionState: ((HSMSConnectionState) -> Void)? {
        get {
            return self._didUpdateHSMSConnectionState
        }
        set {
            self._didUpdateHSMSConnectionState = newValue
        }
    }
    
    public func until(connectionState: HSMSConnectionState) async throws {
        Logger.hsmsConnectionState.notice("wait until HSMS-Connection-state: \(connectionState.rawValue)")
        try await self.connectionAndState.hsmsConnectionStateUpdateNotifier.until(connectionState)
    }
    
    public func untilNot(connectionState: HSMSConnectionState) async throws {
        Logger.hsmsConnectionState.notice("wait until NOT HSMS-Connection-state: \(connectionState.rawValue)")
        try await self.connectionAndState.hsmsConnectionStateUpdateNotifier.untilNot(connectionState)
    }
    
    @discardableResult
    public func until(connectionState: HSMSConnectionState, timeout: Duration) async throws -> Bool {
        Logger.hsmsConnectionState.notice("wait until HSMS-Connection-state: \(connectionState.rawValue), timeout: \(timeout)")
        return try await self.connectionAndState.hsmsConnectionStateUpdateNotifier.until(connectionState, timeout: timeout)
    }
    
    @discardableResult
    public func untilNot(connectionState: HSMSConnectionState, timeout: Duration) async throws -> Bool {
        Logger.hsmsConnectionState.notice("wait until NOT HSMS-Connection-state: \(connectionState.rawValue), timeout: \(timeout)")
        return try await self.connectionAndState.hsmsConnectionStateUpdateNotifier.untilNot(connectionState, timeout: timeout)
    }
    
    // MARK: - SECSMessageReceivable

    public var didReceivePrimaryDataSECSMessage: ((any SECSMessage) -> Void)? {
        get {
            return self._didReceivePrimaryDataSECSMessage
        }
        set {
            self._didReceivePrimaryDataSECSMessage = newValue
        }
    }
    
    // MARK: - HSMSMessageSendable
    
    private func messageBuilderOrThrowing() throws -> HSMSMessageBuildable {
        guard let builder = self.hsmsMessageBuilder?() else {
            throw HSMSSendError.sendFailedByCommunicatorShutdowned(message: nil, connection: nil)
        }
        return builder
    }
    
    private func interSendAndAwaitResponse(message: HSMSMessage) async throws -> HSMSMessage? {
        guard let connection = await self.connectionAndState.connection else {
            throw HSMSSendError.sendFailedByNotConnected(message: message)
        }
        return try await self.hsmsMessageTransactor!().sendAndAwaitResponse(message: message, connection: connection)
    }
    
    private func interSend(message: HSMSMessage) async throws {
        guard let connection = await self.connectionAndState.connection else {
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
    
}

