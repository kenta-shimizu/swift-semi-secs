//
//  SECS2BodyDecoderTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/03/08.
//

import Testing
import Foundation
@testable import SemiSecs

struct SECS2BodyDecoderTests {
    
    @Test func testDecodeEmpty() async throws {
        
        let data = Data([])
        let nn = SECS2BodyDecoder.shared.decode(data)

        #expect(nn == nil)
    }
    
    @Test func testDecodeList() async throws {
        
        // lengthByte-1
        let data1 = Data([0x01, 0x00])
        let l1 = SECS2BodyDecoder.shared.decode(data1)
        
        #expect(l1?.type == .list)
        #expect(l1?.count == 0)
        #expect(l1?.data == data1)
        
        // lengthByte-2
        let data2 = Data([0x02, 0x00, 0x00])
        let l2 = SECS2BodyDecoder.shared.decode(data2)
        
        #expect(l2?.type == .list)
        #expect(l2?.count == 0)
        #expect(l2?.data == data2)
        
        // lengthByte-2
        let data3 = Data([0x03, 0x00, 0x00, 0x00])
        let l3 = SECS2BodyDecoder.shared.decode(data3)
        
        #expect(l3?.type == .list)
        #expect(l3?.count == 0)
        #expect(l3?.data == data3)
        
        // list1-2-3
        let data123 = Data([0x01, 0x01, 0x02, 0x00, 0x01, 0x03, 0x00, 0x00, 0x00])
        let l123 = SECS2BodyDecoder.shared.decode(data123)
        
        #expect(l123?.type == .list)
        #expect(l123?.count == 1)
        #expect(l123?.data == data123)
        
        #expect(l123?.getSECS2Body(0)?.type == .list)
        #expect(l123?.getSECS2Body(0)?.count == 1)
        #expect(l123?.getSECS2Body(0)?.data == Data([0x02, 0x00, 0x01, 0x03, 0x00, 0x00, 0x00]))
        
        #expect(l123?.getSECS2Body(0, 0)?.type == .list)
        #expect(l123?.getSECS2Body(0, 0)?.count == 0)
        #expect(l123?.getSECS2Body(0, 0)?.data == Data([0x03, 0x00, 0x00, 0x00]))

    }
    
    @Test func testDecodeBinary() async throws {
        
        // lengthByte-1
        let data1 = Data([0x21, 0x00])
        let b1 = SECS2BodyDecoder.shared.decode(data1)
        
        #expect(b1?.type == .binary)
        #expect(b1?.count == 0)
        #expect(b1?.data == data1)
        
        // lengthByte-2
        let data2 = Data([0x22, 0x00, 0x01, 0x11])
        let b2 = SECS2BodyDecoder.shared.decode(data2)
        
        #expect(b2?.type == .binary)
        #expect(b2?.count == 1)
        #expect(b2?.getUInt8(0) == 0x11)
        #expect(b2?.data == data2)
        
        // lengthByte-3
        let data3 = Data([0x23, 0x00, 0x00, 0x02, 0x21, 0x22])
        let b3 = SECS2BodyDecoder.shared.decode(data3)
        
        #expect(b3?.type == .binary)
        #expect(b3?.count == 2)
        #expect(b3?.getUInt8(0) == 0x21)
        #expect(b3?.getUInt8(1) == 0x22)
        #expect(b3?.data == data3)
        
        // list 1-2-3
        let data123 = Data([0x01, 0x03]) + data1 + data2 + data3
        let b123 = SECS2BodyDecoder.shared.decode(data123)
        
        #expect(b123?.getSECS2Body(0)?.type == .binary)
        #expect(b123?.getSECS2Body(0)?.count == 0)
        #expect(b123?.getSECS2Body(0)?.data == data1)
        
        #expect(b123?.getSECS2Body(1)?.type == .binary)
        #expect(b123?.getSECS2Body(1)?.count == 1)
        #expect(b123?.getUInt8(1, 0) == 0x11)
        #expect(b123?.getSECS2Body(1)?.data == data2)
        
        #expect(b123?.getSECS2Body(2)?.type == .binary)
        #expect(b123?.getSECS2Body(2)?.count == 2)
        #expect(b123?.getUInt8(2, 0) == 0x21)
        #expect(b123?.getUInt8(2, 1) == 0x22)
        #expect(b123?.getSECS2Body(2)?.data == data3)
        
    }
    
