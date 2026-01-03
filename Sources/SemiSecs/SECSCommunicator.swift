//
//  SecsCommunicator.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Foundation

public protocol Shutdownable {
    func shutdown()
}

public class ShutdownableBase: Shutdownable {
    
    internal enum ShutdownError: Error {
        case alreadyShutdowned
    }
    
    internal var shutdowned: Bool
    internal var shutdownables: [Shutdownable]
    
    internal init() {
        self.shutdowned = false
        self.shutdownables = []
    }
    
    deinit {
        self.shutdown()
    }
    
    internal func append(shutdownable: Shutdownable) {
        self.shutdownables.append(shutdownable)
    }
    
    public func shutdown() {
        for shutdownable in self.shutdownables {
            shutdownable.shutdown()
        }
        self.shutdownables.removeAll()
        self.shutdowned = true
    }
}

internal final class BlockingQueue<T>: ShutdownableBase {
    
    private let condition = NSCondition()
    private var queue: [T] = []
    
    internal override init() {
        super.init()
    }
    
    internal override func shutdown() {
        self.condition.lock()
        if !self.shutdowned {
            self.queue.removeAll()
            super.shutdown()
            self.condition.broadcast()
        }
        self.condition.unlock()
    }
    
    @discardableResult
    internal func put(_ value: T) throws(ShutdownError) -> Bool {
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        self.queue.append(value)
        self.condition.signal()
        return true
    }
    
    @discardableResult
    internal func take() throws(ShutdownError) -> T {
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if !self.queue.isEmpty {
            return self.queue.removeFirst()
        }
        self.condition.wait()
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        return self.queue.removeFirst()
    }
    
    @discardableResult
    internal func poll() throws(ShutdownError) -> T? {
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if self.queue.isEmpty {
            return nil
        } else {
            return self.queue.removeFirst()
        }
    }
    
    @discardableResult
    internal func poll(timeout: Double) throws(ShutdownError) -> T? {
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if !self.queue.isEmpty {
            return self.queue.removeFirst()
        }
        let signaled = self.condition.wait(until: Date().addingTimeInterval(timeout))
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if signaled {
            return self.queue.removeFirst()
        } else {
            return nil
        }
    }
}

internal class BlockingDataQueue: ShutdownableBase {
    
    private let condition = NSCondition()
    private var data = Data()
    
    internal override init() {
        super.init()
    }
    
    internal override func shutdown() {
        self.condition.lock()
        if !self.shutdowned {
            super.shutdown()
            self.condition.broadcast()
        }
        self.condition.unlock()
    }
    
    internal func put(_ data: Data) throws(ShutdownError) {
        guard !data.isEmpty else {
            return
        }
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        self.data.append(data)
        self.condition.signal()
    }
    
    @discardableResult
    internal func take() throws(ShutdownError) -> UInt8 {
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if !self.data.isEmpty {
            return self.data.removeFirst()
        }
        self.condition.wait()
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        return self.data.removeFirst()
    }
    
    @discardableResult
    internal func take(_ maxLength: Int) throws(ShutdownError) -> Data {
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if !self.data.isEmpty {
            if self.data.count > maxLength {
                let r = self.data.prefix(maxLength)
                self.data.removeFirst(maxLength)
                return r
            } else {
                let r = self.data
                self.data.removeAll()
                return r
            }
        }
        self.condition.wait()
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if self.data.count > maxLength {
            let r = self.data.prefix(maxLength)
            self.data.removeFirst(maxLength)
            return r
        } else {
            let r = self.data
            self.data.removeAll()
            return r
        }
    }
    
    @discardableResult
    internal func poll(timeout: Double) throws(ShutdownError) -> UInt8? {
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if !self.data.isEmpty {
            return self.data.removeFirst()
        }
        let signaled = self.condition.wait(until: Date().addingTimeInterval(timeout))
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if signaled {
            return self.data.removeFirst()
        }
        return nil
    }
    
