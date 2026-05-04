//
//  HSMSSession.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/04/04.
//

import Foundation
import Network

public final class  HSMSSession: HSMSMessageSendable, SECSPrimaryDataMessageReceivable, AsyncShutdownable, Sendable {
    
    public enum HSMSConnectionState: String, Sendable {
        case notConnected = "NOT_CONNECTED"
        case notSelected = "NOT_SELECTED"
        case selected = "SELECTED"
    }
    
    internal actor NWConnectionAndHSMSConnectionState {
        
        internal var nwConnection: NWConnection?
        
        internal let stateUpdateNotifier = AsyncStateUpdateNotifier<HSMSConnectionState>(state: .notConnected)
        
        internal init() {
            self.nwConnection = nil
        }
        
        internal func shutdown() async {
            self.nwConnection = nil
            await self.stateUpdateNotifier.shutdown()
        }
        
        internal func set(connection: NWConnection, state: HSMSConnectionState...) async throws {
            self.nwConnection = connection
            for s in state {
                try await self.stateUpdateNotifier.set(state: s)
            }
        }
        
        internal func set(state: HSMSConnectionState...) async throws {
            for s in state {
                try await self.stateUpdateNotifier.set(state: s)
            }
        }
        
        internal func unset() async throws {
            self.nwConnection = nil
            try await self.stateUpdateNotifier.set(state: .notConnected)
        }
    }
    
    private let connectionAndState = NWConnectionAndHSMSConnectionState()
    
    private nonisolated(unsafe) var lastHSMSConnectionState: HSMSConnectionState {
        didSet {
            self.onDidUpdateHSMSConnectionState?(lastHSMSConnectionState)
        }
    }
    
    internal nonisolated(unsafe) var hsmsSessionId: (() -> UInt16)?
    internal nonisolated(unsafe) var hsmsMessageBuilder: (() -> HSMSMessageBuildable)?
    internal nonisolated(unsafe) var hsmsMessageTransactor: (() -> HSMSMessageTransactor)?
    
    internal let receivePrimaryDataMessageNotifier = AsyncStreamNotifier<HSMSMessage>()
    
    private nonisolated(unsafe) var _onDidReceiveSECSPrimaryDataMessage: ((any SECSMessage) -> Void)?
    
    internal init() {
        
        self.hsmsMessageBuilder = nil
        self.hsmsMessageTransactor = nil
        self.hsmsSessionId = nil
        
        self.lastHSMSConnectionState = .notSelected
        self.onDidUpdateHSMSConnectionState = nil
        
        self._onDidReceiveSECSPrimaryDataMessage = nil
    }
    
    internal func start() async {
        
        do {
            try await self.connectionAndState.stateUpdateNotifier.append {
                if let state = $0 {
                    self.lastHSMSConnectionState = state
                }
            }
        }
        catch {
        }
        
        do {
            try await self.receivePrimaryDataMessageNotifier.append {
                self._onDidReceiveSECSPrimaryDataMessage?($0)
            }
        }
        catch {
        }

    }
    
    internal func shutdown() async {
        self.hsmsMessageBuilder = nil
        self.hsmsMessageTransactor = nil
        self.hsmsSessionId = nil
        self.onDidUpdateHSMSConnectionState = nil
        self._onDidReceiveSECSPrimaryDataMessage = nil
        
        await self.connectionAndState.shutdown()
        await self.receivePrimaryDataMessageNotifier.shutdown()
    }
    
    /// Session-ID
    public var sessionId: UInt16 {
        get {
            return self.hsmsSessionId!()
        }
    }
    
    /// HSMS-Connection-State
    public var hsmsConnectionState: HSMSConnectionState {
        get {
            return self.lastHSMSConnectionState
        }
    }
    
    public nonisolated(unsafe) var onDidUpdateHSMSConnectionState: ((HSMSConnectionState) -> Void)? {
        didSet {
            onDidUpdateHSMSConnectionState?(self.lastHSMSConnectionState)
        }
    }
    
    public var onDidReceiveSECSPrimaryDataMessage: ((any SECSMessage) -> Void)? {
        get {
            return self._onDidReceiveSECSPrimaryDataMessage
        }
        set {
            self._onDidReceiveSECSPrimaryDataMessage = newValue
        }
    }
    
    @discardableResult
    public func send(message: HSMSMessage) async throws -> HSMSMessage? {
        
        guard let nwConnection = await self.connectionAndState.nwConnection else {
            throw HSMSError.sendFailedByNotConnected(message: message)
        }
        guard let transactor = self.hsmsMessageTransactor?() else {
            throw HSMSError.sendFailedByCommunicatorShutdowned(message: message, connection: nwConnection)
        }
        
        return try await transactor.send(message: message, connection: nwConnection)
    }
    