    @Test func testDecodeBoolean() async throws {
        
        // lengthByte-1
        let data1 = Data([0x25, 0x00])
        let b1 = SECS2BodyDecoder.shared.decode(data1)
        
        #expect(b1?.type == .boolean)
        #expect(b1?.count == 0)
        #expect(b1?.data == data1)
        
        // lengthByte-2
        let data2 = Data([0x26, 0x00, 0x01, 0xFF])
        let b2 = SECS2BodyDecoder.shared.decode(data2)
        
        #expect(b2?.type == .boolean)
        #expect(b2?.count == 1)
        #expect(b2?.getBool(0) == true)
        #expect(b2?.data == data2)
        
        // lengthByte-3
        let data3 = Data([0x27, 0x00, 0x00, 0x02, 0x00, 0x01])
        let b3 = SECS2BodyDecoder.shared.decode(data3)
        
        #expect(b3?.type == .boolean)
        #expect(b3?.count == 2)
        #expect(b3?.getBool(0) == false)
        #expect(b3?.getBool(1) == true)
        #expect(b3?.data == data3)
        
        // list 1-2-3
        let data123 = Data([0x01, 0x03]) + data1 + data2 + data3
        let b123 = SECS2BodyDecoder.shared.decode(data123)
        
        #expect(b123?.getSECS2Body(0)?.type == .boolean)
        #expect(b123?.getSECS2Body(0)?.count == 0)
        #expect(b123?.getSECS2Body(0)?.data == data1)
        
        #expect(b123?.getSECS2Body(1)?.type == .boolean)
        #expect(b123?.getSECS2Body(1)?.count == 1)
        #expect(b123?.getBool(1, 0) == true)
        #expect(b123?.getSECS2Body(1)?.data == data2)
        
        #expect(b123?.getSECS2Body(2)?.type == .boolean)
        #expect(b123?.getSECS2Body(2)?.count == 2)
        #expect(b123?.getBool(2, 0) == false)
        #expect(b123?.getBool(2, 1) == true)
        #expect(b123?.getSECS2Body(2)?.data == data3)
        
    }
    
    @Test func testDecodeAscii() async throws {
        
        // lengthByte-1
        let data1 = Data([0x41, 0x00])
        let a1 = SECS2BodyDecoder.shared.decode(data1)
        
        #expect(a1?.type == .ascii)
        #expect(a1?.count == 0)
        #expect(a1?.data == data1)
        
        // lengthByte-2
        let data2 = Data([0x42, 0x00, 0x01, 0x41])
        let a2 = SECS2BodyDecoder.shared.decode(data2)
        
        #expect(a2?.type == .ascii)
        #expect(a2?.count == 1)
        #expect(a2?.getString() == "A")
        #expect(a2?.data == data2)
        
        // lengthByte-3
        let data3 = Data([0x43, 0x00, 0x00, 0x03, 0x41, 0x42, 0x43])
        let a3 = SECS2BodyDecoder.shared.decode(data3)
        
        #expect(a3?.type == .ascii)
        #expect(a3?.count == 3)
        #expect(a3?.getString() == "ABC")
        #expect(a3?.data == data3)
        
        // list 1-2-3
        let data123 = Data([0x01, 0x03]) + data1 + data2 + data3
        let a123 = SECS2BodyDecoder.shared.decode(data123)
        
        #expect(a123?.getSECS2Body(0)?.type == .ascii)
        #expect(a123?.getSECS2Body(0)?.count == 0)
        #expect(a123?.getString(0) == "")
        #expect(a123?.getSECS2Body(0)?.data == data1)
        
        #expect(a123?.getSECS2Body(1)?.type == .ascii)
        #expect(a123?.getSECS2Body(1)?.count == 1)
        #expect(a123?.getString(1) == "A")
        #expect(a123?.getSECS2Body(1)?.data == data2)
        
        #expect(a123?.getSECS2Body(2)?.type == .ascii)
        #expect(a123?.getSECS2Body(2)?.count == 3)
        #expect(a123?.getString(2) == "ABC")
        #expect(a123?.getSECS2Body(2)?.data == data3)
        
    }
    
