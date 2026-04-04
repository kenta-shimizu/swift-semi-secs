//
//  HSMSMessage.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Foundation

public struct HSMSMessage: SECSMessage {
    
    /// HSMS-Message Type.
    public enum MessageType : CaseIterable, Sendable {
        
        /// DATA, P: 0x00, S: 0x00.
        case data
        /// SELECT.REQ, P: 0x00, S: 0x01.
        case selectRequest
        /// SELECT.RSP, P: 0x00, S: 0x02.
        case selectResponse
        /// DESELECT.REQ, P: 0x00, S: 0x03.
        case deselectRequest
        /// DESELECT.RSP, P: 0x00, S: 0x04.
        case deselectResponse
        /// LINKTEST.REQ, P: 0x00, S: 0x05.
        case linktestRequest
        /// LINKTEST.RSP, P: 0x00, S: 0x06.
        case linktestResponse
        /// REJECT.REQ, P: 0x00, S: 0x07.
        case rejectRequest
        /// SEPARATE.REQ, P: 0x00, S: 0x09.
        case separateRequest
        /// Unknown type.
        case unknown
        
        private var messageTypeProperty: (pType: UInt8, sType: UInt8, descString: String) {
            switch self {
            case .data:
                return (pType: 0x00, sType: 0x00, descString: "DATA")
            case .selectRequest:
                return (pType: 0x00, sType: 0x01, descString: "SELECT.REQ")
            case .selectResponse:
                return (pType: 0x00, sType: 0x02, descString: "SELECT.RSP")
            case .deselectRequest:
                return (pType: 0x00, sType: 0x03, descString: "DESELECT.REQ")
            case .deselectResponse:
                return (pType: 0x00, sType: 0x04, descString: "DESELECT.RSP")
            case .linktestRequest:
                return (pType: 0x00, sType: 0x05, descString: "LINKTEST.REQ")
            case .linktestResponse:
                return (pType: 0x00, sType: 0x06, descString: "LINKTEST.RSP")
            case .rejectRequest:
                return (pType: 0x00, sType: 0x07, descString: "REJECT.REQ")
            case .separateRequest:
                return (pType: 0x00, sType: 0x09, descString: "SEPARATE.REQ")
            default:
                return (pType: 0xFF, sType: 0xFF, descString: "???")
            }
        }
        
        public var pType: UInt8 {
            return self.messageTypeProperty.pType
        }
        
        public var sType: UInt8 {
            return self.messageTypeProperty.sType
        }
        
        public var descriptionString: String {
            return self.messageTypeProperty.descString
        }
        
        public static func get(pType: UInt8, sType: UInt8) -> Self {
            for i in Self.allCases {
                if (i.pType == pType) && (i.sType == sType) {
                    return i
                }
            }
            return .unknown
        }
        
        public static func hasPType(hsmsMessage: HSMSMessage) -> Bool {
            let pType = hsmsMessage.pType
            for i in Self.allCases {
                if i.pType == pType {
                    return true
                }
            }
            return false
        }
    }
    
    /// SELECT-Status. return in SELECT.RSP.
    public enum SelectStatus: CaseIterable, Sendable {
        
        case success
        case actived
        case notReady
        case alreadyUsed
        case entityUnknown
        case entityAlreadyUsed
        case entityActived
        
        case unknown
        
        public var statusByte: UInt8 {
            switch self {
            case .success:
                return 0x00
            case .actived:
                return 0x01
            case .notReady:
                return 0x02
            case .alreadyUsed:
                return 0x03
            case .entityUnknown:
                return 0x04
            case .entityAlreadyUsed:
                return 0x05
            case .entityActived:
                return 0x06
            case .unknown:
                return 0xFF
            }
        }
        
        public static func get(statusByte: UInt8) -> Self {
            for i in Self.allCases {
                if i.statusByte == statusByte {
                    return i
                }
            }
            return .unknown
        }
        
        public static func get(hsmsSelectRespnseMessage: HSMSMessage) -> Self {
            return Self.get(statusByte: hsmsSelectRespnseMessage.header10Bytes[3])
        }
        
    }
    
    /// DESELECT-Status. return in DESELECT.RSP.
    public enum DeselectStatus: CaseIterable, Sendable {
        
