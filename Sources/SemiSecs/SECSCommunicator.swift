//
//  SecsCommunicator.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Foundation

public protocol SECSError: Error, CustomStringConvertible, CustomDebugStringConvertible {
}

public class SECSCommunicator<T: SECSMessage>: ShutdownableBase {
    
    internal class SECSMessageBuilder {
        
        private let semaphore = DispatchSemaphore(value: 1)
        private var autoNumber: UInt16
        
        internal init() {
            self.autoNumber = 0
        }
        
        internal var incrementAndGetSystemLower2Bytes: [UInt8] {
            self.semaphore.wait()
            defer {
                self.semaphore.signal()
            }
            self.autoNumber = self.autoNumber &+ 1
            return [
                UInt8((self.autoNumber >> 8) & 0x00FF),
                UInt8(self.autoNumber & 0x00FF)
            ]
        }
        
    }
    
    internal class SECSMessageTransaction {
        
        internal enum TransactionPutResult {
            case existReplyMeessage
            case primaryMessage
        }
        
        private let receiveMap = ConcurrentMap<UInt32, BlockingQueue<T>>()
        
        internal init() {
            // Nothing
        }
        
        internal func put(receiveMessage: T) throws -> TransactionPutResult {
            let key = receiveMessage.system4BytesKeyValue
            if let queue = self.receiveMap.removeValue(forKey: key) {
                let result = try queue.put(receiveMessage)
                if result {
                    return .existReplyMeessage
                }
            }
            return .primaryMessage
        }
        
        internal func isWaitReply(message: T) -> Bool {
            return message.wbit
        }
        
        internal func operateSend(message: T) throws {
            fatalError("must override")
        }
        
        internal func operateWaitSendCompleted(message: T) throws {
            fatalError("must override")
        }
        
        internal func operateReceive(primaryMessage: T, receiveQueue: BlockingQueue<T>) throws -> T? {
            fatalError("must override")
        }
        
        @discardableResult
        internal func send(message: T) throws -> T? {
            
            if self.isWaitReply(message: message) {
                
                let key = message.system4BytesKeyValue
                let receiveQueue = BlockingQueue<T>()
                defer {
                    receiveQueue.shutdown()
                    self.receiveMap.removeValue(forKey: key)
                }
                
                self.receiveMap.object(receiveQueue, forKey: key)
                
                try self.operateSend(message: message)
                try self.operateWaitSendCompleted(message: message)
                
                return try self.operateReceive(primaryMessage: message, receiveQueue: receiveQueue)
                
            } else {
                
                try self.operateSend(message: message)
                try self.operateWaitSendCompleted(message: message)
                
                return nil
            }
        }
    }
    
    public struct SECSCommunicatorTimeoutConfig {
        
        private var _t1: TimeInterval
        private var _t2: TimeInterval
        private var _t3: TimeInterval
        private var _t4: TimeInterval
        private var _t5: TimeInterval
        private var _t6: TimeInterval
        private var _t7: TimeInterval
        private var _t8: TimeInterval
        
        public var t1: TimeInterval {
            get {
                return self._t1
            }
            set {
                guard newValue > 0.0 else {
                    fatalError("t1 set value >0.0")
                }
                self._t1 = newValue
            }
        }
        
        public var t2: TimeInterval {
            get {
                return self._t2
            }
            set {
                guard newValue > 0.0 else {
                    fatalError("t2 set value >0.0")
                }
                self._t2 = newValue
            }
        }
        
        public var t3: TimeInterval {
            get {
                return self._t3
            }
            set {
                guard newValue > 0.0 else {
                    fatalError("t3 set value >0.0")
                }
                self._t3 = newValue
            }
        }
        
        public var t4: TimeInterval {
            get {
                return self._t4
            }
            set {
                guard newValue > 0.0 else {
                    fatalError("t4 set value >0.0")
                }
                self._t4 = newValue
            }
        }
        
        public var t5: TimeInterval {
            get {
                return self._t5
            }
            set {
                guard newValue > 0.0 else {
                    fatalError("t5 set value >0.0")
                }
                self._t5 = newValue
            }
        }
        
        public var t6: TimeInterval {
            get {
                return self._t6
            }
            set {
                guard newValue > 0.0 else {
                    fatalError("t6 set value >0.0")
                }
                self._t6 = newValue
            }
        }
        
