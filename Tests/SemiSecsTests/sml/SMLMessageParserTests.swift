//
//  SMLMessageParserTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Testing
import Foundation
import SemiSecs

struct SMLMessageParserTests {
    
    @Suite struct SMLMesageParser {
        
        @Test func testParseSMLMessageNonSECS2Body() async throws {
            
            let string = "S3F1 W."
            
            let result = SMLMessageParser.shared.parseToResult(string)
            
            switch result {
            case .success(let smlMessage):
                #expect(smlMessage.stream == 3)
                #expect(smlMessage.function == 1)
                #expect(smlMessage.wbit == true)
                #expect(smlMessage.secs2Body == nil)
                
            case .failure:
                Issue.record("failed")
            }
            
        }
        
        @Test func testParseSMLMessageExistSECS2Body() async throws {
            
            let string = "S1F2 <L>."
            
            let result = SMLMessageParser.shared.parseToResult(string)
            
            switch result {
            case .success(let smlMessage):
                #expect(smlMessage.stream == 1)
                #expect(smlMessage.function == 2)
                #expect(smlMessage.wbit == false)
                #expect(smlMessage.secs2Body != nil)
                
                if let secs2Body = smlMessage.secs2Body {
                    #expect(secs2Body.type == .list)
                    #expect(secs2Body.count == 0)
                }
                
            case .failure:
                Issue.record("failed")
            }
            
        }
        
        @Test func testParseSMLMessageLiteral() async throws {
            
            let string = """
            S1F2
            <L
            >.
            """
            
            let result = SMLMessageParser.shared.parseToResult(string)
            
            switch result {
            case .success(let smlMessage):
                #expect(smlMessage.stream == 1)
                #expect(smlMessage.function == 2)
                #expect(smlMessage.wbit == false)
                #expect(smlMessage.secs2Body != nil)
                
                if let secs2Body = smlMessage.secs2Body {
                    #expect(secs2Body.type == .list)
                    #expect(secs2Body.count == 0)
                }
                
            case .failure:
                Issue.record("failed")
            }
            
        }
    }
    
    @Suite struct SECS2BodyParser {
        
        @Test func testParseNil() async throws {
            
            let parser = SMLMessageSECS2BodyParser.shared
            
            let r0 = parser.parseToResult("")
            switch r0 {
            case .success(let ss):
                #expect(ss == nil)
            case .failure:
                Issue.record("failed")
            }
            
        }
        
        @Test func testParseList() async throws {
            
            func x0(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .list)
                    #expect(ss?.count == 0)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x0("<L>")
            x0("<L >")  // base
            x0("<L  >")
            x0("< L >")
            x0("<L[0]>")
            x0("<L[0] >")
            x0("<L[0]  >")
            x0("<L [0] >")
            x0("<L[ 0 ] >")
            
            func xx(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .list)
                    #expect(ss?.count == 2)
                    
                    #expect(ss?.secs2BodyValue(at: 0)?.type == .list)
                    #expect(ss?.secs2BodyValue(at: 0)?.count == 0)
                    
                    #expect(ss?.secs2BodyValue(at: 1)?.type == .list)
                    #expect(ss?.secs2BodyValue(at: 1)?.count == 3)

                    #expect(ss?.secs2BodyValue(at: 1, 0)?.type == .list)
                    #expect(ss?.secs2BodyValue(at: 1, 0)?.count == 0)
                    
                    #expect(ss?.secs2BodyValue(at: 1, 1)?.type == .list)
                    #expect(ss?.secs2BodyValue(at: 1, 1)?.count == 0)
                    
                    #expect(ss?.secs2BodyValue(at: 1, 2)?.type == .list)
                    #expect(ss?.secs2BodyValue(at: 1, 2)?.count == 0)
                    
                case .failure:
                    Issue.record("failed")
                }

            }
            
