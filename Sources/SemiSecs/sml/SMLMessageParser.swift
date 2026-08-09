//
//  SMLMessageParser.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/03/07.
//

import Foundation

/// SMLMessageParseError
public enum SMLMessageParseError: Error, Equatable, Sendable {
    
    case missingEndPeriod
    case notMatch
    case streamOutOfRange
    case functionOutOfRange
    case unknownSECS2ItemType(index: String.Index)
    case endBracketNotFound(index: String.Index)
    case endDoubleQuoteNotFound(index: String.Index)
    case incorrectBracket(index: String.Index)
    case illegalSECS2Value(index: String.Index)
    case illegalSECS2BinaryValue(index: String.Index)
    case illegalSECS2BooleanValue(index: String.Index)
    case illegalSECS2AsciiValue(index: String.Index)
    case illegalSECS2Int1Value(index: String.Index)
    case illegalSECS2Int2Value(index: String.Index)
    case illegalSECS2Int4Value(index: String.Index)
    case illegalSECS2Int8Value(index: String.Index)
    case illegalSECS2UInt1Value(index: String.Index)
    case illegalSECS2UInt2Value(index: String.Index)
    case illegalSECS2UInt4Value(index: String.Index)
    case illegalSECS2UInt8Value(index: String.Index)
    case illegalSECS2Float4Value(index: String.Index)
    case illegalSECS2Float8Value(index: String.Index)
    case tooManySECS2Values
    
}

/// SMLMessageParsable
public protocol SMLMessageParsable {
    
    /// Returns SMLMessageSECS2BodyParseer.
    ///
    /// - Returns: SMLMessageSECS2BodyParser
    var secs2BodyParser: SMLMessageSECS2BodyParsable { get }
    
    /// Returns parsed SMLMessage.
    ///
    /// - Parameters:
    ///   - of: SMLMessage string
    /// - Returns: parsed SMLMessage
    /// - Throws: SMLMessageParseError
    @discardableResult
    func parse(_ of: String) throws(SMLMessageParseError) -> SMLMessage
    
    /// Returns SMLMessage parse Result.
    ///
    /// - Parameters:
    ///   - of: SMLMessage string
    /// - Returns: SMLMessage parse Result
    @discardableResult
    func parseToResult(_ of: String) -> Result<SMLMessage, SMLMessageParseError>

}

public extension SMLMessageParsable {
    
    @discardableResult
    func parse(_ of: String) throws(SMLMessageParseError) -> SMLMessage {
        let result = self.parseToResult(of)
        switch result {
        case .success(let smlMessage):
            return smlMessage
        case .failure(let error):
            throw error
        }
    }

    @discardableResult
    func parseToResult(_ of: String) -> Result<SMLMessage, SMLMessageParseError> {
        
        guard of.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix(".") else {
            return Result.failure(.missingEndPeriod)
        }
        
        let string = String(of)
        let pattern = /^\s*[Ss](?<stream>\d+)[Ff](?<function>\d+)\s*(?<wbit>[Ww]?)\s*(?<secs2body>(<[\s\S]+>)?)\s*\.\s*$/
        
        guard let match = string.wholeMatch(of: pattern) else {
            return Result.failure(.notMatch)
        }
        
        guard let stream = UInt8(match.output.stream) else {
            return Result.failure(.streamOutOfRange)
        }
        
        guard stream <= 127 else {
            return Result.failure(.streamOutOfRange)
        }
        
        guard let function = UInt8(match.output.function) else {
            return Result.failure(.functionOutOfRange)
        }
        
        let wbit = !(match.output.wbit.isEmpty)
        
        let secs2Parse = { () -> Result<(any SECS2BodyProvider)?, SMLMessageParseError> in
            let secs2BodyString = match.output.secs2body
            return self.secs2BodyParser.parseToResult(string, startIndex: secs2BodyString.startIndex, endIndex: secs2BodyString.endIndex)
        }
        
        switch (secs2Parse()) {
        case .success(let secs2Body):
            return Result.success(SMLMessage(stream: stream, function: function, wbit: wbit, secs2Body: secs2Body))
        case .failure(let error):
            return Result.failure(error)
        }
    }
}

/// SMLMessageParser
public final class SMLMessageParser: SMLMessageParsable, Sendable {
    
    public static let shared = SMLMessageParser()
    