    @Test func testDecodeJIS8() async throws {
        
        // lengthByte-1
        let data1 = Data([0x45, 0x00])
        let j1 = SECS2BodyDecoder.shared.decode(data1)
        
        #expect(j1?.type == .jis8)
        #expect(j1?.data == data1)
        
        // lengthByte-2
        let data2 = Data([0x46, 0x00, 0x00])
        let j2 = SECS2BodyDecoder.shared.decode(data2)
        
        #expect(j2?.type == .jis8)
        #expect(j2?.data == data2)
        
        // lengthByte-3
        let data3 = Data([0x47, 0x00, 0x00, 0x00])
        let j3 = SECS2BodyDecoder.shared.decode(data3)
        
        #expect(j3?.type == .jis8)
        #expect(j3?.data == data3)
        
    }
    
    @Test func testDecodeCharacter2Bytes() async throws {
        
        // lengthByte-1
        let data1 = Data([0x49, 0x00])
        let c1 = SECS2BodyDecoder.shared.decode(data1)
        
        #expect(c1?.type == .character2bytes)
        #expect(c1?.data == data1)
        
        // lengthByte-2
        let data2 = Data([0x4A, 0x00, 0x00])
        let c2 = SECS2BodyDecoder.shared.decode(data2)
        
        #expect(c2?.type == .character2bytes)
        #expect(c2?.data == data2)
        
        // lengthByte-3
        let data3 = Data([0x4B, 0x00, 0x00, 0x00])
        let c3 = SECS2BodyDecoder.shared.decode(data3)
        
        #expect(c3?.type == .character2bytes)
        #expect(c3?.data == data3)
        
    }
    
    @Test func testDecodeInt1() async throws {
        
        // lengthByte-1
        let data1 = Data([0x65, 0x00])
        let n1 = SECS2BodyDecoder.shared.decode(data1)
        
        #expect(n1?.type == .int1)
        #expect(n1?.count == 0)
        #expect(n1?.data == data1)
        
        // lengthByte-2
        let data2 = Data([0x66, 0x00, 0x01, 0x01])
        let n2 = SECS2BodyDecoder.shared.decode(data2)
        
        #expect(n2?.type == .int1)
        #expect(n2?.count == 1)
        #expect(n2?.getInt8(0) == 0x01)
        #expect(n2?.data == data2)
        
        // lengthByte-3
        let data3 = Data([0x67, 0x00, 0x00, 0x02, 0x02, 0x03])
        let n3 = SECS2BodyDecoder.shared.decode(data3)
        
        #expect(n3?.type == .int1)
        #expect(n3?.count == 2)
        #expect(n3?.getInt8(0) == 0x02)
        #expect(n3?.getInt8(1) == 0x03)
        #expect(n3?.data == data3)
        
        // list 1-2-3
        let data123 = Data([0x01, 0x03]) + data1 + data2 + data3
        let n123 = SECS2BodyDecoder.shared.decode(data123)
        
        #expect(n123?.getSECS2Body(0)?.type == .int1)
        #expect(n123?.getSECS2Body(0)?.count == 0)
        #expect(n123?.getSECS2Body(0)?.data == data1)
        
        #expect(n123?.getSECS2Body(1)?.type == .int1)
        #expect(n123?.getSECS2Body(1)?.count == 1)
        #expect(n123?.getInt8(1, 0) == 0x01)
        #expect(n123?.getSECS2Body(1)?.data == data2)
        
        #expect(n123?.getSECS2Body(2)?.type == .int1)
        #expect(n123?.getSECS2Body(2)?.count == 2)
        #expect(n123?.getInt8(2, 0) == 0x02)
        #expect(n123?.getInt8(2, 1) == 0x03)
        #expect(n123?.getSECS2Body(2)?.data == data3)
        
    }
    