        /// Sucess, 0x00.
        case success
        /// No-Selected, 0x01.
        case noSelected
        /// Failed, 0x02.
        case failed
        /// Unknown status.
        case unknown
        
        public var statusByte: UInt8 {
            switch self {
            case .success:
                return 0x00
            case .noSelected:
                return 0x01
            case .failed:
                return 0x02
            case .unknown:
                return 0x00
            }
        }
        
        private static let statusSet: [Self] = [
            .success,
            .noSelected,
            .failed,
        ]
        
        public static func get(statusByte: UInt8) -> Self {
            for i in Self.statusSet {
                if i.statusByte == statusByte {
                    return i
                }
            }
            return .unknown
        }
        
        public static func get(hsmsDeselectRespnseMessage: HSMSMessage) -> Self {
            return Self.get(statusByte: hsmsDeselectRespnseMessage.header10Bytes[3])
        }
        
    }
    
    public enum RejectReason: CaseIterable, Sendable {
        
        case notSupportTypeS
        case notSupportTypeP
        case transactionNotOpen
        case notSelected
        
        case unknown
        
        public var reasonByte: UInt8 {
            switch self {
            case .notSupportTypeS:
                return 0x01
            case .notSupportTypeP:
                return 0x02
            case .transactionNotOpen:
                return 0x03
            case .notSelected:
                return 0x04
            case .unknown:
                return 0xFF
            }
        }
        
        public static func get(reasonByte: UInt8) -> Self {
            for i in Self.allCases {
                if i.reasonByte == reasonByte {
                    return i
                }
            }
            return .unknown
        }
        
        public static func get(hsmsRejectRequestMessage: HSMSMessage) -> Self {
            return Self.get(reasonByte: hsmsRejectRequestMessage.header10Bytes[3])
        }
        
    }
    
    
    private let _header10Bytes: Data
    private let _secs2Body: (any SECS2Body)?
    
    internal init(header10Bytes: Data, secs2Body:
    (any SECS2Body)?) {
        self._header10Bytes = header10Bytes
        self._secs2Body = secs2Body
    }
    
    public var data: Data {
        let r = self._header10Bytes + (self._secs2Body?.data ?? Data())
        let i = r.count
        return Data([
            UInt8((i >> 24) & 0x000000FF),
            UInt8((i >> 16) & 0x000000FF),
            UInt8((i >> 8) & 0x000000FF),
            UInt8(i & 0x000000FF),
        ]) + r
    }
    
    public var count: Int {
        return self._header10Bytes.count + (self._secs2Body?.data.count ?? 0)
    }
    
    public var secs2Body: (any SECS2Body)? {
        return self._secs2Body
    }
    
    public var header10Bytes: Data {
        return self._header10Bytes
    }
    
    public var sessionId: UInt16 {
        return UInt16(self._header10Bytes[0]) << 8 | UInt16(self._header10Bytes[1])
    }
    
    public var isDataMessage: Bool {
        return self.messageType == .data
    }
    
    public var pType: UInt8 {
        return self._header10Bytes[4]
    }
    
    public var sType: UInt8 {
        return self._header10Bytes[5]
    }
    
    public var messageType: MessageType {
        return MessageType.get(pType: self.pType, sType: self.sType)
    }
    
    private static let lineSeparator: String = "\n"
    private static let endMessage = "."
    
    public var header10BytesString: String {
        return String(format: "[%02X %02X|%02X %02X|%02X %02X|%02X %02X %02X %02X]",
                      self._header10Bytes[0],
                      self._header10Bytes[1],
                      self._header10Bytes[2],
                      self._header10Bytes[3],
                      self._header10Bytes[4],
                      self._header10Bytes[5],
                      self._header10Bytes[6],
                      self._header10Bytes[7],
                      self._header10Bytes[8],
                      self._header10Bytes[9])
    }
    
    public var description: String {
        var r = self.header10BytesString + " \(self.messageType.descriptionString) length:\(self.count)"
        if self.isDataMessage {
            r += "\(Self.lineSeparator)S\(self.stream)F\(self.function)"
            if self.wbit {
                r += " W"
            }
            if let secs2BodySmlString = self._secs2Body?.smlString {
                r += Self.lineSeparator + secs2BodySmlString
            }
            r += Self.endMessage
        }
        return r
    }
    
    public var debugDescription: String {
        return self.description;
    }
    
}