    public var secs2BodyParser: SMLMessageSECS2BodyParsable {
        get { SMLMessageSECS2BodyParser.shared }
    }
    
    private init() {
        // Nothing
    }

}

/// SMLMessageSECSBodyParsable
public protocol SMLMessageSECS2BodyParsable {
    
    /// Returns SECS2Body parse Result.
    ///
    /// - Parameter string: the String
    /// - Returns: SECS2Body parse Result
    @discardableResult
    func parseToResult<T: StringProtocol>(_ string: T) -> Result<(any SECS2BodyProvider)?, SMLMessageParseError>
    
    /// Returns SECS2Body parse Result.
    ///
    /// - Parameter string: the string
    /// - Parameter startIndex: the startIndex
    /// - Parameter endIndex: the endIndex
    /// - Returns: SECS2Body parse Result
    @discardableResult
    func parseToResult(_ string: String, startIndex: String.Index, endIndex: String.Index) -> Result<(any SECS2BodyProvider)?, SMLMessageParseError>
    
    /// Returns Extend-type SECS2Body parse Result.
    ///
    /// - Parameter string: the string
    /// - Parameter startIndex: the startIndex
    /// - Parameter endIndex: the endIndex
    /// - Returns: SECS2Body parsing Result
    @discardableResult
    func parseExtendType(_ string: String, startIndex: String.Index) -> Result<(secs2Body: (any SECS2BodyProvider), endIndex: String.Index), SMLMessageParseError>?
    
}

public extension SMLMessageSECS2BodyParsable {
    
    @discardableResult
    func parseToResult<T: StringProtocol>(_ string: T) -> Result<(any SECS2BodyProvider)?, SMLMessageParseError> {
        return self.parseToResult(String(string), startIndex: string.startIndex, endIndex: string.endIndex)
    }
    
    @discardableResult
    func parseToResult(_ string: String, startIndex: String.Index, endIndex: String.Index) -> Result<(any SECS2BodyProvider)?, SMLMessageParseError> {
        
        if startIndex == endIndex {
            return Result.success(nil)
        }
        
        let result = self.innerParse(string, startIndex: startIndex)
        switch result {
        case .success(let value):
            guard value.endIndex == endIndex else {
                return Result.failure(.incorrectBracket(index: value.endIndex))
            }
            return Result.success(value.secs2Body)
        case .failure(let error):
            return Result.failure(error)
        }
    }
    
    private func innerParse(_ string: String, startIndex: String.Index) -> Result<(secs2Body: (any SECS2BodyProvider), endIndex: String.Index), SMLMessageParseError> {
        
        if let result = parseList(string, startIndex: startIndex) {
            return result
        }
        
        if let result = parseBinary(string, startIndex: startIndex) {
            return result
        }
        
        if let result = parseBoolean(string, startIndex: startIndex) {
            return result
        }
        
        if let result = parseAscii(string, startIndex: startIndex) {
            return result
        }
        
        if let result = parseInt1(string, startIndex: startIndex) {
            return result
        }
        
        if let result = parseInt2(string, startIndex: startIndex) {
            return result
        }
        
        if let result = parseInt4(string, startIndex: startIndex) {
            return result
        }
        
        if let result = parseInt8(string, startIndex: startIndex) {
            return result
        }
        
        if let result = parseUInt1(string, startIndex: startIndex) {
            return result
        }
        
        if let result = parseUInt2(string, startIndex: startIndex) {
            return result
        }
        
        if let result = parseUInt4(string, startIndex: startIndex) {
            return result
        }
        
        if let result = parseUInt8(string, startIndex: startIndex) {
            return result
        }
        
        if let result = parseFloat4(string, startIndex: startIndex) {
            return result
        }
        
        if let result = parseFloat8(string, startIndex: startIndex) {
            return result
        }
        
        if let result = parseExtendType(string, startIndex: startIndex) {
            return result
        }
        
        return Result.failure(.unknownSECS2ItemType(index: startIndex))
    }
    
    private static func seek(_ string: String, targets: [Character], startIndex: String.Index, andWhitespqce: Bool = false) -> (hit: Character, index: String.Index)? {
        
        var pos = startIndex
        while pos < string.endIndex {
            let c = string[pos]
            for target in targets {
                if target == c {
                    return (hit: c, index: pos)
                }
            }
            if andWhitespqce {
                if c.isWhitespace {
                    return (hit: c, index: pos)
                }
            }
            
            pos = string.index(after: pos)  // increment
        }
        
        return nil
    }
    