    @Test func testDecodeInt2() async throws {
        
        // lengthByte-1
        let data1 = Data([0x69, 0x00])
        let n1 = SECS2BodyDecoder.shared.decode(data1)
        
        #expect(n1?.type == .int2)
        #expect(n1?.count == 0)
        #expect(n1?.data == data1)
        
        // lengthByte-2
        let data2 = Data([0x6A, 0x00, 0x02,
                          0x00, 0x01])
        let n2 = SECS2BodyDecoder.shared.decode(data2)
        
        #expect(n2?.type == .int2)
        #expect(n2?.count == 1)
        #expect(n2?.getInt16(0) == 0x0001)
        #expect(n2?.data == data2)
        
        // lengthByte-3
        let data3 = Data([0x6B, 0x00, 0x00, 0x04,
                          0x00, 0x02,
                          0x00, 0x03])
        let n3 = SECS2BodyDecoder.shared.decode(data3)
        
        #expect(n3?.type == .int2)
        #expect(n3?.count == 2)
        #expect(n3?.getInt16(0) == 0x0002)
        #expect(n3?.getInt16(1) == 0x0003)
        #expect(n3?.data == data3)
        
        // list 1-2-3
        let data123 = Data([0x01, 0x03]) + data1 + data2 + data3
        let n123 = SECS2BodyDecoder.shared.decode(data123)
        
        #expect(n123?.getSECS2Body(0)?.type == .int2)
        #expect(n123?.getSECS2Body(0)?.count == 0)
        #expect(n123?.getSECS2Body(0)?.data == data1)
        
        #expect(n123?.getSECS2Body(1)?.type == .int2)
        #expect(n123?.getSECS2Body(1)?.count == 1)
        #expect(n123?.getInt16(1, 0) == 0x0001)
        #expect(n123?.getSECS2Body(1)?.data == data2)
        
        #expect(n123?.getSECS2Body(2)?.type == .int2)
        #expect(n123?.getSECS2Body(2)?.count == 2)
        #expect(n123?.getInt16(2, 0) == 0x0002)
        #expect(n123?.getInt16(2, 1) == 0x0003)
        #expect(n123?.getSECS2Body(2)?.data == data3)
        
    }
    
    @Test func testDecodeInt4() async throws {
        
        // lengthByte-1
        let data1 = Data([0x71, 0x00])
        let n1 = SECS2BodyDecoder.shared.decode(data1)
        
        #expect(n1?.type == .int4)
        #expect(n1?.count == 0)
        #expect(n1?.data == data1)
        
        // lengthByte-2
        let data2 = Data([0x72, 0x00, 0x04,
                          0x00, 0x00, 0x00, 0x01])
        let n2 = SECS2BodyDecoder.shared.decode(data2)
        
        #expect(n2?.type == .int4)
        #expect(n2?.count == 1)
        #expect(n2?.getInt32(0) == 0x00000001)
        #expect(n2?.data == data2)
        
        // lengthByte-3
        let data3 = Data([0x73, 0x00, 0x00, 0x08,
                          0x00, 0x00, 0x00, 0x02,
                          0x00, 0x00, 0x00, 0x03])
        let n3 = SECS2BodyDecoder.shared.decode(data3)
        
        #expect(n3?.type == .int4)
        #expect(n3?.count == 2)
        #expect(n3?.getInt32(0) == 0x00000002)
        #expect(n3?.getInt32(1) == 0x00000003)
        #expect(n3?.data == data3)
        
        // list 1-2-3
        let data123 = Data([0x01, 0x03]) + data1 + data2 + data3
        let n123 = SECS2BodyDecoder.shared.decode(data123)
        
        #expect(n123?.getSECS2Body(0)?.type == .int4)
        #expect(n123?.getSECS2Body(0)?.count == 0)
        #expect(n123?.getSECS2Body(0)?.data == data1)
        
        #expect(n123?.getSECS2Body(1)?.type == .int4)
        #expect(n123?.getSECS2Body(1)?.count == 1)
        #expect(n123?.getInt32(1, 0) == 0x0001)
        #expect(n123?.getSECS2Body(1)?.data == data2)
        
        #expect(n123?.getSECS2Body(2)?.type == .int4)
        #expect(n123?.getSECS2Body(2)?.count == 2)
        #expect(n123?.getInt32(2, 0) == 0x0002)
        #expect(n123?.getInt32(2, 1) == 0x0003)
        #expect(n123?.getSECS2Body(2)?.data == data3)
        
    }
    
