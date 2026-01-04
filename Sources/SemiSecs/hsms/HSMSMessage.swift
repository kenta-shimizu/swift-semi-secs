//
//  HSMSMessage.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Foundation

public struct HSMSMessage: SECSMessage {
    
    public enum MessageType : Sendable {
        
        case data
        case selectRequest
        case selectResponse
        case deselectRequest
        case deselectResponse
        case linktestRequest
        case linktestResponse
        case rejectRequest
        case separateRequest
        
        case unknown
        
        
        private var messageTypeProperty: (pType: UInt8, sType: UInt8, descString: String) {
            switch self {
            case .data:
                return (pType: 0x00, sType: 0x00, descString: "DATA")
            case .selectRequest:
                return (pType: 0x00, sType: 0x01, descString: "SELECT.req")
            case .selectResponse:
                return (pType: 0x00, sType: 0x02, descString: "SELECT.rsp")
            case .deselectRequest:
                return (pType: 0x00, sType: 0x03, descString: "DESELECT.req")
            case .deselectResponse:
                return (pType: 0x00, sType: 0x04, descString: "DESELECT.rsp")
            case .linktestRequest:
                return (pType: 0x00, sType: 0x05, descString: "LINKTEST.req")
            case .linktestResponse:
                return (pType: 0x00, sType: 0x06, descString: "LINKTEST.rsp")
            case .rejectRequest:
                return (pType: 0x00, sType: 0x07, descString: "REJECT.req")
            case .separateRequest:
                return (pType: 0x00, sType: 0x09, descString: "SEPARATE.req")
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
        
        private static let messageTypeSet: [Self] = [
            .data,
            .selectRequest,
            .selectResponse,
            .deselectRequest,
            .deselectResponse,
            .linktestRequest,
            .linktestResponse,
            .rejectRequest,
            .separateRequest,
        ]
        
        public static func get(pType: UInt8, sType: UInt8) -> Self {
            for i in Self.messageTypeSet {
                if (i.pType == pType) && (i.sType == sType) {
                    return i
                }
            }
            return .unknown
        }
        
        public static func hasPType(hsmsMessage: HSMSMessage) -> Bool {
            let pType = hsmsMessage.pType
            for i in Self.messageTypeSet {
                if i.pType == pType {
                    return true
                }
            }
            return false
        }
    }
    
    public enum SelectStatus: Sendable {
        
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
        
        private static let statusSet: [Self] = [
            .success,
            .actived,
            .notReady,
            .alreadyUsed,
            .entityUnknown,
            .entityAlreadyUsed,
            .entityActived,
        ]
        
        public static func get(statusByte: UInt8) -> Self {
            for i in Self.statusSet {
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
    
    public enum DeselectStatus: Sendable {
        
        case success
        case noSelected
        case failed
        
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
    
    public enum RejectReason: Sendable {
        
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
        
        private static let reasonSet: [Self] = [
            .notSupportTypeS,
            .notSupportTypeP,
            .transactionNotOpen,
            .notSelected,
        ]
        
        public static func get(reasonByte: UInt8) -> Self {
            for i in Self.reasonSet {
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
    
    
    private let header10BytesData: Data
    public private(set) var secs2Body: SECS2Body?
    
    public var data: Data {
        let r = self.header10BytesData + (self.secs2Body?.data ?? Data())
        let i = r.count
        return Data([
            UInt8((i >> 24) & 0x000000FF),
            UInt8((i >> 16) & 0x000000FF),
            UInt8((i >> 8) & 0x000000FF),
            UInt8(i & 0x000000FF),
        ]) + r
    }
    
    public var stream: UInt8 {
        return self.header10BytesData[2] & 0x7F
    }
    
    public var function: UInt8 {
        return self.header10BytesData[3]
    }
    
    public var wbit: Bool {
        return (self.header10BytesData[2] & 0x80) == 0x80
    }
    
    public var count: Int {
        return self.header10BytesData.count + (self.secs2Body?.data.count ?? 0)
    }
    
    public var header10Bytes: [UInt8] {
        return [UInt8](self.header10BytesData)
    }
    
    public var sessionId: UInt16 {
        return UInt16(self.header10BytesData[0]) << 8 | UInt16(self.header10BytesData[1])
    }
    
    public var system4BytesKeyValue: UInt32 {
        return (UInt32(self.header10BytesData[6]) << 24) | (UInt32(self.header10BytesData[7]) << 16) | (UInt32(self.header10BytesData[8]) << 8) | UInt32(self.header10BytesData[9])
    }
    
    public var isDataMessage: Bool {
        return self.messageType == .data
    }
    
    public var pType: UInt8 {
        return self.header10BytesData[4]
    }
    
    public var sType: UInt8 {
        return self.header10BytesData[5]
    }
    
    public var messageType: MessageType {
        return MessageType.get(pType: self.pType, sType: self.sType)
    }
    
    private static let lineSeparator: String = "\n"
    private static let endMessage = "."
    
    public var header10BytesString: String {
        return String(format: "[%02X %02X|%02X %02X|%02X %02X|%02X %02X %02X %02X]",
                      self.header10BytesData[0],
                      self.header10BytesData[1],
                      self.header10BytesData[2],
                      self.header10BytesData[3],
                      self.header10BytesData[4],
                      self.header10BytesData[5],
                      self.header10BytesData[6],
                      self.header10BytesData[7],
                      self.header10BytesData[8],
                      self.header10BytesData[9])
    }
    
    public var description: String {
        var r = self.header10BytesString + " \(self.messageType.descriptionString) length:\(self.count)"
        if self.isDataMessage {
            r += "\(Self.lineSeparator)S\(self.stream)F\(self.function)"
            if self.wbit {
                r += " W"
            }
            if let secs2BodySmlString = self.secs2Body?.smlString {
                r += Self.lineSeparator + secs2BodySmlString
            }
            r += Self.endMessage
        }
        return r
    }
    
    public var debugDescription: String {
        return self.description;
    }
    
    public init(header10BytesData: Data, secs2BodyData: Data) {
        self.header10BytesData = header10BytesData
        self.secs2Body = SECS2Body(data: secs2BodyData)
    }
    
    public init(sessionId2Bytes: [UInt8], smlMessage: SMLMessage, system4Bytes: [UInt8]) {
        self.header10BytesData = Data([
            sessionId2Bytes[0],
            sessionId2Bytes[1],
            smlMessage.stream | (smlMessage.wbit ? 0x80 : 0x00),
            smlMessage.function,
            MessageType.data.pType,
            MessageType.data.sType,
            system4Bytes[0],
            system4Bytes[1],
            system4Bytes[2],
            system4Bytes[3],
        ])
        self.secs2Body = smlMessage.secs2Body
    }
    
    public init(primaryMessage: SECSMessage, smlMessage: SMLMessage) {
        let ref = primaryMessage.header10Bytes
        self.header10BytesData = Data([
            ref[0],
            ref[1],
            smlMessage.stream | (smlMessage.wbit ? 0x80 : 0x00),
            smlMessage.function,
            ref[4],
            ref[5],
            ref[6],
            ref[7],
            ref[8],
            ref[9],
        ])
        self.secs2Body = nil
    }
    
    public init(sessionId2Bytes: [UInt8], messageType: MessageType, system4Bytes: [UInt8]) {
        self.header10BytesData = Data([
            sessionId2Bytes[0],
            sessionId2Bytes[1],
            0x00,
            0x00,
            messageType.pType,
            messageType.sType,
            system4Bytes[0],
            system4Bytes[1],
            system4Bytes[2],
            system4Bytes[3],
        ])
        self.secs2Body = nil
    }
    
    public init(hsmsSelectRequest: HSMSMessage, selectStatus: SelectStatus) {
        let ref = hsmsSelectRequest.header10Bytes
        self.header10BytesData = Data([
            ref[0],
            ref[1],
            0x00,
            selectStatus.statusByte,
            MessageType.selectResponse.pType,
            MessageType.selectResponse.sType,
            ref[6],
            ref[7],
            ref[8],
            ref[9],
        ])
        self.secs2Body = nil
    }
    
    public init(hsmsDeselectRequest: HSMSMessage, deselectStatus: DeselectStatus) {
        let ref = hsmsDeselectRequest.header10Bytes
        self.header10BytesData = Data([
            ref[0],
            ref[1],
            0x00,
            deselectStatus.statusByte,
            MessageType.deselectResponse.pType,
            MessageType.deselectResponse.sType,
            ref[6],
            ref[7],
            ref[8],
            ref[9],
        ])
        self.secs2Body = nil
    }
    
    public init(hsmsLinktestRequest: HSMSMessage) {
        let ref = hsmsLinktestRequest.header10Bytes
        self.header10BytesData = Data([
            ref[0],
            ref[1],
            0x00,
            0x00,
            MessageType.linktestResponse.pType,
            MessageType.linktestResponse.sType,
            ref[6],
            ref[7],
            ref[8],
            ref[9],
        ])
        self.secs2Body = nil
    }
    
    public init(hsmsRejectRequest: HSMSMessage, rejectReason: RejectReason, byte2: UInt8) {
        let ref = hsmsRejectRequest.header10Bytes
        self.header10BytesData = Data([
            ref[0],
            ref[1],
            byte2,
            rejectReason.reasonByte,
            MessageType.rejectRequest.pType,
            MessageType.rejectRequest.sType,
            ref[6],
            ref[7],
            ref[8],
            ref[9],
        ])
        self.secs2Body = nil
    }
    
    public init(originSECSMessage: SECSMessage) {
        self.header10BytesData = Data(originSECSMessage.header10Bytes)
        self.secs2Body = originSECSMessage.secs2Body
    }
    
}