    private static func parseToUInt8<T: StringProtocol>(of: T) -> UInt8? {
        if of.uppercased().hasPrefix("0X") {
            return UInt8(of.dropFirst(2), radix: 16)
        } else {
            return UInt8(of)
        }
    }
    
    private func parseList(_ string: String, startIndex: String.Index) -> Result<(secs2Body: any SECS2BodyProvider, endIndex: String.Index), SMLMessageParseError>? {
        
        let prefixPatternList = /^<\s*L(\s*\[\s*\d+\s*\])?/
        
        if let match = string[startIndex...].prefixMatch(of: prefixPatternList) {
            
            var values: [any SECS2BodyProvider] = []
            
            var pos = string.index(after: match.range.lowerBound)
            
            while true {
                if let seekResult = Self.seek(string, targets: ["<", ">"], startIndex: pos) {
                    if seekResult.hit == "<" {
                        let valueResult = innerParse(string, startIndex: seekResult.index)
                        switch valueResult {
                        case .success(let value):
                            values.append(value.secs2Body)
                            pos = value.endIndex
                        case .failure(let error):
                            return Result.failure(error)
                        }
                        
                    } else if seekResult.hit == ">" {
                        pos = string.index(after: seekResult.index)
                        break
                    }
                } else {
                    return Result.failure(.endBracketNotFound(index: startIndex))
                }
            }
            
            guard values.count < 0x01000000 else {
                return Result.failure(.tooManySECS2Values)
            }
            
            let secs2Body = SECS2Body(list: values)
            return Result.success((secs2Body: secs2Body, endIndex: pos))
        }
        
        return nil
    }
    
    private func parseBinary(_ string: String, startIndex: String.Index) -> Result<(secs2Body: any SECS2BodyProvider, endIndex: String.Index), SMLMessageParseError>? {
        
        let prefixPatternBinary = /^<\s*B(\s*\[\s*\d+\s*\])?(\s+(?<values>[^>]*))?>/
        
        if let match = string[startIndex...].prefixMatch(of: prefixPatternBinary) {
            
            var values: [UInt8] = []
            
            if let subValues = match.output.values {
                
                let splitValues = subValues.split(omittingEmptySubsequences: true) { $0.isWhitespace }
                
                for splitValue in splitValues {
                    guard let value = Self.parseToUInt8(of: splitValue) else {
                        return Result.failure(.illegalSECS2BinaryValue(index: startIndex))
                    }
                    values.append(value)
                }
            }
            
            guard values.count < 0x01000000 else {
                return Result.failure(.tooManySECS2Values)
            }
            
            let secs2Body = SECS2Body(binary: Data(values))
            return Result.success((secs2Body: secs2Body, endIndex: match.range.upperBound))
        }
        
        return nil
    }
    
    private func parseBoolean(_ string: String, startIndex: String.Index) -> Result<(secs2Body: any SECS2BodyProvider, endIndex: String.Index), SMLMessageParseError>? {
        
        let prefixPatternBoolean = /^<\s*BOOLEAN(\s*\[\s*\d+\s*\])?(\s+(?<values>[^>]*))?>/
        
        if let match = string[startIndex...].prefixMatch(of: prefixPatternBoolean) {
            
            var values: [Bool] = []
            
            if let subValues = match.output.values {
                
                let splitValues = subValues.split(omittingEmptySubsequences: true) { $0.isWhitespace }
                
                for splitValue in splitValues {
                    
                    switch splitValue.uppercased() {
                    case "TRUE", "T":
                        values.append(true)
                    case "FALSE", "F":
                        values.append(false)
                    default:
                        return Result.failure(.illegalSECS2BooleanValue(index: startIndex))
                    }
                }
            }
            
            guard values.count < 0x01000000 else {
                return Result.failure(.tooManySECS2Values)
            }
            
            let secs2Body = SECS2Body(boolean: values)
            return Result.success((secs2Body: secs2Body, endIndex: match.range.upperBound))
        }
        
        return nil
    }
    