    @Test func testDecodeInt8() async throws {
        
        // lengthByte-1
        let data1 = Data([0x61, 0x00])
        let n1 = SECS2BodyDecoder.shared.decode(data1)
        
        #expect(n1?.type == .int8)
        #expect(n1?.count == 0)
        #expect(n1?.data == data1)
        
        // lengthByte-2
        let data2 = Data([0x62, 0x00, 0x08,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01])
        let n2 = SECS2BodyDecoder.shared.decode(data2)
        
        #expect(n2?.type == .int8)
        #expect(n2?.count == 1)
        #expect(n2?.getInt64(0) == 0x0000000000000001)
        #expect(n2?.data == data2)
        
        // lengthByte-3
        let data3 = Data([0x63, 0x00, 0x00, 0x10,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03])
        let n3 = SECS2BodyDecoder.shared.decode(data3)
        
        #expect(n3?.type == .int8)
        #expect(n3?.count == 2)
        #expect(n3?.getInt64(0) == 0x0000000000000002)
        #expect(n3?.getInt64(1) == 0x0000000000000003)
        #expect(n3?.data == data3)
        
        // list 1-2-3
        let data123 = Data([0x01, 0x03]) + data1 + data2 + data3
        let n123 = SECS2BodyDecoder.shared.decode(data123)
        
        #expect(n123?.getSECS2Body(0)?.type == .int8)
        #expect(n123?.getSECS2Body(0)?.count == 0)
        #expect(n123?.getSECS2Body(0)?.data == data1)
        
        #expect(n123?.getSECS2Body(1)?.type == .int8)
        #expect(n123?.getSECS2Body(1)?.count == 1)
        #expect(n123?.getInt64(1, 0) == 0x000000000001)
        #expect(n123?.getSECS2Body(1)?.data == data2)
        
        #expect(n123?.getSECS2Body(2)?.type == .int8)
        #expect(n123?.getSECS2Body(2)?.count == 2)
        #expect(n123?.getInt64(2, 0) == 0x000000000002)
        #expect(n123?.getInt64(2, 1) == 0x000000000003)
        #expect(n123?.getSECS2Body(2)?.data == data3)
        
    }
    
    @Test func testDecodeUInt1() async throws {
        
        // lengthByte-1
        let data1 = Data([0xA5, 0x00])
        let n1 = SECS2BodyDecoder.shared.decode(data1)
        
        #expect(n1?.type == .uint1)
        #expect(n1?.count == 0)
        #expect(n1?.data == data1)
        
        // lengthByte-2
        let data2 = Data([0xA6, 0x00, 0x01, 0x01])
        let n2 = SECS2BodyDecoder.shared.decode(data2)
        
        #expect(n2?.type == .uint1)
        #expect(n2?.count == 1)
        #expect(n2?.getUInt8(0) == 0x01)
        #expect(n2?.data == data2)
        
        // lengthByte-3
        let data3 = Data([0xA7, 0x00, 0x00, 0x02, 0x02, 0x03])
        let n3 = SECS2BodyDecoder.shared.decode(data3)
        
        #expect(n3?.type == .uint1)
        #expect(n3?.count == 2)
        #expect(n3?.getUInt8(0) == 0x02)
        #expect(n3?.getUInt8(1) == 0x03)
        #expect(n3?.data == data3)
        
        // list 1-2-3
        let data123 = Data([0x01, 0x03]) + data1 + data2 + data3
        let n123 = SECS2BodyDecoder.shared.decode(data123)
        
        #expect(n123?.getSECS2Body(0)?.type == .uint1)
        #expect(n123?.getSECS2Body(0)?.count == 0)
        #expect(n123?.getSECS2Body(0)?.data == data1)
        
        #expect(n123?.getSECS2Body(1)?.type == .uint1)
        #expect(n123?.getSECS2Body(1)?.count == 1)
        #expect(n123?.getUInt8(1, 0) == 0x01)
        #expect(n123?.getSECS2Body(1)?.data == data2)
        
        #expect(n123?.getSECS2Body(2)?.type == .uint1)
        #expect(n123?.getSECS2Body(2)?.count == 2)
        #expect(n123?.getUInt8(2, 0) == 0x02)
        #expect(n123?.getUInt8(2, 1) == 0x03)
        #expect(n123?.getSECS2Body(2)?.data == data3)
        
    }
    
