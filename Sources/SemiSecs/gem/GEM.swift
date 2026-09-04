//
//  GEM.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/08/10.
//

import Foundation

public final class GEM: Sendable {
    
    public internal(set) nonisolated(unsafe) var communicator: (any SECSMessageSendable)?
    public internal(set) nonisolated(unsafe) var deviceId: (() -> UInt16)?
    public internal(set) nonisolated(unsafe) var isEquipment: (() -> Bool)?
    
    internal init() {
        self.communicator = nil
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
        if let deviceId = self.deviceId?() {
            let b0 = UInt8(deviceId >> 8)
            let b1 = UInt8(deviceId & 0x00FF)
            guard (responseMessage.header10Bytes[0] & 0x7F) == b0 &&
                    responseMessage.header10Bytes[1] == b1 else {
                throw GEMError.unrecognizedDeviceID(responseMesage: responseMessage)
            }
        }
        
        // check Stream Function.
        guard responseMessage.stream == stream,
              responseMessage.function == function else {
            throw GEMError.unmatchStreamFunction(responseMesage: responseMessage)
        }
        
    }
    
}