    private func parseAscii(_ string: String, startIndex: String.Index) -> Result<(secs2Body: any SECS2BodyProvider, endIndex: String.Index), SMLMessageParseError>? {
        
        let prefixPatternAscii = /^<\s*A(\s*\[\s*\d+\s*\])?/
        
        if let _ = string[startIndex...].prefixMatch(of: prefixPatternAscii) {
            
            // seek end Bracket(>) index
            func seekEndDoubleQuoteIndex(_ str: String, startIndex: String.Index) -> String.Index? {
                var pos = startIndex
                while pos < str.endIndex {
                    guard let result = Self.seek(str, targets: ["\"", ">"], startIndex: pos) else {
                        // not found end bracket.
                        return nil
                    }
                    
                    pos = str.index(after: result.index)    // increment
                    
                    switch result.hit {
                    case ">":   // hit end ">"
                        return pos
                    case "\"":  // hit start DoubleQuote
                        func seekEndDoubleQuoteIndex(_ str: String, startIndex: String.Index) -> String.Index? {
                            var pos = startIndex
                            while pos < str.endIndex {
                                guard let result = Self.seek(str, targets: ["\"", "\\"], startIndex: pos) else {
                                    // not found end DoubleQuote.
                                    return nil
                                }
                                
                                pos = str.index(after: result.index)
                                switch result.hit {
                                case "\"":  // hit end DoubleQuote.
                                    return pos
                                case "\\":  // hit escape sequence
                                    // skip next character.
                                    pos = str.index(after: pos)
                                default:    // not reached.
                                    return nil
                                }
                            }
                            
                            // not reach. not found end DoubleQuote.
                            return nil
                        }
                        
                        guard let endDoubleQuoteIndex = seekEndDoubleQuoteIndex(str, startIndex: pos) else {
                            return nil
                        }
                        
                        pos = endDoubleQuoteIndex
                        
                    default:    // not reached.
                        return nil
                    }
                }
                
                // not reach. not found end bracket.
                return nil
            }
            
            guard let endIndex = seekEndDoubleQuoteIndex(string, startIndex: startIndex) else {
                return Result.failure(.endDoubleQuoteNotFound(index: startIndex))
            }
            
            let wholePatternAscii = /^<\s*A(\s*\[\s*\d+\s*\])?(\s+(?<values>.*))?>$/
            
            guard let match = string[startIndex..<endIndex].wholeMatch(of: wholePatternAscii) else {
                return Result.failure(.illegalSECS2AsciiValue(index: startIndex))
            }
            
            guard let values = match.output.values else {
                return Result.failure(.illegalSECS2AsciiValue(index: startIndex))
            }
            
            func parseAsciiStringValues(_ string: String, startIndex: String.Index, endIndex: String.Index) -> String? {
                var asciiString = String()
                
                var pos = startIndex
                while pos < endIndex {
                    let c = string[pos]
                    
                    if c.isWhitespace {
                        pos = string.index(after: pos) // increment
                        continue    // skip if Whitespace
                    }
                    
                    switch c {
                    case "\"":  // hit start DoubleQuote
                        
                        func seekDoubleQuoteInnerString(_ string: String, startIndex: String.Index, endIndex: String.Index) -> (asciiString: String, endIndex: String.Index)? {
                            
                            var asciiString = String()
                            
                            var pos = string.index(after: startIndex)   // after start DoubleQuote
                            while pos < endIndex {
                                let c = string[pos]
                                pos = string.index(after: pos)
                                
                                switch c {
                                case "\"":  // hit end DoubleQuote
                                    return (asciiString: asciiString, endIndex: pos)
                                case "\\":  // hit escape sequence
                                    func getEscapedCharacter(_ character: Character) -> Character? {
                                        switch character {
                                        case "t":
                                            return "\t"
                                        case "r":
                                            return "\r"
                                        case "n":
                                            return "\n"
                                        case "\\":
                                            return "\\"
                                        case "\"":
                                            return "\""
                                        default:    // ignore
                                            return nil
                                        }
                                    }
                                    
                                    if let escapedCharacter = getEscapedCharacter(string[pos]) {
                                        asciiString.append(escapedCharacter)
                                    }
                                    
                                    pos = string.index(after: pos)  // increment
                                    
                                default:
                                    guard c.isASCII else {
                                        return nil
                                    }
                                    
                                    asciiString.append(c)
                                }
                            }
                            
                            // not reach. not found end DoubleQuote.
                            return nil
                        }
                        
                        guard let result = seekDoubleQuoteInnerString(string, startIndex: pos, endIndex: endIndex) else {
                            return nil
                        }
                        
                        asciiString.append(result.asciiString)
                        pos = result.endIndex   // set after end DoubleQuote.
                        
                    case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":  // hit number
                        
                        guard let result = Self.seek(string, targets: ["\"", ">"], startIndex: pos) else {
                            return nil
                        }
                        
                        let splitValues = string[pos..<result.index].split(omittingEmptySubsequences: true) { $0.isWhitespace }
                        
                        var asciiUInt8Values: [UInt8] = []
                        for splitValue in splitValues {
                            guard let value = Self.parseToUInt8(of: splitValue) else {
                                return nil
                            }
                            
                            asciiUInt8Values.append(value)
                        }
                        
                        guard let encodedString = String(bytes: asciiUInt8Values, encoding: .ascii) else {
                            return nil
                        }
                        
                        asciiString.append(encodedString)
                        pos = result.index
                        
                    default:
                        // invalid
                        return nil
                    }
                }
                
                return asciiString
            }
            
            guard let asciiString = parseAsciiStringValues(string, startIndex: values.startIndex, endIndex: values.endIndex) else {
                return Result.failure(.illegalSECS2AsciiValue(index: startIndex))
            }
            
            let secs2Body = SECS2Body(ascii: asciiString)
            return Result.success((secs2Body: secs2Body, endIndex: endIndex))
        }
        
        return nil
    }
    