    @Test func testDecodeUInt2() async throws {
        
        // lengthByte-1
        let data1 = Data([0xA9, 0x00])
        let n1 = SECS2BodyDecoder.shared.decode(data1)
        
        #expect(n1?.type == .uint2)
        #expect(n1?.count == 0)
        #expect(n1?.data == data1)
        
        // lengthByte-2
        let data2 = Data([0xAA, 0x00, 0x02,
                          0x00, 0x01])
        let n2 = SECS2BodyDecoder.shared.decode(data2)
        
        #expect(n2?.type == .uint2)
        #expect(n2?.count == 1)
        #expect(n2?.getUInt16(0) == 0x0001)
        #expect(n2?.data == data2)
        
        // lengthByte-3
        let data3 = Data([0xAB, 0x00, 0x00, 0x04,
                          0x00, 0x02,
                          0x00, 0x03])
        let n3 = SECS2BodyDecoder.shared.decode(data3)
        
        #expect(n3?.type == .uint2)
        #expect(n3?.count == 2)
        #expect(n3?.getUInt16(0) == 0x0002)
        #expect(n3?.getUInt16(1) == 0x0003)
        #expect(n3?.data == data3)
        
        // list 1-2-3
        let data123 = Data([0x01, 0x03]) + data1 + data2 + data3
        let n123 = SECS2BodyDecoder.shared.decode(data123)
        
        #expect(n123?.getSECS2Body(0)?.type == .uint2)
        #expect(n123?.getSECS2Body(0)?.count == 0)
        #expect(n123?.getSECS2Body(0)?.data == data1)
        
        #expect(n123?.getSECS2Body(1)?.type == .uint2)
        #expect(n123?.getSECS2Body(1)?.count == 1)
        #expect(n123?.getUInt16(1, 0) == 0x0001)
        #expect(n123?.getSECS2Body(1)?.data == data2)
        
        #expect(n123?.getSECS2Body(2)?.type == .uint2)
        #expect(n123?.getSECS2Body(2)?.count == 2)
        #expect(n123?.getUInt16(2, 0) == 0x0002)
        #expect(n123?.getUInt16(2, 1) == 0x0003)
        #expect(n123?.getSECS2Body(2)?.data == data3)
        
    }
    
    @Test func testDecodeUInt4() async throws {
        
        // lengthByte-1
        let data1 = Data([0xB1, 0x00])
        let n1 = SECS2BodyDecoder.shared.decode(data1)
        
        #expect(n1?.type == .uint4)
        #expect(n1?.count == 0)
        #expect(n1?.data == data1)
        
        // lengthByte-2
        let data2 = Data([0xB2, 0x00, 0x04,
                          0x00, 0x00, 0x00, 0x01])
        let n2 = SECS2BodyDecoder.shared.decode(data2)
        
        #expect(n2?.type == .uint4)
        #expect(n2?.count == 1)
        #expect(n2?.getUInt32(0) == 0x00000001)
        #expect(n2?.data == data2)
        
        // lengthByte-3
        let data3 = Data([0xB3, 0x00, 0x00, 0x08,
                          0x00, 0x00, 0x00, 0x02,
                          0x00, 0x00, 0x00, 0x03])
        let n3 = SECS2BodyDecoder.shared.decode(data3)
        
        #expect(n3?.type == .uint4)
        #expect(n3?.count == 2)
        #expect(n3?.getUInt32(0) == 0x00000002)
        #expect(n3?.getUInt32(1) == 0x00000003)
        #expect(n3?.data == data3)
        
        // list 1-2-3
        let data123 = Data([0x01, 0x03]) + data1 + data2 + data3
        let n123 = SECS2BodyDecoder.shared.decode(data123)
        
        #expect(n123?.getSECS2Body(0)?.type == .uint4)
        #expect(n123?.getSECS2Body(0)?.count == 0)
        #expect(n123?.getSECS2Body(0)?.data == data1)
        
        #expect(n123?.getSECS2Body(1)?.type == .uint4)
        #expect(n123?.getSECS2Body(1)?.count == 1)
        #expect(n123?.getUInt32(1, 0) == 0x0001)
        #expect(n123?.getSECS2Body(1)?.data == data2)
        
        #expect(n123?.getSECS2Body(2)?.type == .uint4)
        #expect(n123?.getSECS2Body(2)?.count == 2)
        #expect(n123?.getUInt32(2, 0) == 0x0002)
        #expect(n123?.getUInt32(2, 1) == 0x0003)
        #expect(n123?.getSECS2Body(2)?.data == data3)
        
    }
    