    @discardableResult
    internal func poll(_ maxLength: Int, timeout: Double) throws(ShutdownError) -> Data? {
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if !self.data.isEmpty {
            if self.data.count > maxLength {
                let r = self.data.prefix(maxLength)
                self.data.removeFirst(maxLength)
                return r
            } else {
                let r = self.data
                self.data.removeAll()
                return r
            }
        }
        let signaled = self.condition.wait(until: Date().addingTimeInterval(timeout))
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if signaled {
            if self.data.count > maxLength {
                let r = self.data.prefix(maxLength)
                self.data.removeFirst(maxLength)
                return r
            } else {
                let r = self.data
                self.data.removeAll()
                return r
            }
        }
        return nil
    }
    
}

internal class BlockingQueueAndNotifier<T>: ShutdownableBase {
    
    fileprivate class Inner {
        
        fileprivate let semaphore = DispatchSemaphore(value: 1)
        fileprivate let queue: BlockingQueue<T> = BlockingQueue()
        fileprivate var observers: [(T) -> Void] = []
        
        fileprivate init() {
        }
        
        fileprivate func startLoop() {
            do {
                while true {
                    let value = try self.queue.take()
                    self.semaphore.wait()
                    for observer in self.observers {
                        observer(value)
                    }
                    self.semaphore.signal()
                }
            }
            catch {
                // Nothing
            }
        }
    }
    
    private let inner = Inner()
    
    internal override init() {
        
        super.init()
        self.append(shutdownable: self.inner.queue)
        
        DispatchQueue.global().async {
            self.inner.startLoop()
        }
    }
    
    internal override func shutdown() {
        self.inner.semaphore.wait()
        if !self.shutdowned {
            self.inner.observers.removeAll()
            super.shutdown()
        }
        self.inner.semaphore.signal()
    }
    
    @discardableResult
    internal func put(_ value: T) throws(ShutdownError) -> Bool {
        return try self.inner.queue.put(value)
    }
    
    internal func append(observer: @escaping (T) -> Void) {
        self.inner.semaphore.wait()
        self.inner.observers.append(observer)
        self.inner.semaphore.signal()
    }
}

internal class StateChangeNotifier<T: Equatable>: ShutdownableBase {
    
    internal let condition = NSCondition()
    private var observers: [(T) -> Void] = []
    internal var state: T
    
    private var boolNoifiers: [BoolChangeNotifier] = []
    
    internal init(_ state: T) {
        self.state = state
        super.init()
    }
    
    internal override func shutdown() {
        self.condition.lock()
        if !self.shutdowned {
            self.observers.removeAll()
            for notifier in self.boolNoifiers {
                notifier.shutdown()
            }
            self.boolNoifiers.removeAll()
            super.shutdown()
        }
        self.condition.unlock()
    }
    
    internal func append(observer: @escaping (T) -> Void) {
        self.condition.lock()
        if !self.shutdowned {
            observer(self.state)
            self.observers.append(observer)
        }
        self.condition.unlock()
    }
    
    internal func set(_ state: T) {
        self.condition.lock()
        if !self.shutdowned {
            if state != self.state {
                self.state = state
                self.condition.broadcast()
                for observer in self.observers {
                    observer(state)
                }
            }
        }
        self.condition.unlock()
    }
    
    @discardableResult
    internal func waitUntil(_ state: T) throws(ShutdownError) -> Bool {
        let boolNotifier = BoolChangeNotifier(false)
        self.boolNoifiers.append(boolNotifier)
        defer {
            boolNotifier.shutdown()
            self.boolNoifiers.removeAll { $0 === boolNotifier }
        }
        do {
            self.condition.lock()
            defer {
                self.condition.unlock()
            }
            guard !self.shutdowned else {
                throw .alreadyShutdowned
            }
            boolNotifier.set(state == self.state)
            self.observers.append { boolNotifier.set($0 == state) }
        }
        return try boolNotifier.waitUntil(true)
    }
    
    @discardableResult
    internal func waitUntilNot(_ state: T) throws(ShutdownError) -> Bool {
        let boolNotifier = BoolChangeNotifier(true)
        self.boolNoifiers.append(boolNotifier)
        defer {
            boolNotifier.shutdown()
            self.boolNoifiers.removeAll { $0 === boolNotifier }
        }
        do {
            self.condition.lock()
            defer {
                self.condition.unlock()
            }
            guard !self.shutdowned else {
                throw .alreadyShutdowned
            }
            boolNotifier.set(state == self.state)
            self.observers.append { boolNotifier.set($0 == state) }
        }
        return try boolNotifier.waitUntilNot(true)
    }
    