        public var t7: TimeInterval {
            get {
                return self._t7
            }
            set {
                guard newValue > 0.0 else {
                    fatalError("t7 set value >0.0")
                }
                self._t7 = newValue
            }
        }
        
        public var t8: TimeInterval {
            get {
                return self._t8
            }
            set {
                guard newValue > 0.0 else {
                    fatalError("t8 set value >0.0")
                }
                self._t8 = newValue
            }
        }
        
        internal init() {
            self._t1 = 1.0
            self._t2 = 15.0
            self._t3 = 45.0
            self._t4 = 45.0
            self._t5 = 10.0
            self._t6 = 5.0
            self._t7 = 10.0
            self._t8 = 6.0
        }
    }
    
    public struct SECSDebugLog: CustomDebugStringConvertible {
        
        public enum SECSDebugLogType: String {
            case receiveHSMSMessage = "Receive HSMS-Message"
            case willSendHSMSMessage = "Will send HSMS-Message"
            case didSendHSMSMessage = "Did send HSMS-Message"
            case didChangeHSMSConnectionState = "Did change HSMS-Connection-State"
            case errorHSMSSendTransactionShutdown = "Send HSMS-Transaction Shutdown Error"
            case errorHSMSReceiveTransactionShutdown = "Receive HSMS-Transaction Shutdown Error"
            case errorSendHSMSMessageFailed = "Send HSMS-Message Failed"
            case startHSMSNWConnection = "HSMS-NWConnection start"
            case errorHSMSTimeoutT3 = "HSMS-T3-Timeout Error"
            case errorHSMSTimeoutT6 = "HSMS-T6-Timeout Error"
            case errorHSMSTimeoutT7 = "HSMS-T7-Timeout Error"
            case errorHSMSTimeoutT8 = "HSMS-T8-Timeout Error"
        }
        
        public let timestamp: Date
        public let label: String?
        public let type: SECSDebugLogType
        public let value: CustomDebugStringConvertible?
        
        fileprivate init(label: String?, type: SECSDebugLogType, value: CustomDebugStringConvertible?) {
            self.timestamp = Date()
            self.label = label
            self.type = type
            self.value = value
        }
        
        public var debugDescription: String {
            let timestampFormatter = DateFormatter()
            timestampFormatter.locale = Locale.current
            timestampFormatter.timeZone = TimeZone.current
            timestampFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            
            let timestamp = timestampFormatter.string(from: self.timestamp)
            let label = self.label != nil ? (self.label! + ": ") : ""
            var r = "\(timestamp) \(label)\(self.type.rawValue)"
            if let v = self.value {
                if let str = v as? String {
                    r.append("\n")
                    r.append(str)
                } else {
                    r.append("\n\(v.debugDescription)")
                }
            }
            return r
        }
    }
    
    fileprivate class DebugLogger: ShutdownableBase, @unchecked Sendable {
        
        private let logQueue = BlockingQueue<SECSDebugLog>()
        fileprivate var textOutputStream: TextOutputStream?
        
        fileprivate override init() {
            self.textOutputStream = nil
            super.init()
            self.append(shutdownable: logQueue)
        }
        
        fileprivate func put(_ log: SECSDebugLog) throws(ShutdownError) {
            try self.logQueue.put(log)
        }
        
        fileprivate func startLoop() {
            do {
                while true {
                    let log = try self.logQueue.take()
                    self.textOutputStream?.write(log.debugDescription)
                }
            }
            catch {
                // Nothing
            }
        }
    }
    
    private let debugLogger = DebugLogger()
    public var label: String?
    public var debugOutputStream: TextOutputStream? {
        get {
            return self.debugLogger.textOutputStream
        }
        set {
            self.debugLogger.textOutputStream = newValue
        }
    }
    
    internal init(label: String?) {
        self.label = label
        super.init()
        
        self.append(shutdownable: self.debugLogger)
        
        DispatchQueue.global().async {
            self.debugLogger.startLoop()
        }
    }
    
    internal func putDebugLog(type: SECSDebugLog.SECSDebugLogType, value: CustomDebugStringConvertible? = nil) {
        do {
            try self.debugLogger.put(SECSDebugLog(label: self.label, type: type, value: value))
        }
        catch {
            // Nothing
        }
    }
    
}