    @Test func testDecodeUInt8() async throws {
        
        // lengthByte-1
        let data1 = Data([0xA1, 0x00])
        let n1 = SECS2BodyDecoder.shared.decode(data1)
        
        #expect(n1?.type == .uint8)
        #expect(n1?.count == 0)
        #expect(n1?.data == data1)
        
        // lengthByte-2
        let data2 = Data([0xA2, 0x00, 0x08,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01])
        let n2 = SECS2BodyDecoder.shared.decode(data2)
        
        #expect(n2?.type == .uint8)
        #expect(n2?.count == 1)
        #expect(n2?.getUInt64(0) == 0x0000000000000001)
        #expect(n2?.data == data2)
        
        // lengthByte-3
        let data3 = Data([0xA3, 0x00, 0x00, 0x10,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03])
        let n3 = SECS2BodyDecoder.shared.decode(data3)
        
        #expect(n3?.type == .uint8)
        #expect(n3?.count == 2)
        #expect(n3?.getUInt64(0) == 0x0000000000000002)
        #expect(n3?.getUInt64(1) == 0x0000000000000003)
        #expect(n3?.data == data3)
        
        // list 1-2-3
        let data123 = Data([0x01, 0x03]) + data1 + data2 + data3
        let n123 = SECS2BodyDecoder.shared.decode(data123)
        
        #expect(n123?.getSECS2Body(0)?.type == .uint8)
        #expect(n123?.getSECS2Body(0)?.count == 0)
        #expect(n123?.getSECS2Body(0)?.data == data1)
        
        #expect(n123?.getSECS2Body(1)?.type == .uint8)
        #expect(n123?.getSECS2Body(1)?.count == 1)
        #expect(n123?.getUInt64(1, 0) == 0x000000000001)
        #expect(n123?.getSECS2Body(1)?.data == data2)
        
        #expect(n123?.getSECS2Body(2)?.type == .uint8)
        #expect(n123?.getSECS2Body(2)?.count == 2)
        #expect(n123?.getUInt64(2, 0) == 0x000000000002)
        #expect(n123?.getUInt64(2, 1) == 0x000000000003)
        #expect(n123?.getSECS2Body(2)?.data == data3)
        
    }
    
    @Test func testDecodeFloat4() async throws {
        
        // lengthByte-1
        let data1 = Data([0x91, 0x00])
        let n1 = SECS2BodyDecoder.shared.decode(data1)
        
        #expect(n1?.type == .float4)
        #expect(n1?.count == 0)
        #expect(n1?.data == data1)
        
        // lengthByte-2
        let data2 = Data([0x92, 0x00, 0x04,
                          0x3F, 0x80, 0x00, 0x00])
        let n2 = SECS2BodyDecoder.shared.decode(data2)
        
        #expect(n2?.type == .float4)
        #expect(n2?.count == 1)
        #expect(n2?.getFloat(0) == 1.0)
        #expect(n2?.data == data2)
        
        // lengthByte-3
        let data3 = Data([0x93, 0x00, 0x00, 0x08,
                          0x40, 0x00, 0x00, 0x00,
                          0x40, 0x40, 0x00, 0x00])
        let n3 = SECS2BodyDecoder.shared.decode(data3)
        
        #expect(n3?.type == .float4)
        #expect(n3?.count == 2)
        #expect(n3?.getFloat(0) == 2.0)
        #expect(n3?.getFloat(1) == 3.0)
        #expect(n3?.data == data3)
        
        // list 1-2-3
        let data123 = Data([0x01, 0x03]) + data1 + data2 + data3
        let n123 = SECS2BodyDecoder.shared.decode(data123)
        
        #expect(n123?.getSECS2Body(0)?.type == .float4)
        #expect(n123?.getSECS2Body(0)?.count == 0)
        #expect(n123?.getSECS2Body(0)?.data == data1)
        
        #expect(n123?.getSECS2Body(1)?.type == .float4)
        #expect(n123?.getSECS2Body(1)?.count == 1)
        #expect(n123?.getFloat(1, 0) == 1.0)
        #expect(n123?.getSECS2Body(1)?.data == data2)
        
        #expect(n123?.getSECS2Body(2)?.type == .float4)
        #expect(n123?.getSECS2Body(2)?.count == 2)
        #expect(n123?.getFloat(2, 0) == 2.0)
        #expect(n123?.getFloat(2, 1) == 3.0)
        #expect(n123?.getSECS2Body(2)?.data == data3)
        
    }
    
