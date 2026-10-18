//
//  GEM.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/08/10.
//

import Foundation
import Synchronization

public final class GEM: Sendable {
    
    internal init() {
        // Nothing
    }
    
    private let __gem = Mutex<(@Sendable () -> any SECSMessageSendable)?>(nil)
    
    internal var _communicator: (@Sendable () -> any SECSMessageSendable)? {
        get { self.__gem.withLock { $0 } }
        set { self.__gem.withLock { $0 = newValue } }
    }
    
    internal var communicator: any SECSMessageSendable {
        get { self._communicator!() }
    }
    
    private let __deviceId = Mutex<(@Sendable () -> UInt16)?>(nil)
    
    internal var _deviceId: (@Sendable () -> UInt16)? {
        get { self.__deviceId.withLock { $0 } }
        set { self.__deviceId.withLock { $0 = newValue } }
    }
    
    public var deviceId: UInt16 {
        get { self._deviceId!() }
    }
    
    private let __isEquipment = Mutex<(@Sendable () -> Bool)?>(nil)
    
    internal var _isEquipment: (@Sendable () -> Bool)? {
        get { self.__isEquipment.withLock { $0 } }
        set { self.__isEquipment.withLock { $0 = newValue } }
    }
    
    public var isEquipment: Bool {
        get { self._isEquipment!() }
    }
    
    /// GEMError
    public enum GEMError: Error {
        
        /// Not Data Message
        case notDataMessage(responseMesage: any SECSMessage)
        
        /// Unrecognized Device ID
        case unrecognizedDeviceID(responseMesage: any SECSMessage)
        
        /// Unmatch Stream Function
        case unmatchStreamFunction(responseMesage: any SECSMessage)
        
        /// Illegal Data
        case illegalData(responseMesage: any SECSMessage)
        
        /// Unknown
        case unknown
        
    }
    
    /// Check GEMError, throw if unmatch
    ///
    /// - Parameters:
    ///   - responseMessage: The response message
    ///   - stream: The expect stream number
    ///   - function: The expect function number
    /// - Throws:
    ///   - `GEMError`: if unexpected response.
    public func checkGEMError(responseMessage: SECSMessage, stream: UInt8, function: UInt8) throws {
        
        guard responseMessage.isDataMessage else {
            throw GEMError.notDataMessage(responseMesage: responseMessage)
        }
        
        // check Device-ID.
        let deviceIds = self.deviceId.toBytes()
        guard (responseMessage.header10Bytes[0] & 0x7F) == deviceIds[0] &&
                responseMessage.header10Bytes[1] == deviceIds[1] else {
            throw GEMError.unrecognizedDeviceID(responseMesage: responseMessage)
        }
        
        // check Stream Function.
        guard responseMessage.stream == stream,
              responseMessage.function == function else {
            throw GEMError.unmatchStreamFunction(responseMesage: responseMessage)
        }
        
    }
    
}