    public func reply(message: HSMSMessage) async throws {
        
        guard let nwConnection = await self.connectionAndState.nwConnection else {
            throw HSMSError.sendFailedByNotConnected(message: message)
        }
        guard let transactor = self.hsmsMessageTransactor?() else {
            throw HSMSError.sendFailedByCommunicatorShutdowned(message: message, connection: nwConnection)
        }
        
        try await transactor.reply(message: message, connection: nwConnection)
    }
    
    @discardableResult
    public func send(smlMessage: SMLMessage) async throws -> SECSMessage? {
        
        guard let builder = self.hsmsMessageBuilder?() else {
            throw HSMSError.sendFailedByCommunicatorShutdowned(messageType: .data, smlMessage: smlMessage)
        }
        
        let message = builder.buildPrimaryData(sessionId: self.sessionId, smlMessage: smlMessage)
        return try await self.send(message: message)
    }
    
    public func reply(primaryMessage: SECSMessage, smlMessage: SMLMessage) async throws {
        
        guard let builder = self.hsmsMessageBuilder?() else {
            throw HSMSError.sendFailedByCommunicatorShutdowned(messageType: .data, primaryMessage: primaryMessage, smlMessage: smlMessage)
        }
        
        let message = builder.buildResponseData(primaryMessage: primaryMessage, smlMessage: smlMessage)
        try await self.reply(message: message)
    }
    
    @discardableResult
    public func sendSelectRequest() async throws -> HSMSMessage? {
        
        guard let builder = self.hsmsMessageBuilder?() else {
            throw HSMSError.sendFailedByCommunicatorShutdowned(messageType: .selectRequest)
        }
        
        let message = builder.buildSelectRequest(sessionId: self.sessionId)
        return try await self.send(message: message)
    }
    
    public func replySelectResponse(selectRequest: HSMSMessage, selectStatus: HSMSMessage.SelectStatus) async throws {
        
        guard let builder = self.hsmsMessageBuilder?() else {
            throw HSMSError.sendFailedByCommunicatorShutdowned(messageType: .selectResponse, primaryMessage: selectRequest)
        }
        
        let message = builder.buildSelectResponse(selectRequest: selectRequest, selectStatus: selectStatus)
        try await self.reply(message: message)
    }
    
    @discardableResult
    public func sendDeselectRequest() async throws -> HSMSMessage? {
        
        guard let builder = self.hsmsMessageBuilder?() else {
            throw HSMSError.sendFailedByCommunicatorShutdowned(messageType: .deselectRequest)
        }
        
        let message = builder.buildDeselectRequest(sessionId: self.sessionId)
        return try await self.send(message: message)
    }
    
    public func replyDeselectResponse(deselectRequest: HSMSMessage, deselectStatus: HSMSMessage.DeselectStatus) async throws {
        
        guard let builder = self.hsmsMessageBuilder?() else {
            throw HSMSError.sendFailedByCommunicatorShutdowned(messageType: .deselectResponse, primaryMessage: deselectRequest)
        }
        
        let message = builder.buildDeselectResponse(deselectRequest: deselectRequest, deselectStatus: deselectStatus)
        try await self.reply(message: message)
    }
    
    @discardableResult
    public func sendLinktestRequest() async throws -> HSMSMessage? {
        
        guard let builder = self.hsmsMessageBuilder?() else {
            throw HSMSError.sendFailedByCommunicatorShutdowned(messageType: .linktestRequest)
        }
        
        let message = builder.buildLinktestRequest(sessionId: self.sessionId)
        return try await self.send(message: message)
    }
    
    public func replyLinktestResponse(linktestRequest: HSMSMessage) async throws {
        
        guard let builder = self.hsmsMessageBuilder?() else {
            throw HSMSError.sendFailedByCommunicatorShutdowned(messageType: .selectResponse, primaryMessage: linktestRequest)
        }
        
        let message = builder.buildLinktestResponse(linktestRequest: linktestRequest)
        try await self.reply(message: message)
    }
    
    public func replyRejectRequest(referenceMessage: HSMSMessage, rejectReason: HSMSMessage.RejectReason, byte2: UInt8) async throws {
        
        guard let builder = self.hsmsMessageBuilder?() else {
            throw HSMSError.sendFailedByCommunicatorShutdowned(messageType: .rejectRequest, referenceMessage: referenceMessage)
        }
        
        let message = builder.buildRejectRequest(referenceMessage: referenceMessage, rejectReason: rejectReason, byte2: byte2)
        try await self.reply(message: message)
    }
    
    public func sendSeparateRequest() async throws {
        
        guard let builder = self.hsmsMessageBuilder?() else {
            throw HSMSError.sendFailedByCommunicatorShutdowned(messageType: .separateRequest)
        }
        
        let message = builder.buildSeparateRequest(sessionId: self.sessionId)
        try await self.reply(message: message)
    }
    
}