    @Test func testDecodeFloat8() async throws {
        
        // lengthByte-1
        let data1 = Data([0x81, 0x00])
        let n1 = SECS2BodyDecoder.shared.decode(data1)
        
        #expect(n1?.type == .float8)
        #expect(n1?.count == 0)
        #expect(n1?.data == data1)
        
        // lengthByte-2
        let data2 = Data([0x82, 0x00, 0x08,
                          0x3F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        let n2 = SECS2BodyDecoder.shared.decode(data2)
        
        #expect(n2?.type == .float8)
        #expect(n2?.count == 1)
        #expect(n2?.getDouble(0) == 1.0)
        #expect(n2?.data == data2)
        
        // lengthByte-3
        let data3 = Data([0x83, 0x00, 0x00, 0x10,
                          0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x40, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        let n3 = SECS2BodyDecoder.shared.decode(data3)
        
        #expect(n3?.type == .float8)
        #expect(n3?.count == 2)
        #expect(n3?.getDouble(0) == 2.0)
        #expect(n3?.getDouble(1) == 3.0)
        #expect(n3?.data == data3)
        
        // list 1-2-3
        let data123 = Data([0x01, 0x03]) + data1 + data2 + data3
        let n123 = SECS2BodyDecoder.shared.decode(data123)
        
        #expect(n123?.getSECS2Body(0)?.type == .float8)
        #expect(n123?.getSECS2Body(0)?.count == 0)
        #expect(n123?.getSECS2Body(0)?.data == data1)
        
        #expect(n123?.getSECS2Body(1)?.type == .float8)
        #expect(n123?.getSECS2Body(1)?.count == 1)
        #expect(n123?.getDouble(1, 0) == 1.0)
        #expect(n123?.getSECS2Body(1)?.data == data2)
        
        #expect(n123?.getSECS2Body(2)?.type == .float8)
        #expect(n123?.getSECS2Body(2)?.count == 2)
        #expect(n123?.getDouble(2, 0) == 2.0)
        #expect(n123?.getDouble(2, 1) == 3.0)
        #expect(n123?.getSECS2Body(2)?.data == data3)
        
    }
    
    @Test func testDecodeUnknown() async throws {
        
        // lengthByte-1
        let data1 = Data([0xC1, 0x00])
        let u1 = SECS2BodyDecoder.shared.decode(data1)
        
        #expect(u1?.type == .unknown)
        #expect(u1?.data == data1)
        
    }
    
    @Test func testDecodeError() async throws {
        
        // no-length-bits
        let data1 = Data([0x20, 0x00])
        let e1 = SECS2BodyDecoder.shared.decode(data1)
        
        #expect(e1?.type == .error)
        #expect(e1?.data == data1)
        
        // not-reach-end
        let data2 = Data([0x21, 0x00, 0x00])
        let e2 = SECS2BodyDecoder.shared.decode(data2)
        
        #expect(e2?.type == .error)
        #expect(e2?.data == data2)
        
        // short-bytes
        let data3 = Data([0x21, 0x03, 0x01, 0x02])
        let e3 = SECS2BodyDecoder.shared.decode(data3)
        
        #expect(e3?.type == .error)
        #expect(e3?.data == data3)
        
    }
    
}
