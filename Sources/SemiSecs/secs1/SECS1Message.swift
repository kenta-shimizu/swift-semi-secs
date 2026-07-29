//
//  SECS1Message.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/03/06.
//

import Foundation

public struct SECS1Message: SECSMessage, Sendable {
    
    public struct SECS1MessageBlock : Sendable{
        
        private let _data: Data
        
        public init?(data: Data) {
            guard (13...257).contains(data.count) else {
                return nil
            }
            self._data = data
        }
        
        public var data: Data {
            return self._data
        }
        
        public var header10Bytes: Data {
            return self._data.subdata(in: 1..<11)
        }
        
        public var deviceId: UInt16 {
            return (UInt16(self._data[1] & 0x7F) << 8) | UInt16(self._data[2])
        }
        
        public var ebit: Bool {
            return (self._data[5] & 0x80) == 0x80
        }
        
        public var sumCheck: Bool {
            
            //TODO
            
            return true
        }
        
        public func isSameMessage(block: Self) -> Bool {
            
            //TODO
            return false
        }
        
        public func isNextMessage(block: Self) -> Bool {
            
            //TODO
            return false
        }
        
    }
    
    private let _header10Bytes: Data
    private let _secs2Body: (any SECS2Body)?
    private let _blocks: [SECS1MessageBlock]
    
    internal init(header10Bytes: Data, secs2Body: (any SECS2Body)?, blocks: [SECS1MessageBlock]) {
        self._header10Bytes = header10Bytes
        self._secs2Body = secs2Body
        self._blocks = blocks
    }
    
    public var secs2Body: (any SECS2Body)? {
        return self._secs2Body
    }
    
    public var header10Bytes: Data {
        return self._header10Bytes
    }
    
    public var description: String {
        
        //TODO
        return ""
    }
    
    public var debugDescription: String {
        
        //TODO
        return ""
    }
    
    
}