    private func parseInt1(_ string: String, startIndex: String.Index) -> Result<(secs2Body: any SECS2BodyProvider, endIndex: String.Index), SMLMessageParseError>? {
        
        let prefixPatternInt1 = /^<\s*I1(\s*\[\s*\d+\s*\])?(\s+(?<values>[^>]*))?>/

        if let match = string[startIndex...].prefixMatch(of: prefixPatternInt1) {
            
            var values: [Int8] = []
            
            if let subValues = match.output.values {
                
                let splitValues = subValues.split(omittingEmptySubsequences: true) { $0.isWhitespace }
                
                for splitValue in splitValues {
                    guard let value = Int8(splitValue) else {
                        return Result.failure(.illegalSECS2Int1Value(index: startIndex))
                    }
                    
                    values.append(value)
                }
            }
            
            guard values.count < 0x01000000 else {
                return Result.failure(.tooManySECS2Values)
            }
            
            let secs2Body = SECS2Body(int1: values)
            return Result.success((secs2Body: secs2Body, endIndex: match.range.upperBound))
        }
        
        return nil
    }
    
    private func parseInt2(_ string: String, startIndex: String.Index) -> Result<(secs2Body: any SECS2BodyProvider, endIndex: String.Index), SMLMessageParseError>? {
        
        let prefixPatternInt2 = /^<\s*I2(\s*\[\s*\d+\s*\])?(\s+(?<values>[^>]*))?>/
        
        if let match = string[startIndex...].prefixMatch(of: prefixPatternInt2) {
            
            var values: [Int16] = []
            
            if let subValues = match.output.values {
                
                let splitValues = subValues.split(omittingEmptySubsequences: true) { $0.isWhitespace }

                for splitValue in splitValues {
                    guard let value = Int16(splitValue) else {
                        return Result.failure(.illegalSECS2Int2Value(index: startIndex))
                    }
                    
                    values.append(value)
                }
            }
            
            guard values.count < 0x00800000 else {
                return Result.failure(.tooManySECS2Values)
            }
            
            let secs2Body = SECS2Body(int2: values)
            return Result.success((secs2Body: secs2Body, endIndex: match.range.upperBound))
        }
        
        return nil
    }
    
    private func parseInt4(_ string: String, startIndex: String.Index) -> Result<(secs2Body: any SECS2BodyProvider, endIndex: String.Index), SMLMessageParseError>? {
        
        let prefixPatternInt4 = /^<\s*I4(\s*\[\s*\d+\s*\])?(\s+(?<values>[^>]*))?>/
        
        if let match = string[startIndex...].prefixMatch(of: prefixPatternInt4) {
            
            var values: [Int32] = []
            
            if let subValues = match.output.values {
                
                let splitValues = subValues.split(omittingEmptySubsequences: true) { $0.isWhitespace }

                for splitValue in splitValues {
                    guard let value = Int32(splitValue) else {
                        return Result.failure(.illegalSECS2Int4Value(index: startIndex))
                    }
                    
                    values.append(value)
                }
            }
            
            guard values.count < 0x00400000 else {
                return Result.failure(.tooManySECS2Values)
            }
            
            let secs2Body = SECS2Body(int4: values)
            return Result.success((secs2Body: secs2Body, endIndex: match.range.upperBound))
        }
        
        return nil
    }
    
