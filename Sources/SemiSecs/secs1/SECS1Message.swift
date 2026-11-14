//
//  SECS1Message.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/03/06.
//

import Foundation

/// SECS-I Message
public struct SECS1Message: SECSMessage, Sendable {
    
    /// SECS-I Message Block
    public struct Block : CustomStringConvertible, CustomDebugStringConvertible, Sendable {
        
        private let _data: Data
        
        public init?(data: Data) {
            guard (13...257).contains(data.count) else {
                return nil
            }
            self._data = data
        }
        
        /// Data
        public var data: Data {
            get { self._data }
        }
        
        /// Header-10-bytes. Readonly.
        internal var header10Bytes: Data {
            get { self._data.subdata(in: 1..<11) }
        }
        
        /// Device-ID
        internal var deviceId: UInt16 {
            get { UInt16(bytes: [(self._data[1] & 0x7F), self._data[2]])! }
        }
        
        /// R-Bit, Returns true if R-Bit is 1, otherwise false.
        internal var rbit: Bool {
            get { (self._data[1] & 0x80) == 0x80 }
        }
        
        /// W-Bit, Returns true if R-Bit is 1, otherwise false.
        internal var wbit: Bool {
            get { (self._data[3] & 0x80) == 0x80 }
        }
        
        /// E-Bit, Returns true if R-Bit is 1, otherwise false.
        internal var ebit: Bool {
            get { (self._data[5] & 0x80) == 0x80 }
        }
        
        /// Block-Number
        internal var blockNumber: UInt16 {
            get { UInt16(bytes: [(self._data[5] & 0x7F), self._data[6]])! }
        }
        
        /// System-4-Bytes-32bit-unsigned-Number. Readonly.
        internal var system4BytesKeyValue: UInt32 {
            get { UInt32(bytes: Array(self._data[7...10]))! }
        }
        
        public var description: String {
            get {
                return String(format: "[%02X %02X|%02X %02X|%02X %02X|%02X %02X %02X %02X] length:%d",
                              self._data[1],
                              self._data[2],
                              self._data[3],
                              self._data[4],
                              self._data[5],
                              self._data[6],
                              self._data[7],
                              self._data[8],
                              self._data[9],
                              self._data[10],
                              self._data[0])
            }
        }
        
        public var debugDescription: String {
            get { self.description }
        }
        
        internal var validLength: Bool {
            get { self._data[0] == (self._data.count - 3) }
        }
        
        public var sumCheck: Bool {
            get {
                let suffix = self._data.suffix(2)
                let sum = self._data.dropFirst().dropLast(2).reduce(0) { $0 + UInt16($1) }
                return sum == UInt16(bytes: Array(suffix))
            }
        }
        
        public func isSame(block: Self) -> Bool {
            return block.system4BytesKeyValue == self.system4BytesKeyValue && block.blockNumber == self.blockNumber
        }
        
        public func isNext(block: Self) -> Bool {
            return block.system4BytesKeyValue == self.system4BytesKeyValue && block.blockNumber == (self.blockNumber + 1)
        }
        
    }
    
    private let _secs2Body: (any SECS2BodyProvider)?
    private let _blocks: [Block]
    
    internal init(secs2Body: (any SECS2BodyProvider)?, blocks: [Block]) {
        self._secs2Body = secs2Body
        self._blocks = blocks
    }
    
    public var header10Bytes: Data {
        get { self._blocks.last!.header10Bytes }
    }
    
    public var secs2Body: (any SECS2BodyProvider)? {
        get { self._secs2Body }
    }
    
    /// SECS1Message-Blocks
    public var blocks: [Block] {
        get { self._blocks }
    }
    
    /// Device-ID
    public var deviceId: UInt16 {
        get { self.blocks.last!.deviceId }
    }
    
    /// R-Bit, Returns true if R-Bit is 1, otherwise false.
    public var rbit: Bool {
        get { self.blocks.last!.rbit }
    }
    
    private static let lineSeparator: String = "\n"
    private static let endMessage = "."
    
    internal var header10BytesString: String {
        get {
            String(format: "[%02X %02X|%02X %02X|%02X %02X|%02X %02X %02X %02X]",
                   self.header10Bytes[0],
                   self.header10Bytes[1],
                   self.header10Bytes[2],
                   self.header10Bytes[3],
                   self.header10Bytes[4],
                   self.header10Bytes[5],
                   self.header10Bytes[6],
                   self.header10Bytes[7],
                   self.header10Bytes[8],
                   self.header10Bytes[9])
        }
    }
    
    public var description: String {
        get {
            var r = "\(self.header10BytesString)\(Self.lineSeparator)S\(self.stream)F\(self.function)"
            if self.wbit {
                r += " W"
            }
            if let secs2BodySmlString = self._secs2Body?.smlString {
                r += Self.lineSeparator + secs2BodySmlString
            }
            r += Self.endMessage
            
            return r
        }
    }
    
    public var debugDescription: String {
        return self.description
    }
    
}
