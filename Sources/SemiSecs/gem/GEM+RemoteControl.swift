//
//  GEM+RemoteControl.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/09/10.
//

import Foundation

extension GEM {
    
    public enum HCACK: CaseIterable, CustomStringConvertible, CustomDebugStringConvertible, Sendable {
        
        /// Acknowledge, command has been performed, byte=0x00
        case acknowledge
        /// Command does not exist, byte=0x01
        case comamndNotExist
        /// Cannot perform now, byte=0x02
        case cannnotPerformNow
        /// At least one parameter is invalid, byte=0x03
        case parameterInvalid
        /// Acknowledge, command will be performed with completion signaled later by an event, byte=0x04
        case commandPerforming
        /// Rejected, Already in Desired Condition, byte=0x05
        case reject
        /// No such object exists, byte=0x06
        case notExistObjects
        
        private var itemProperty: (byte: UInt8, description: String) {
            switch self {
            case .acknowledge:
                return (byte: 0x00, description: "Acknowledge, command has been performed")
            case .comamndNotExist:
                return (byte: 0x01, description: "Command does not exist")
            case .cannnotPerformNow:
                return (byte: 0x02, description: "Cannot perform now")
            case .parameterInvalid:
                return (byte: 0x03, description: "At least one parameter is invalid")
            case .commandPerforming:
                return (byte: 0x04, description: "Acknowledge, command will be performed with completion signaled later by an event")
            case .reject:
                return (byte: 0x05, description: "Rejected, Already in Desired Condition")
            case .notExistObjects:
                return (byte: 0x06, description: "No such object exists")
            }
        }
        
        public init?(byte: UInt8) {
            for i in Self.allCases {
                if i.itemProperty.byte == byte {
                    self = i
                    return
                }
            }
            return nil
        }
        
        public var uint8Value: UInt8 {
            get {
                return self.itemProperty.byte
            }
        }
        
        public var description: String {
            return self.itemProperty.description
        }

        public var debugDescription: String {
            return self.description
        }
        
    }
    
}