    private func parseInt8(_ string: String, startIndex: String.Index) -> Result<(secs2Body: any SECS2BodyProvider, endIndex: String.Index), SMLMessageParseError>? {
        
        let prefixPatternInt8 = /^<\s*I8(\s*\[\s*\d+\s*\])?(\s+(?<values>[^>]*))?>/
        
        if let match = string[startIndex...].prefixMatch(of: prefixPatternInt8) {
            
            var values: [Int64] = []
            
            if let subValues = match.output.values {
                
                let splitValues = subValues.split(omittingEmptySubsequences: true) { $0.isWhitespace }
                
                for splitValue in splitValues {
                    guard let value = Int64(splitValue) else {
                        return Result.failure(.illegalSECS2Int8Value(index: startIndex))
                    }
                    
                    values.append(value)
                }
            }
            
            guard values.count < 0x00200000 else {
                return Result.failure(.tooManySECS2Values)
            }
            
            let secs2Body = SECS2Body(int8: values)
            return Result.success((secs2Body: secs2Body, endIndex: match.range.upperBound))
        }
        
        return nil
    }
    
    private func parseUInt1(_ string: String, startIndex: String.Index) -> Result<(secs2Body: any SECS2BodyProvider, endIndex: String.Index), SMLMessageParseError>? {
        
        let prefixPatternUInt1 = /^<\s*U1(\s*\[\s*\d+\s*\])?(\s+(?<values>[^>]*))?>/
        
        if let match = string[startIndex...].prefixMatch(of: prefixPatternUInt1) {
            
            var values: [UInt8] = []
            
            if let subValues = match.output.values {
                
                let splitValues = subValues.split(omittingEmptySubsequences: true) { $0.isWhitespace }

                for splitValue in splitValues {
                    guard let value = UInt8(splitValue) else {
                        return Result.failure(.illegalSECS2UInt1Value(index: startIndex))
                    }
                    
                    values.append(value)
                }
            }
            
            guard values.count < 0x01000000 else {
                return Result.failure(.tooManySECS2Values)
            }
            
            let secs2Body = SECS2Body(uint1: values)
            return Result.success((secs2Body: secs2Body, endIndex: match.range.upperBound))
        }
        
        return nil
    }
    
    private func parseUInt2(_ string: String, startIndex: String.Index) -> Result<(secs2Body: any SECS2BodyProvider, endIndex: String.Index), SMLMessageParseError>? {
        
        let prefixPatternUInt2 = /^<\s*U2(\s*\[\s*\d+\s*\])?(\s+(?<values>[^>]*))?>/
        
        if let match = string[startIndex...].prefixMatch(of: prefixPatternUInt2) {
            
            var values: [UInt16] = []
            
            if let subValues = match.output.values {
                
                let splitValues = subValues.split(omittingEmptySubsequences: true) { $0.isWhitespace }
                
                for splitValue in splitValues {
                    guard let value = UInt16(splitValue) else {
                        return Result.failure(.illegalSECS2UInt2Value(index: startIndex))
                    }
                    
                    values.append(value)
                }
            }
            
            guard values.count < 0x00800000 else {
                return Result.failure(.tooManySECS2Values)
            }
            
            let secs2Body = SECS2Body(uint2: values)
            return Result.success((secs2Body: secs2Body, endIndex: match.range.upperBound))
        }
        
        return nil
    }
    
    private func parseUInt4(_ string: String, startIndex: String.Index) -> Result<(secs2Body: any SECS2BodyProvider, endIndex: String.Index), SMLMessageParseError>? {
        
        let prefixPatternUInt4 = /^<\s*U4(\s*\[\s*\d+\s*\])?(\s+(?<values>[^>]*))?>/
        
        if let match = string[startIndex...].prefixMatch(of: prefixPatternUInt4) {
            
            var values: [UInt32] = []
            
            if let subValues = match.output.values {
                
                let splitValues = subValues.split(omittingEmptySubsequences: true) { $0.isWhitespace }

                for splitValue in splitValues {
                    guard let value = UInt32(splitValue) else {
                        return Result.failure(.illegalSECS2UInt4Value(index: startIndex))
                    }
                    
                    values.append(value)
                }
            }
            
            guard values.count < 0x00400000 else {
                return Result.failure(.tooManySECS2Values)
            }
            
            let secs2Body = SECS2Body(uint4: values)
            return Result.success((secs2Body: secs2Body, endIndex: match.range.upperBound))
        }
        
        return nil
    }
    