    @discardableResult
    internal func waitUntil(_ state: T, timeout: Double) throws(ShutdownError) -> Bool {
        let boolNotifier = BoolChangeNotifier(false)
        self.boolNoifiers.append(boolNotifier)
        defer {
            boolNotifier.shutdown()
            self.boolNoifiers.removeAll { $0 === boolNotifier }
        }
        do {
            self.condition.lock()
            defer {
                self.condition.unlock()
            }
            guard !self.shutdowned else {
                throw .alreadyShutdowned
            }
            boolNotifier.set(state == self.state)
            self.observers.append { boolNotifier.set($0 == state) }
        }
        return try boolNotifier.waitUntil(true, timeout: timeout)
    }
    
    @discardableResult
    internal func waitUntilNot(_ state: T, timeout: Double) throws(ShutdownError) -> Bool {
        let boolNotifier = BoolChangeNotifier(true)
        self.boolNoifiers.append(boolNotifier)
        defer {
            boolNotifier.shutdown()
            self.boolNoifiers.removeAll { $0 === boolNotifier }
        }
        do {
            self.condition.lock()
            defer {
                self.condition.unlock()
            }
            guard !self.shutdowned else {
                throw .alreadyShutdowned
            }
            boolNotifier.set(state == self.state)
            self.observers.append { boolNotifier.set($0 == state) }
        }
        return try boolNotifier.waitUntilNot(true, timeout: timeout)
    }
    
}

internal class BoolChangeNotifier: StateChangeNotifier<Bool> {
    
    internal override init(_ state: Bool) {
        super.init(state)
    }
    
    internal override func shutdown() {
        super.shutdown()
    }
    
    @discardableResult
    internal override func waitUntil(_ state: Bool) throws(ShutdownError) -> Bool{
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if state == self.state {
            return true
        }
        self.condition.wait()
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        return true
    }
    
    @discardableResult
    internal override func waitUntilNot(_ state: Bool) throws(ShutdownError) -> Bool{
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if state != self.state {
            return true
        }
        self.condition.wait()
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        return true
    }
    
    @discardableResult
    internal override func waitUntil(_ state: Bool, timeout: Double) throws(ShutdownError) -> Bool{
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned        }
        if state == self.state {
            return true
        }
        self.condition.wait(until: Date().addingTimeInterval(timeout))
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        return state == self.state
    }

    @discardableResult
    internal override func waitUntilNot(_ state: Bool, timeout: Double) throws(ShutdownError) -> Bool{
        self.condition.lock()
        defer {
            self.condition.unlock()
        }
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        if state != self.state {
            return true
        }
        self.condition.wait(until: Date().addingTimeInterval(timeout))
        guard !self.shutdowned else {
            throw .alreadyShutdowned
        }
        return state != self.state
    }

}

internal class ConcurrentMap<K: Hashable, V> {
    
    private let semaphore = DispatchSemaphore(value: 1)
    private var map: [K: V] = [:]
    
    internal init() {
        /* Nothing */
    }
    
    internal func object(_ value: V, forKey: K) {
        self.semaphore.wait()
        defer {
            self.semaphore.signal()
        }
        self.map[forKey] = value
    }
    
    @discardableResult
    internal func removeValue(forKey: K) -> V? {
        self.semaphore.wait()
        defer {
            self.semaphore.signal()
        }
        return self.map.removeValue(forKey: forKey)
    }
}

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
        
        private var _t1: Double
        private var _t2: Double
        private var _t3: Double
        private var _t4: Double
        private var _t5: Double
        private var _t6: Double
        private var _t7: Double
        private var _t8: Double
        
        public var t1: Double {
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
        public var t2: Double {
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
        public var t3: Double {
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
        public var t4: Double {
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
        public var t5: Double {
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
        public var t6: Double {
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
        public var t7: Double {
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
        public var t8: Double {
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