            xx("<L <L[0]><L [3] <L><L [0]><L [0] >>>")

        }
        
        @Test func testParseBinary() async throws {
            
            func x0(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .binary)
                    #expect(ss?.count == 0)
                    #expect(ss?.value as? Data == Data())
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x0("<B>")
            x0("<B >")  // base
            x0("<B  >")
            x0("< B >")
            x0("<B[0]>")
            x0("<B[0] >")
            x0("<B[0]  >")
            x0("<B [0] >")
            x0("<B[ 0 ] >")
            
            func x1(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .binary)
                    #expect(ss?.count == 1)
                    #expect(ss?.value as? Data == Data([0x1]))
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x1("<B 0x1 >")  // base
            x1("<B 0x1>")
            x1("<B 0x01>")
            x1("<B 1>")
            x1("<B 1 >")
            x1("<B[1] 0x1 >")
            x1("<B[1] 0x01 >")
            x1("<B[1] 0x1>")
            x1("<B[1] 0x01>")
            
            func x2(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .binary)
                    #expect(ss?.count == 2)
                    #expect(ss?.value as? Data == Data([2, 10]))
                case .failure:
                    Issue.record("failed")
                }
            }

            x2("<B 0x02 0x0A>")
            x2("<B 0x02 0x0A >")    // base
            x2("<B 2 10>")
            x2("<B 2 10 >")
            x2("<B 0x2 10>")
            x2("<B 2 0xA>")
            
        }
        
        @Test func testParseBoolean() async throws {
            
            func x0(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .boolean)
                    #expect(ss?.count == 0)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x0("<BOOLEAN>")
            x0("<BOOLEAN >")  // base
            x0("<BOOLEAN  >")
            x0("< BOOLEAN >")
            x0("<BOOLEAN[0]>")
            x0("<BOOLEAN[0] >")
            x0("<BOOLEAN[0]  >")
            x0("<BOOLEAN [0] >")
            x0("<BOOLEAN[ 0 ] >")
            
            func x1(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .boolean)
                    #expect(ss?.count == 1)
                    #expect(ss?.boolValue(at: 0) == true)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x1("<BOOLEAN TRUE >")  // base
            x1("<BOOLEAN TRUE>")
            x1("<BOOLEAN[1] TRUE >")
            x1("<BOOLEAN[1] TRUE>")
            
            func x4(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .boolean)
                    #expect(ss?.count == 4)
                    #expect(ss?.boolValue(at: 0) == true)
                    #expect(ss?.boolValue(at: 1) == false)
                    #expect(ss?.boolValue(at: 2) == true)
                    #expect(ss?.boolValue(at: 3) == false)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x4("<BOOLEAN TRUE FALSE T F>")
            x4("<BOOLEAN TRUE FALSE T F >")    // base
            x4("<BOOLEAN true false t f>")
            x4("<BOOLEAN true false t f >")
        }
        
        @Test func testParseAscii() async throws {
            
            func x0(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .ascii)
                    #expect(ss?.count == 0)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x0("<A \"\">")
            x0("<A \"\" >")  // base
            x0("<A \"\"  >")
            x0("< A \"\">")
            x0("<A[0] \"\">")
            x0("<A[0] \"\" >")
            x0("<A[0] \"\"  >")
            x0("<A [0] \"\">")
            x0("<A[ 0 ] \"\">")
            
            func xa(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .ascii)
                    #expect(ss?.count == 3)
                    #expect(ss?.stringValue() == "ABC")
                case .failure:
                    Issue.record("failed")
                }
            }
            
            xa("<A \"ABC\">")
            xa("<A \"ABC\" >")
            xa("<A[3] \"ABC\">")
            xa("<A[3] \"ABC\" >")
            xa("<A \"A\" \"B\" \"C\" >")
            xa("<A 0x41 0x42 0x43>")
            xa("<A \"A\" 0x42 \"C\" >")
            xa("<A 0x41 \"B\" 0x43 >")
            
        }
        
        @Test func testParseInt1() async throws {
            
            func x0(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .int1)
                    #expect(ss?.count == 0)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x0("<I1>")
            x0("<I1 >")  // base
            x0("<I1  >")
            x0("< I1 >")
            x0("<I1[0]>")
            x0("<I1[0] >")
            x0("<I1[0]  >")
            x0("<I1 [0] >")
            x0("<I1[ 0 ] >")
            
            func x1(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .int1)
                    #expect(ss?.count == 1)
                    #expect(ss?.int8Value(at: 0) == 1)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x1("<I1 1>")
            x1("<I1 1 >")   // base
            x1("<I1[1] 1>")
            x1("<I1[1] 1 >")
            
            func x2(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .int1)
                    #expect(ss?.count == 2)
                    #expect(ss?.int8Value(at: 0) == 2)
                    #expect(ss?.int8Value(at: 1) == 3)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x2("<I1 2 3>")
            x2("<I1 2 3 >")  // base
            
        }
        
        @Test func testParseInt2() async throws {
            
            func x0(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .int2)
                    #expect(ss?.count == 0)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x0("<I2>")
            x0("<I2 >")  // base
            x0("<I2  >")
            x0("< I2 >")
            x0("<I2[0]>")
            x0("<I2[0] >")
            x0("<I2[0]  >")
            x0("<I2 [0] >")
            x0("<I2[ 0 ] >")
            
            func x1(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .int2)
                    #expect(ss?.count == 1)
                    #expect(ss?.int16Value(at: 0) == 1)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x1("<I2 1>")
            x1("<I2 1 >")   // base
            x1("<I2[1] 1>")
            x1("<I2[1] 1 >")
            
            func x2(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .int2)
                    #expect(ss?.count == 2)
                    #expect(ss?.int16Value(at: 0) == 2)
                    #expect(ss?.int16Value(at: 1) == 3)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x2("<I2 2 3>")
            x2("<I2 2 3 >")  // base
            
        }
        
        @Test func testParseInt4() async throws {
            
            func x0(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .int4)
                    #expect(ss?.count == 0)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x0("<I4>")
            x0("<I4 >")  // base
            x0("<I4  >")
            x0("< I4 >")
            x0("<I4[0]>")
            x0("<I4[0] >")
            x0("<I4[0]  >")
            x0("<I4 [0] >")
            x0("<I4[ 0 ] >")
            
            func x1(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .int4)
                    #expect(ss?.count == 1)
                    #expect(ss?.int32Value(at: 0) == 1)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x1("<I4 1>")
            x1("<I4 1 >")   // base
            x1("<I4[1] 1>")
            x1("<I4[1] 1 >")
            
            func x2(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .int4)
                    #expect(ss?.count == 2)
                    #expect(ss?.int32Value(at: 0) == 2)
                    #expect(ss?.int32Value(at: 1) == 3)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x2("<I4 2 3>")
            x2("<I4 2 3 >")  // base
            
        }
        
        @Test func testParseInt8() async throws {
            
            func x0(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .int8)
                    #expect(ss?.count == 0)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x0("<I8>")
            x0("<I8 >")  // base
            x0("<I8  >")
            x0("< I8 >")
            x0("<I8[0]>")
            x0("<I8[0] >")
            x0("<I8[0]  >")
            x0("<I8 [0] >")
            x0("<I8[ 0 ] >")
            
            func x1(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .int8)
                    #expect(ss?.count == 1)
                    #expect(ss?.int64Value(at: 0) == 1)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x1("<I8 1>")
            x1("<I8 1 >")   // base
            x1("<I8[1] 1>")
            x1("<I8[1] 1 >")
            
            func x2(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .int8)
                    #expect(ss?.count == 2)
                    #expect(ss?.int64Value(at: 0) == 2)
                    #expect(ss?.int64Value(at: 1) == 3)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x2("<I8 2 3>")
            x2("<I8 2 3 >")  // base
            
        }
        
        @Test func testParseUInt1() async {
            
            func x0(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .uint1)
                    #expect(ss?.count == 0)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x0("<U1>")
            x0("<U1 >")  // base
            x0("<U1  >")
            x0("< U1 >")
            x0("<U1[0]>")
            x0("<U1[0] >")
            x0("<U1[0]  >")
            x0("<U1 [0] >")
            x0("<U1[ 0 ] >")
            
            func x1(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .uint1)
                    #expect(ss?.count == 1)
                    #expect(ss?.uint8Value(at: 0) == 1)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x1("<U1 1>")
            x1("<U1 1 >")   // base
            x1("<U1[1] 1>")
            x1("<U1[1] 1 >")
            
            func x2(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .uint1)
                    #expect(ss?.count == 2)
                    #expect(ss?.uint8Value(at: 0) == 2)
                    #expect(ss?.uint8Value(at: 1) == 3)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x2("<U1 2 3>")
            x2("<U1 2 3 >")  // base
            
        }
        
        @Test func testParseUInt2() async {
            
            func x0(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .uint2)
                    #expect(ss?.count == 0)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x0("<U2>")
            x0("<U2 >")  // base
            x0("<U2  >")
            x0("< U2 >")
            x0("<U2[0]>")
            x0("<U2[0] >")
            x0("<U2[0]  >")
            x0("<U2 [0] >")
            x0("<U2[ 0 ] >")
            
            func x1(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .uint2)
                    #expect(ss?.count == 1)
                    #expect(ss?.uint16Value(at: 0) == 1)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x1("<U2 1>")
            x1("<U2 1 >")   // base
            x1("<U2[1] 1>")
            x1("<U2[1] 1 >")
            
            func x2(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .uint2)
                    #expect(ss?.count == 2)
                    #expect(ss?.uint16Value(at: 0) == 2)
                    #expect(ss?.uint16Value(at: 1) == 3)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x2("<U2 2 3>")
            x2("<U2 2 3 >")  // base
            
        }
        
        @Test func testParseUInt4() async throws {
            
            func x0(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .uint4)
                    #expect(ss?.count == 0)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x0("<U4>")
            x0("<U4 >")  // base
            x0("<U4  >")
            x0("< U4 >")
            x0("<U4[0]>")
            x0("<U4[0] >")
            x0("<U4[0]  >")
            x0("<U4 [0] >")
            x0("<U4[ 0 ] >")
            
            func x1(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .uint4)
                    #expect(ss?.count == 1)
                    #expect(ss?.uint32Value(at: 0) == 1)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x1("<U4 1>")
            x1("<U4 1 >")   // base
            x1("<U4[1] 1>")
            x1("<U4[1] 1 >")
            
            func x2(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .uint4)
                    #expect(ss?.count == 2)
                    #expect(ss?.uint32Value(at: 0) == 2)
                    #expect(ss?.uint32Value(at: 1) == 3)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x2("<U4 2 3>")
            x2("<U4 2 3 >")  // base
            
        }
        
        @Test func testParseUInt8() async throws {
            
            func x0(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .uint8)
                    #expect(ss?.count == 0)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x0("<U8>")
            x0("<U8 >")  // base
            x0("<U8  >")
            x0("< U8 >")
            x0("<U8[0]>")
            x0("<U8[0] >")
            x0("<U8[0]  >")
            x0("<U8 [0] >")
            x0("<U8[ 0 ] >")
            
            func x1(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .uint8)
                    #expect(ss?.count == 1)
                    #expect(ss?.uint64Value(at: 0) == 1)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x1("<U8 1>")
            x1("<U8 1 >")   // base
            x1("<U8[1] 1>")
            x1("<U8[1] 1 >")
            
            func x2(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .uint8)
                    #expect(ss?.count == 2)
                    #expect(ss?.uint64Value(at: 0) == 2)
                    #expect(ss?.uint64Value(at: 1) == 3)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x2("<U8 2 3>")
            x2("<U8 2 3 >")  // base
            
        }
        
        @Test func testParseFloat4() async throws {
            
            func x0(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .float4)
                    #expect(ss?.count == 0)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x0("<F4>")
            x0("<F4 >")  // base
            x0("<F4  >")
            x0("< F4 >")
            x0("<F4[0]>")
            x0("<F4[0] >")
            x0("<F4[0]  >")
            x0("<F4 [0] >")
            x0("<F4[ 0 ] >")
            
            func x1(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .float4)
                    #expect(ss?.count == 1)
                    #expect(ss?.floatValue(at: 0) == 1.0)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x1("<F4 1.0>")
            x1("<F4 1.0 >")   // base
            x1("<F4 1 >")
            x1("<F4 1.00 >")
            x1("<F4[1] 1.0>")
            x1("<F4[1] 1.0 >")
            
            func x2(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .float4)
                    #expect(ss?.count == 2)
                    #expect(ss?.floatValue(at: 0) == 2.0)
                    #expect(ss?.floatValue(at: 1) == 3.0)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x2("<F4 2.0 3.0>")
            x2("<F4 2.0 3.0 >")  // base
            
        }
        
        @Test func testParseFloat8() async throws {
            
            func x0(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .float8)
                    #expect(ss?.count == 0)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x0("<F8>")
            x0("<F8 >")  // base
            x0("<F8  >")
            x0("< F8 >")
            x0("<F8[0]>")
            x0("<F8[0] >")
            x0("<F8[0]  >")
            x0("<F8 [0] >")
            x0("<F8[ 0 ] >")
            
            func x1(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .float8)
                    #expect(ss?.count == 1)
                    #expect(ss?.doubleValue(at: 0) == 1.0)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x1("<F8 1.0>")
            x1("<F8 1.0 >")   // base
            x1("<F8 1 >")
            x1("<F8 1.00 >")
            x1("<F8[1] 1.0>")
            x1("<F8[1] 1.0 >")
            
            func x2(_ string: String) {
                let r = SMLMessageSECS2BodyParser.shared.parseToResult(string)
                switch r {
                case .success(let ss):
                    #expect(ss?.type == .float8)
                    #expect(ss?.count == 2)
                    #expect(ss?.doubleValue(at: 0) == 2.0)
                    #expect(ss?.doubleValue(at: 1) == 3.0)
                case .failure:
                    Issue.record("failed")
                }
            }
            
            x2("<F8 2.0 3.0>")
            x2("<F8 2.0 3.0 >")  // base
            
        }
        
    }
    
    @Suite struct SMLMesageParserError {
        
        @Test func testErrorMissingFinalPeriod() async throws {
            
            let string = "S3F1 W"
            
            let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
            
            guard case .failure(let error) = result else {
                Issue.record("failed")
                return
            }
            
            #expect(error == .missingEndPeriod)
        }
        
        @Test func testErrorNotMatch() async throws {
            
            let string = "T1F1 W <L>."
            
            let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
            
            guard case .failure(let error) = result else {
                Issue.record("failed")
                return
            }
            
            #expect(error == .notMatch)
        }
        
        @Test func testErrorStreamOutOfRange() async throws {
            
            let string = "S128F1 W."
            
            let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
            
            guard case .failure(let error) = result else {
                Issue.record("failed")
                return
            }
            
            #expect(error == .streamOutOfRange)
        }
        
        @Test func testErrorFunctionOutOfRange() async throws {
            
            let string = "S1F256 <L>."
            
            let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
            
            guard case .failure(let error) = result else {
                Issue.record("failed")
                return
            }
            
            #expect(error == .functionOutOfRange)
        }
        
        @Test func testErrorUnknownSECS2ItemType() async throws {
            
            let string = "S1F5 W <C>."
            
            let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
            
            guard case .failure(let error) = result else {
                Issue.record("failed")
                return
            }
            
            #expect(error == .unknownSECS2ItemType(index: string.index(string.startIndex, offsetBy: 7)))
        }
        
        @Test func testErrorEndBracketNotFound() async throws {
            
            let string = "S1F6 W <L<L>."
            
            let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
            
            guard case .failure(let error) = result else {
                Issue.record("failed")
                return
            }
            
            #expect(error == .endBracketNotFound(index: string.index(string.startIndex, offsetBy: 7)))
        }
        
        @Test func testErrorEndDoubleQuoteNotFound() async throws {
            
            func xd(_ string: String) {
                
                let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
                
                guard case .failure(let error) = result else {
                    Issue.record("failed")
                    return
                }
                
                #expect(error == .endDoubleQuoteNotFound(index: string.index(string.startIndex, offsetBy: 7)))
            }
            
            xd("S1F8 W <A \">.")
            xd("S1F8 W <A \"\"\">.")
        }
        
        @Test func testErrorIncorrectBracket() async throws {
            
            let string = "S1F7 W <L>>."
            
            let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
            
            guard case .failure(let error) = result else {
                Issue.record("failed")
                return
            }
            
            #expect(error == .incorrectBracket(index: string.index(string.startIndex, offsetBy: 10)))
        }
        
        @Test func testErrorIllegalSECS2Value() async throws {
            
            // nothing
        }
        
        @Test func testErrorIllegalSECS2BinaryValue() async throws {
            
            func xx(_ string: String) {
                
                let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
                
                guard case .failure(let error) = result else {
                    Issue.record("failed")
                    return
                }
                
                #expect(error == .illegalSECS2BinaryValue(index: string.index(string.startIndex, offsetBy: 7)))
            }
            
            xx("S1F8 W <B 0X>.")
            xx("S1F8 W <B 0xGG>.")
            xx("S1F8 W <B -1>.")
            xx("S1F8 W <B 256>.")
            xx("S1F8 W <B 0 256>.")
            xx("S1F8 W <B \"\">.")
            xx("S1F8 W <B L<>>.")
        }
        
        @Test func testErrorIllegalSECS2BooleanValue() async throws {
            
            func xx(_ string: String) {
                
                let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
                
                guard case .failure(let error) = result else {
                    Issue.record("failed")
                    return
                }
                
                #expect(error == .illegalSECS2BooleanValue(index: string.index(string.startIndex, offsetBy: 7)))
            }
            
            xx("S1F8 W <BOOLEAN A >.")
            xx("S1F8 W <BOOLEAN \"true\" >.")
            xx("S1F8 W <BOOLEAN 0 >.")
            xx("S1F8 W <BOOLEAN 0xFF >.")
            xx("S1F8 W <BOOLEAN L<>>.")
        }
        
        @Test func testErrorIllegalSECS2AsciiValue() async throws {
            
            func xx(_ string: String) {
                
                let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
                
                guard case .failure(let error) = result else {
                    Issue.record("failed")
                    return
                }
                
                #expect(error == .illegalSECS2AsciiValue(index: string.index(string.startIndex, offsetBy: 7)))
            }
            
            xx("S1F8 W <A -1 >.")
            xx("S1F8 W <A 256 >.")
            xx("S1F8 W <A L<>>.")
        }
        
        @Test func testErrorIllegalSECS2Int1Value() async throws {
            
            func xx(_ string: String) {
                
                let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
                
                guard case .failure(let error) = result else {
                    Issue.record("failed")
                    return
                }
                
                #expect(error == .illegalSECS2Int1Value(index: string.index(string.startIndex, offsetBy: 7)))
            }
            
            xx("S1F8 W <I1 -129 >.")
            xx("S1F8 W <I1 128 >.")
            xx("S1F8 W <I1 0.1 >.")
            xx("S1F8 W <I1 0x01 >.")
            xx("S1F8 W <I1 \"\" >.")
            xx("S1F8 W <I1 L<> >.")
        }
        
        @Test func testErrorIllegalSECS2Int2Value() async throws {
            
            func xx(_ string: String) {
                
                let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
                
                guard case .failure(let error) = result else {
                    Issue.record("failed")
                    return
                }
                
                #expect(error == .illegalSECS2Int2Value(index: string.index(string.startIndex, offsetBy: 7)))
            }
            
            xx("S1F8 W <I2 -32769 >.")
            xx("S1F8 W <I2 32768 >.")
            xx("S1F8 W <I2 0.1 >.")
            xx("S1F8 W <I2 0x01 >.")
            xx("S1F8 W <I2 \"1\" >.")
            xx("S1F8 W <I2 L<> >.")
        }
        
        @Test func testErrorIllegalSECS2Int4Value() async throws {
            
            func xx(_ string: String) {
                
                let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
                
                guard case .failure(let error) = result else {
                    Issue.record("failed")
                    return
                }
                
                #expect(error == .illegalSECS2Int4Value(index: string.index(string.startIndex, offsetBy: 7)))
            }
            
            xx("S1F8 W <I4 -2147483649 >.")
            xx("S1F8 W <I4 2147483648 >.")
            xx("S1F8 W <I4 0.1 >.")
            xx("S1F8 W <I4 0x01 >.")
            xx("S1F8 W <I4 \"1\" >.")
            xx("S1F8 W <I4 L<> >.")
        }
        
        @Test func testErrorIllegalSECS2Int8Value() async throws {
            
            func xx(_ string: String) {
                
                let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
                
                guard case .failure(let error) = result else {
                    Issue.record("failed")
                    return
                }
                
                #expect(error == .illegalSECS2Int8Value(index: string.index(string.startIndex, offsetBy: 7)))
            }
            
            xx("S1F8 W <I8 -9223372036854775809 >.")
            xx("S1F8 W <I8 9223372036854775808 >.")
            xx("S1F8 W <I8 0.1 >.")
            xx("S1F8 W <I8 0x01 >.")
            xx("S1F8 W <I8 \"1\" >.")
            xx("S1F8 W <I8 L<> >.")
        }
        
        @Test func testErrorIllegalSECS2UInt1Value() async throws {
            
            func xx(_ string: String) {
                
                let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
                
                guard case .failure(let error) = result else {
                    Issue.record("failed")
                    return
                }
                
                #expect(error == .illegalSECS2UInt1Value(index: string.index(string.startIndex, offsetBy: 7)))
            }
            
            xx("S1F8 W <U1 -1 >.")
            xx("S1F8 W <U1 256 >.")
            xx("S1F8 W <U1 0.1 >.")
            xx("S1F8 W <U1 0x01 >.")
            xx("S1F8 W <U1 \"1\" >.")
            xx("S1F8 W <U1 L<> >.")
        }
        
        @Test func testErrorIllegalSECS2UInt2Value() async throws {
            
            func xx(_ string: String) {
                
                let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
                
                guard case .failure(let error) = result else {
                    Issue.record("failed")
                    return
                }
                
                #expect(error == .illegalSECS2UInt2Value(index: string.index(string.startIndex, offsetBy: 7)))
            }
            
            xx("S1F8 W <U2 -1 >.")
            xx("S1F8 W <U2 65536 >.")
            xx("S1F8 W <U2 0.1 >.")
            xx("S1F8 W <U2 0x01 >.")
            xx("S1F8 W <U2 \"1\" >.")
            xx("S1F8 W <U2 L<> >.")
        }
        
        @Test func testErrorIllegalSECS2UInt4Value() async throws {
            
            func xx(_ string: String) {
                
                let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
                
                guard case .failure(let error) = result else {
                    Issue.record("failed")
                    return
                }
                
                #expect(error == .illegalSECS2UInt4Value(index: string.index(string.startIndex, offsetBy: 7)))
            }
            
            xx("S1F8 W <U4 -1 >.")
            xx("S1F8 W <U4 4294967296 >.")
            xx("S1F8 W <U4 0.1 >.")
            xx("S1F8 W <U4 0x01 >.")
            xx("S1F8 W <U4 \"1\" >.")
            xx("S1F8 W <U4 L<> >.")
        }
        
        @Test func testErrorIllegalSECS2UInt8Value() async throws {
            
            func xx(_ string: String) {
                
                let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
                
                guard case .failure(let error) = result else {
                    Issue.record("failed")
                    return
                }
                
                #expect(error == .illegalSECS2UInt8Value(index: string.index(string.startIndex, offsetBy: 7)))
            }
            
            xx("S1F8 W <U8 -1 >.")
            xx("S1F8 W <U8 18446744073709551616 >.")
            xx("S1F8 W <U8 0.1 >.")
            xx("S1F8 W <U8 0x01 >.")
            xx("S1F8 W <U8 \"1\" >.")
            xx("S1F8 W <U8 L<> >.")
        }
        
        @Test func testErrorIllegalSECS2Float4Value() async throws {
            
            func xx(_ string: String) {
                
                let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
                
                guard case .failure(let error) = result else {
                    Issue.record("failed")
                    return
                }
                
                #expect(error == .illegalSECS2Float4Value(index: string.index(string.startIndex, offsetBy: 7)))
            }
            
            xx("S1F8 W <F4 \"1\" >.")
            xx("S1F8 W <F4 L<> >.")
        }
        
        @Test func testErrorIllegalSECS2Float8Value() async throws {
            
            func xx(_ string: String) {
                
                let result: Result<SMLMessage, SMLMessageParseError> = SMLMessageParser.shared.parseToResult(string)
                
                guard case .failure(let error) = result else {
                    Issue.record("failed")
                    return
                }
                
                #expect(error == .illegalSECS2Float8Value(index: string.index(string.startIndex, offsetBy: 7)))
            }
            
            xx("S1F8 W <F8 \"1\" >.")
            xx("S1F8 W <F8 L<> >.")
        }
        
        @Test func testErrorTooManySECS2Values() async throws {
            
            // giveup
        }
        
    }
    
}