    private func parseUInt8(_ string: String, startIndex: String.Index) -> Result<(secs2Body: any SECS2BodyProvider, endIndex: String.Index), SMLMessageParseError>? {
        
        let prefixPatternUInt8 = /^<\s*U8(\s*\[\s*\d+\s*\])?(\s+(?<values>[^>]*))?>/
        
        if let match = string[startIndex...].prefixMatch(of: prefixPatternUInt8) {
            
            var values: [UInt64] = []
            
            if let subValues = match.output.values {
                
                let splitValues = subValues.split(omittingEmptySubsequences: true) { $0.isWhitespace }
                
                for splitValue in splitValues {
                    guard let value = UInt64(splitValue) else {
                        return Result.failure(.illegalSECS2UInt8Value(index: startIndex))
                    }
                    
                    values.append(value)
                }
            }
            
            guard values.count < 0x00200000 else {
                return Result.failure(.tooManySECS2Values)
            }
            
            let secs2Body = SECS2Body(uint8: values)
            return Result.success((secs2Body: secs2Body, endIndex: match.range.upperBound))
        }
        
        return nil
    }
    
    private func parseFloat4(_ string: String, startIndex: String.Index) -> Result<(secs2Body: any SECS2BodyProvider, endIndex: String.Index), SMLMessageParseError>? {
        
        let prefixPatternFloat4 = /^<\s*F4(\s*\[\s*\d+\s*\])?(\s+(?<values>[^>]*))?>/
        
        if let match = string[startIndex...].prefixMatch(of: prefixPatternFloat4) {
            
            var values: [Float] = []
            
            if let subValues = match.output.values {
                
                let splitValues = subValues.split(omittingEmptySubsequences: true) { $0.isWhitespace }
                
                for splitValue in splitValues {
                    guard let value = Float(splitValue) else {
                        return Result.failure(.illegalSECS2Float4Value(index: startIndex))
                    }
                    
                    values.append(value)
                }
            }
            
            guard values.count < 0x00400000 else {
                return Result.failure(.tooManySECS2Values)
            }
            
            let secs2Body = SECS2Body(float4: values)
            return Result.success((secs2Body: secs2Body, endIndex: match.range.upperBound))
        }
        
        return nil
    }
    
    private func parseFloat8(_ string: String, startIndex: String.Index) -> Result<(secs2Body: any SECS2BodyProvider, endIndex: String.Index), SMLMessageParseError>? {
        
        let prefixPatternFloat8 = /^<\s*F8(\s*\[\s*\d+\s*\])?(\s+(?<values>[^>]*))?>/
        
        if let match = string[startIndex...].prefixMatch(of: prefixPatternFloat8) {
            
            var values: [Double] = []
            
            if let subValues = match.output.values {
                
                let splitValues = subValues.split(omittingEmptySubsequences: true) { $0.isWhitespace }

                for splitValue in splitValues {
                    guard let value = Double(splitValue) else {
                        return Result.failure(.illegalSECS2Float8Value(index: startIndex))
                    }
                    
                    values.append(value)
                }
            }
            
            guard values.count < 0x00200000 else {
                return Result.failure(.tooManySECS2Values)
            }
            
            let secs2Body = SECS2Body(float8: values)
            return Result.success((secs2Body: secs2Body, endIndex: match.range.upperBound))
        }
        
        return nil
    }
    
    @discardableResult
    func parseExtendType(_ string: String, startIndex: String.Index) -> Result<(secs2Body: any SECS2BodyProvider, endIndex: String.Index), SMLMessageParseError>? {
        
        // Nothing. override if extend type support.
        return nil
    }
    
}

/// SMLMessageSECS2BodyParser
public final class SMLMessageSECS2BodyParser: SMLMessageSECS2BodyParsable, Sendable {
    
    public static let shared = SMLMessageSECS2BodyParser()
    
    private init() {
        // Nothing
    }
    
}
