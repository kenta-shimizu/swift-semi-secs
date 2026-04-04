//
//  SECS2BodyBuilderTests.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/01/03.
//

import Testing
import Foundation
@testable import SemiSecs

struct SECS2BodyBuilderTests {
    
    @Test func testBuildList() async throws {
        
        let builder = SECS2BodyBuilder.shared
        
        let l0 = builder.build(list: [])
        #expect(l0.type == .list)
        #expect(l0.count == 0)
        #expect(l0.getSECS2Body(0) == nil)
        #expect(l0.data == Data([0x01, 0x00]))
        #expect(l0.smlString == "<L [0]\n>")
        
        let l1 = builder.build(list: [l0])
        #expect(l1.type == .list)
        #expect(l1.count == 1)
        #expect(l1.getSECS2Body(0) != nil)
        #expect(l1.getSECS2Body(1) == nil)
        #expect(l1.getSECS2Body(0, 0) == nil)
        
        #expect(l1.getSECS2Body(0) != nil)
        #expect(l1.getBool(0) == nil)
        #expect(l1.getString() == nil)
        #expect(l1.getInt8(0) == nil)
        #expect(l1.getInt16(0) == nil)
        #expect(l1.getInt32(0) == nil)
        #expect(l1.getInt64(0) == nil)
        #expect(l1.getUInt8(0) == nil)
        #expect(l1.getUInt16(0) == nil)
        #expect(l1.getUInt32(0) == nil)
        #expect(l1.getUInt64(0) == nil)
        #expect(l1.getFloat(0) == nil)
        #expect(l1.getDouble(0) == nil)
        
        #expect(l1.data == Data([0x01, 0x01, 0x01, 0x00]))
        #expect(l1.smlString == "<L [1]\n  <L [0]\n  >\n>")
    }
    
    @Test func testBuildBinary() async throws {
        
        let builder = SECS2BodyBuilder.shared
        
        let b0 = builder.build(binary: Data([]))
        #expect(b0.type == .binary)
        #expect(b0.count == 0)
        #expect(b0.getUInt8(0) == nil)
        #expect(b0.data == Data([0x21, 0x00]))
        #expect(b0.smlString == "<B [0] >")
        
        var a0: [UInt8] = []
        for v in b0 {
            a0.append(v as! UInt8)
        }
        #expect(a0.count == 0)
        
        let b3 = builder.build(binary: Data([0x01, 0x02, 0x03]))
        #expect(b3.type == .binary)
        #expect(b3.count == 3)
        #expect(b3.getUInt8(0) == 0x01)
        #expect(b3.getUInt8(1) == 0x02)
        #expect(b3.getUInt8(2) == 0x03)
        #expect(b3.getUInt8(3) == nil)
        #expect(b3.getUInt8(0, 0) == nil)
        #expect((b3[0] as? UInt8) == 0x01)
        
        var a3: [UInt8] = []
        for v in b3 {
            a3.append(v as! UInt8)
        }
        #expect(a3 == [0x01, 0x02, 0x03])
        
        #expect(b3.getSECS2Body(0) == nil)
        #expect(b3.getBool(0) == nil)
        #expect(b3.getString() == nil)
        #expect(b3.getInt8(0) == nil)
        #expect(b3.getInt16(0) == nil)
        #expect(b3.getInt32(0) == nil)
        #expect(b3.getInt64(0) == nil)
        #expect(b3.getUInt8(0) == 0x01)
        #expect(b3.getUInt16(0) == nil)
        #expect(b3.getUInt32(0) == nil)
        #expect(b3.getUInt64(0) == nil)
        #expect(b3.getFloat(0) == nil)
        #expect(b3.getDouble(0) == nil)
        
        #expect((b3.value as? Data) == Data([0x01, 0x02, 0x03]))
        #expect(b3.data == Data([0x21, 0x03, 0x01, 0x02, 0x03]))
        #expect((b3.getAny() as? Data) == Data([0x01, 0x02, 0x03]))
        #expect((b3.getAny(0) as? UInt8) == 0x01)
        #expect((b3.getAny(3) as? UInt8) == nil)
        #expect((b3.getAny(0, 0) as? UInt8) == nil)
        #expect(b3.smlString == "<B [3] 0x01 0x02 0x03 >")
        
        let bl = builder.build(list: [b0, b3])
        #expect(bl.getUInt8(1, 0) == 0x01)
        #expect(bl.getUInt8(1, 1) == 0x02)
        #expect(bl.getUInt8(1, 2) == 0x03)
        #expect(bl.getUInt8(1, 3) == nil)
        #expect(bl.getUInt8(1, 0, 0) == nil)
        #expect(bl.data == Data([0x01, 0x02,
                                 0x21, 0x00,
                                 0x21, 0x03, 0x01, 0x02, 0x03]))
    }
    
    @Test func testBuildBoolean() async throws {
        
        let builder = SECS2BodyBuilder.shared
        
        let b0 = builder.build(boolean: [])
        #expect(b0.type == .boolean)
        #expect(b0.count == 0)
        #expect(b0.getUInt8(0) == nil)
        #expect(b0.data == Data([0x25, 0x00]))
        #expect(b0.smlString == "<BOOLEAN [0] >")
        
        var a0: [Bool] = []
        for v in b0 {
            a0.append(v as! Bool)
        }
        #expect(a0.count == 0)
        
        let b2 = builder.build(boolean: [false, true])
        #expect(b2.type == .boolean)
        #expect(b2.count == 2)
        #expect(b2.getBool(0) == false)
        #expect(b2.getBool(1) == true)
        #expect(b2.getBool(2) == nil)
        #expect(b2.getBool(0, 0) == nil)
        #expect((b2[0] as? Bool) == false)
        
        var a2: [Bool] = []
        for v in b2 {
            a2.append(v as! Bool)
        }
        #expect(a2 == [false, true])
        
        #expect(b2.getSECS2Body(0) == nil)
        #expect(b2.getBool(0) == false)
        #expect(b2.getString() == nil)
        #expect(b2.getInt8(0) == nil)
        #expect(b2.getInt16(0) == nil)
        #expect(b2.getInt32(0) == nil)
        #expect(b2.getInt64(0) == nil)
        #expect(b2.getUInt8(0) == nil)
        #expect(b2.getUInt16(0) == nil)
        #expect(b2.getUInt32(0) == nil)
        #expect(b2.getUInt64(0) == nil)
        #expect(b2.getFloat(0) == nil)
        #expect(b2.getDouble(0) == nil)
        
        #expect((b2.value as? [Bool]) == [false, true])
        #expect(b2.data == Data([0x25, 0x02, 0x00, 0xFF]))
        #expect((b2.getAny() as? [Bool]) == [false, true])
        #expect((b2.getAny(0) as? Bool) == false)
        #expect((b2.getAny(2) as? Bool) == nil)
        #expect((b2.getAny(0, 0) as? Bool) == nil)
        #expect(b2.smlString == "<BOOLEAN [2] FALSE TRUE >")
        
        let bl = builder.build(list: [b0, b2])
        #expect(bl.getBool(1, 0) == false)
        #expect(bl.getBool(1, 1) == true)
        #expect(bl.getBool(1, 2) == nil)
        #expect(bl.getBool(1, 0, 0) == nil)
        #expect(bl.data == Data([0x01, 0x02,
                                 0x25, 0x00,
                                 0x25, 0x02, 0x00, 0xFF]))
    }
    
    @Test func testBuildAscii() async throws {
        
        let builder = SECS2BodyBuilder.shared
        
        let a0 = builder.build(ascii: "")
        #expect(a0.type == .ascii)
        #expect(a0.count == 0)
        #expect(a0.getString() == "")
        #expect(a0.data == Data([0x41, 0x00]))
        #expect(a0.smlString == "<A [0] \"\" >")
        
        let a3 = builder.build(ascii: "ABC")
        #expect(a3.type == .ascii)
        #expect(a3.count == 3)
        #expect(a3.getString() == "ABC")
        #expect(a3.getString(0) == nil)
        #expect((a3[0] as? Character) == Character("A"))
        
        #expect(a3.getSECS2Body(0) == nil)
        #expect(a3.getBool(0) == nil)
        #expect(a3.getString() == "ABC")
        #expect(a3.getInt8(0) == nil)
        #expect(a3.getInt16(0) == nil)
        #expect(a3.getInt32(0) == nil)
        #expect(a3.getInt64(0) == nil)
        #expect(a3.getUInt8(0) == nil)
        #expect(a3.getUInt16(0) == nil)
        #expect(a3.getUInt32(0) == nil)
        #expect(a3.getUInt64(0) == nil)
        #expect(a3.getFloat(0) == nil)
        #expect(a3.getDouble(0) == nil)
        
        #expect((a3.value as? String) == "ABC")
        #expect(a3.data == Data([0x41, 0x03, 0x41, 0x42, 0x43]))
        #expect((a3.getAny() as? String) == "ABC")
        #expect((a3.getAny(0) as? Character) == Character("A"))
        #expect((a3.getAny(3) as? Character) == nil)
        #expect((a3.getAny(0, 0) as? Character) == nil)
        #expect(a3.smlString == "<A [3] \"ABC\" >")
        
        let al = builder.build(list: [a0, a3])
        #expect(al.getString(0) == "")
        #expect(al.getString(1) == "ABC")
        #expect(al.getString(2) == nil)
        #expect(al.getString(1, 0) == nil)
        #expect(al.data == Data([0x01, 0x02,
                                 0x41, 0x00,
                                 0x41, 0x03, 0x41, 0x42, 0x43]))
    }
    
    @Test func testBuildInt1() async throws {
        
        let builder = SECS2BodyBuilder.shared
        
        let i0 = builder.build(int1: [])
        #expect(i0.type == .int1)
        #expect(i0.count == 0)
        #expect(i0.getInt8(0) == nil)
        #expect(i0.data == Data([0x65, 0x00]))
        #expect(i0.smlString == "<I1 [0] >")
        
        var a0: [Int8] = []
        for v in i0 {
            a0.append(v as! Int8)
        }
        #expect(a0.count == 0)
        
        let i3 = builder.build(int1: [1, 2, 3])
        #expect(i3.type == .int1)
        #expect(i3.count == 3)
        #expect(i3.getInt8(0) == 1)
        #expect(i3.getInt8(1) == 2)
        #expect(i3.getInt8(2) == 3)
        #expect(i3.getInt8(3) == nil)
        #expect(i3.getInt8(0, 0) == nil)
        #expect((i3[0] as? Int8) == 1)
        
        var a3: [Int8] = []
        for v in i3 {
            a3.append(v as! Int8)
        }
        #expect(a3 == [1, 2, 3])
        
        #expect(i3.getSECS2Body(0) == nil)
        #expect(i3.getBool(0) == nil)
        #expect(i3.getString() == nil)
        #expect(i3.getInt8(0) == 1)
        #expect(i3.getInt16(0) == nil)
        #expect(i3.getInt32(0) == nil)
        #expect(i3.getInt64(0) == nil)
        #expect(i3.getUInt8(0) == nil)
        #expect(i3.getUInt16(0) == nil)
        #expect(i3.getUInt32(0) == nil)
        #expect(i3.getUInt64(0) == nil)
        #expect(i3.getFloat(0) == nil)
        #expect(i3.getDouble(0) == nil)
        
        #expect((i3.value as? [Int8]) == [1, 2, 3])
        #expect(i3.data == Data([0x65, 0x03, 0x01, 0x02, 0x03]))
        #expect((i3.getAny() as? [Int8]) == [1, 2, 3])
        #expect((i3.getAny(0) as? Int8) == 1)
        #expect((i3.getAny(3) as? Int8) == nil)
        #expect((i3.getAny(0, 0) as? Int8) == nil)
        #expect(i3.smlString == "<I1 [3] 1 2 3 >")
        
        let il = builder.build(list: [i0, i3])
        #expect(il.getInt8(1, 0) == 1)
        #expect(il.getInt8(1, 1) == 2)
        #expect(il.getInt8(1, 2) == 3)
        #expect(il.getInt8(1, 3) == nil)
        #expect(il.getInt8(1, 0, 0) == nil)
        #expect(il.data == Data([0x01, 0x02,
                                 0x65, 0x00,
                                 0x65, 0x03, 0x01, 0x02, 0x03]))
    }
    
    @Test func testBuildInt2() async throws {
        
        let builder = SECS2BodyBuilder.shared
        
        let i0 = builder.build(int2: [])
        #expect(i0.type == .int2)
        #expect(i0.count == 0)
        #expect(i0.getInt16(0) == nil)
        #expect(i0.data == Data([0x69, 0x00]))
        #expect(i0.smlString == "<I2 [0] >")
        
        var a0: [Int16] = []
        for v in i0 {
            a0.append(v as! Int16)
        }
        #expect(a0.count == 0)
        
        let i3 = builder.build(int2: [1, 2, 3])
        #expect(i3.type == .int2)
        #expect(i3.count == 3)
        #expect(i3.getInt16(0) == 1)
        #expect(i3.getInt16(1) == 2)
        #expect(i3.getInt16(2) == 3)
        #expect(i3.getInt16(3) == nil)
        #expect(i3.getInt16(0, 0) == nil)
        #expect((i3[0] as? Int16) == 1)
        
        var a3: [Int16] = []
        for v in i3 {
            a3.append(v as! Int16)
        }
        #expect(a3 == [1, 2, 3])
        
        #expect(i3.getSECS2Body(0) == nil)
        #expect(i3.getBool(0) == nil)
        #expect(i3.getString() == nil)
        #expect(i3.getInt8(0) == nil)
        #expect(i3.getInt16(0) == 1)
        #expect(i3.getInt32(0) == nil)
        #expect(i3.getInt64(0) == nil)
        #expect(i3.getUInt8(0) == nil)
        #expect(i3.getUInt16(0) == nil)
        #expect(i3.getUInt32(0) == nil)
        #expect(i3.getUInt64(0) == nil)
        #expect(i3.getFloat(0) == nil)
        #expect(i3.getDouble(0) == nil)
        
        #expect((i3.value as? [Int16]) == [1, 2, 3])
        #expect(i3.data == Data([0x69, 0x06,
                                 0x00, 0x01,
                                 0x00, 0x02,
                                 0x00, 0x03]))
        #expect((i3.getAny() as? [Int16]) == [1, 2, 3])
        #expect((i3.getAny(0) as? Int16) == 1)
        #expect((i3.getAny(3) as? Int16) == nil)
        #expect((i3.getAny(0, 0) as? Int16) == nil)
        #expect(i3.smlString == "<I2 [3] 1 2 3 >")
        
        let il = builder.build(list: [i0, i3])
        #expect(il.getInt16(1, 0) == 1)
        #expect(il.getInt16(1, 1) == 2)
        #expect(il.getInt16(1, 2) == 3)
        #expect(il.getInt16(1, 3) == nil)
        #expect(il.getInt16(1, 0, 0) == nil)
        #expect(il.data == Data([0x01, 0x02,
                                 0x69, 0x00,
                                 0x69, 0x06,
                                 0x00, 0x01,
                                 0x00, 0x02,
                                 0x00, 0x03]))
    }
    
    @Test func testBuildInt4() async throws {
        
        let builder = SECS2BodyBuilder.shared
        
        let i0 = builder.build(int4: [])
        #expect(i0.type == .int4)
        #expect(i0.count == 0)
        #expect(i0.getInt32(0) == nil)
        #expect(i0.data == Data([0x71, 0x00]))
        #expect(i0.smlString == "<I4 [0] >")
        
        var a0: [Int32] = []
        for v in i0 {
            a0.append(v as! Int32)
        }
        #expect(a0.count == 0)
        
        let i3 = builder.build(int4: [1, 2, 3])
        #expect(i3.type == .int4)
        #expect(i3.count == 3)
        #expect(i3.getInt32(0) == 1)
        #expect(i3.getInt32(1) == 2)
        #expect(i3.getInt32(2) == 3)
        #expect(i3.getInt32(3) == nil)
        #expect(i3.getInt32(0, 0) == nil)
        #expect((i3[0] as? Int32) == 1)
        
        var a3: [Int32] = []
        for v in i3 {
            a3.append(v as! Int32)
        }
        #expect(a3 == [1, 2, 3])
        
        #expect(i3.getSECS2Body(0) == nil)
        #expect(i3.getBool(0) == nil)
        #expect(i3.getString() == nil)
        #expect(i3.getInt8(0) == nil)
        #expect(i3.getInt16(0) == nil)
        #expect(i3.getInt32(0) == 1)
        #expect(i3.getInt64(0) == nil)
        #expect(i3.getUInt8(0) == nil)
        #expect(i3.getUInt16(0) == nil)
        #expect(i3.getUInt32(0) == nil)
        #expect(i3.getUInt64(0) == nil)
        #expect(i3.getFloat(0) == nil)
        #expect(i3.getDouble(0) == nil)
        
        #expect((i3.value as? [Int32]) == [1, 2, 3])
        #expect(i3.data == Data([0x71, 0x0C,
                                 0x00, 0x00, 0x00, 0x01,
                                 0x00, 0x00, 0x00, 0x02,
                                 0x00, 0x00, 0x00, 0x03]))
        #expect((i3.getAny() as? [Int32]) == [1, 2, 3])
        #expect((i3.getAny(0) as? Int32) == 1)
        #expect((i3.getAny(3) as? Int32) == nil)
        #expect((i3.getAny(0, 0) as? Int32) == nil)
        #expect(i3.smlString == "<I4 [3] 1 2 3 >")
        
        let il = builder.build(list: [i0, i3])
        #expect(il.getInt32(1, 0) == 1)
        #expect(il.getInt32(1, 1) == 2)
        #expect(il.getInt32(1, 2) == 3)
        #expect(il.getInt32(1, 3) == nil)
        #expect(il.getInt32(1, 0, 0) == nil)
        #expect(il.data == Data([0x01, 0x02,
                                 0x71, 0x00,
                                 0x71, 0x0C,
                                 0x00, 0x00, 0x00, 0x01,
                                 0x00, 0x00, 0x00, 0x02,
                                 0x00, 0x00, 0x00, 0x03]))
    }
    
    @Test func testBuildInt8() async throws {
        
        let builder = SECS2BodyBuilder.shared
        
        let i0 = builder.build(int8: [])
        #expect(i0.type == .int8)
        #expect(i0.count == 0)
        #expect(i0.getInt64(0) == nil)
        #expect(i0.data == Data([0x61, 0x00]))
        #expect(i0.smlString == "<I8 [0] >")
        
        var a0: [Int64] = []
        for v in i0 {
            a0.append(v as! Int64)
        }
        #expect(a0.count == 0)
        
        let i3 = builder.build(int8: [1, 2, 3])
        #expect(i3.type == .int8)
        #expect(i3.count == 3)
        #expect(i3.getInt64(0) == 1)
        #expect(i3.getInt64(1) == 2)
        #expect(i3.getInt64(2) == 3)
        #expect(i3.getInt64(3) == nil)
        #expect(i3.getInt64(0, 0) == nil)
        #expect((i3[0] as? Int64) == 1)
        
        var a3: [Int64] = []
        for v in i3 {
            a3.append(v as! Int64)
        }
        #expect(a3 == [1, 2, 3])
        
        #expect(i3.getSECS2Body(0) == nil)
        #expect(i3.getBool(0) == nil)
        #expect(i3.getString() == nil)
        #expect(i3.getInt8(0) == nil)
        #expect(i3.getInt16(0) == nil)
        #expect(i3.getInt32(0) == nil)
        #expect(i3.getInt64(0) == 1)
        #expect(i3.getUInt8(0) == nil)
        #expect(i3.getUInt16(0) == nil)
        #expect(i3.getUInt32(0) == nil)
        #expect(i3.getUInt64(0) == nil)
        #expect(i3.getFloat(0) == nil)
        #expect(i3.getDouble(0) == nil)
        
        #expect((i3.value as? [Int64]) == [1, 2, 3])
        #expect(i3.data == Data([0x61, 0x18,
                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02,
                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03]))
        #expect((i3.getAny() as? [Int64]) == [1, 2, 3])
        #expect((i3.getAny(0) as? Int64) == 1)
        #expect((i3.getAny(3) as? Int64) == nil)
        #expect((i3.getAny(0, 0) as? Int64) == nil)
        #expect(i3.smlString == "<I8 [3] 1 2 3 >")
        
        let il = builder.build(list: [i0, i3])
        #expect(il.getInt64(1, 0) == 1)
        #expect(il.getInt64(1, 1) == 2)
        #expect(il.getInt64(1, 2) == 3)
        #expect(il.getInt64(1, 3) == nil)
        #expect(il.getInt64(1, 0, 0) == nil)
        #expect(il.data == Data([0x01, 0x02,
                                 0x61, 0x00,
                                 0x61, 0x18,
                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02,
                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03]))
    }
    
    @Test func testBuildUInt1() async throws {
        
        let builder = SECS2BodyBuilder.shared
        
        let i0 = builder.build(uint1: [])
        #expect(i0.type == .uint1)
        #expect(i0.count == 0)
        #expect(i0.getInt8(0) == nil)
        #expect(i0.data == Data([0xA5, 0x00]))
        #expect(i0.smlString == "<U1 [0] >")
        
        var a0: [UInt8] = []
        for v in i0 {
            a0.append(v as! UInt8)
        }
        #expect(a0.count == 0)
        
        let i3 = builder.build(uint1: [1, 2, 3])
        #expect(i3.type == .uint1)
        #expect(i3.count == 3)
        #expect(i3.getUInt8(0) == 1)
        #expect(i3.getUInt8(1) == 2)
        #expect(i3.getUInt8(2) == 3)
        #expect(i3.getUInt8(3) == nil)
        #expect(i3.getUInt8(0, 0) == nil)
        #expect((i3[0] as? UInt8) == 1)
        
        var a3: [UInt8] = []
        for v in i3 {
            a3.append(v as! UInt8)
        }
        #expect(a3 == [1, 2, 3])
        
        #expect(i3.getSECS2Body(0) == nil)
        #expect(i3.getBool(0) == nil)
        #expect(i3.getString() == nil)
        #expect(i3.getInt8(0) == nil)
        #expect(i3.getInt16(0) == nil)
        #expect(i3.getInt32(0) == nil)
        #expect(i3.getInt64(0) == nil)
        #expect(i3.getUInt8(0) == 1)
        #expect(i3.getUInt16(0) == nil)
        #expect(i3.getUInt32(0) == nil)
        #expect(i3.getUInt64(0) == nil)
        #expect(i3.getFloat(0) == nil)
        #expect(i3.getDouble(0) == nil)
        
        #expect((i3.value as? [UInt8]) == [1, 2, 3])
        #expect(i3.data == Data([0xA5, 0x03, 0x01, 0x02, 0x03]))
        #expect((i3.getAny() as? [UInt8]) == [1, 2, 3])
        #expect((i3.getAny(0) as? UInt8) == 1)
        #expect((i3.getAny(3) as? UInt8) == nil)
        #expect((i3.getAny(0, 0) as? UInt8) == nil)
        #expect(i3.smlString == "<U1 [3] 1 2 3 >")
        
        let il = builder.build(list: [i0, i3])
        #expect(il.getUInt8(1, 0) == 1)
        #expect(il.getUInt8(1, 1) == 2)
        #expect(il.getUInt8(1, 2) == 3)
        #expect(il.getUInt8(1, 3) == nil)
        #expect(il.getUInt8(1, 0, 0) == nil)
        #expect(il.data == Data([0x01, 0x02,
                                 0xA5, 0x00,
                                 0xA5, 0x03, 0x01, 0x02, 0x03]))
    }
    
    @Test func testBuildUInt2() async throws {
        
        let builder = SECS2BodyBuilder.shared
        
        let i0 = builder.build(uint2: [])
        #expect(i0.type == .uint2)
        #expect(i0.count == 0)
        #expect(i0.getInt16(0) == nil)
        #expect(i0.data == Data([0xA9, 0x00]))
        #expect(i0.smlString == "<U2 [0] >")
        
        var a0: [UInt16] = []
        for v in i0 {
            a0.append(v as! UInt16)
        }
        #expect(a0.count == 0)
        
        let i3 = builder.build(uint2: [1, 2, 3])
        #expect(i3.type == .uint2)
        #expect(i3.count == 3)
        #expect(i3.getUInt16(0) == 1)
        #expect(i3.getUInt16(1) == 2)
        #expect(i3.getUInt16(2) == 3)
        #expect(i3.getUInt16(3) == nil)
        #expect(i3.getUInt16(0, 0) == nil)
        #expect((i3[0] as? UInt16) == 1)
        
        var a3: [UInt16] = []
        for v in i3 {
            a3.append(v as! UInt16)
        }
        #expect(a3 == [1, 2, 3])
        
        #expect(i3.getSECS2Body(0) == nil)
        #expect(i3.getBool(0) == nil)
        #expect(i3.getString() == nil)
        #expect(i3.getInt8(0) == nil)
        #expect(i3.getInt16(0) == nil)
        #expect(i3.getInt32(0) == nil)
        #expect(i3.getInt64(0) == nil)
        #expect(i3.getUInt8(0) == nil)
        #expect(i3.getUInt16(0) == 1)
        #expect(i3.getUInt32(0) == nil)
        #expect(i3.getUInt64(0) == nil)
        #expect(i3.getFloat(0) == nil)
        #expect(i3.getDouble(0) == nil)
        
        #expect((i3.value as? [UInt16]) == [1, 2, 3])
        #expect(i3.data == Data([0xA9, 0x06,
                                 0x00, 0x01,
                                 0x00, 0x02,
                                 0x00, 0x03]))
        #expect((i3.getAny() as? [UInt16]) == [1, 2, 3])
        #expect((i3.getAny(0) as? UInt16) == 1)
        #expect((i3.getAny(3) as? UInt16) == nil)
        #expect((i3.getAny(0, 0) as? UInt16) == nil)
        #expect(i3.smlString == "<U2 [3] 1 2 3 >")
        
        let il = builder.build(list: [i0, i3])
        #expect(il.getUInt16(1, 0) == 1)
        #expect(il.getUInt16(1, 1) == 2)
        #expect(il.getUInt16(1, 2) == 3)
        #expect(il.getUInt16(1, 3) == nil)
        #expect(il.getUInt16(1, 0, 0) == nil)
        #expect(il.data == Data([0x01, 0x02,
                                 0xA9, 0x00,
                                 0xA9, 0x06,
                                 0x00, 0x01,
                                 0x00, 0x02,
                                 0x00, 0x03]))
    }
    
    @Test func testBuildUInt4() async throws {
        
        let builder = SECS2BodyBuilder.shared
        
        let i0 = builder.build(uint4: [])
        #expect(i0.type == .uint4)
        #expect(i0.count == 0)
        #expect(i0.getInt32(0) == nil)
        #expect(i0.data == Data([0xB1, 0x00]))
        #expect(i0.smlString == "<U4 [0] >")
        
        var a0: [UInt32] = []
        for v in i0 {
            a0.append(v as! UInt32)
        }
        #expect(a0.count == 0)
        
        let i3 = builder.build(uint4: [1, 2, 3])
        #expect(i3.type == .uint4)
        #expect(i3.count == 3)
        #expect(i3.getUInt32(0) == 1)
        #expect(i3.getUInt32(1) == 2)
        #expect(i3.getUInt32(2) == 3)
        #expect(i3.getUInt32(3) == nil)
        #expect(i3.getUInt32(0, 0) == nil)
        #expect((i3[0] as? UInt32) == 1)
        
        var a3: [UInt32] = []
        for v in i3 {
            a3.append(v as! UInt32)
        }
        #expect(a3 == [1, 2, 3])
        
        #expect(i3.getSECS2Body(0) == nil)
        #expect(i3.getBool(0) == nil)
        #expect(i3.getString() == nil)
        #expect(i3.getInt8(0) == nil)
        #expect(i3.getInt16(0) == nil)
        #expect(i3.getInt32(0) == nil)
        #expect(i3.getInt64(0) == nil)
        #expect(i3.getUInt8(0) == nil)
        #expect(i3.getUInt16(0) == nil)
        #expect(i3.getUInt32(0) == 1)
        #expect(i3.getUInt64(0) == nil)
        #expect(i3.getFloat(0) == nil)
        #expect(i3.getDouble(0) == nil)
        
        #expect((i3.value as? [UInt32]) == [1, 2, 3])
        #expect(i3.data == Data([0xB1, 0x0C,
                                 0x00, 0x00, 0x00, 0x01,
                                 0x00, 0x00, 0x00, 0x02,
                                 0x00, 0x00, 0x00, 0x03]))
        #expect((i3.getAny() as? [UInt32]) == [1, 2, 3])
        #expect((i3.getAny(0) as? UInt32) == 1)
        #expect((i3.getAny(3) as? UInt32) == nil)
        #expect((i3.getAny(0, 0) as? UInt32) == nil)
        #expect(i3.smlString == "<U4 [3] 1 2 3 >")
        
        let il = builder.build(list: [i0, i3])
        #expect(il.getUInt32(1, 0) == 1)
        #expect(il.getUInt32(1, 1) == 2)
        #expect(il.getUInt32(1, 2) == 3)
        #expect(il.getUInt32(1, 3) == nil)
        #expect(il.getUInt32(1, 0, 0) == nil)
        #expect(il.data == Data([0x01, 0x02,
                                 0xB1, 0x00,
                                 0xB1, 0x0C,
                                 0x00, 0x00, 0x00, 0x01,
                                 0x00, 0x00, 0x00, 0x02,
                                 0x00, 0x00, 0x00, 0x03]))
    }
    
    @Test func testBuildUInt8() async throws {
        
        let builder = SECS2BodyBuilder.shared
        
        let i0 = builder.build(uint8: [])
        #expect(i0.type == .uint8)
        #expect(i0.count == 0)
        #expect(i0.getInt64(0) == nil)
        #expect(i0.data == Data([0xA1, 0x00]))
        #expect(i0.smlString == "<U8 [0] >")
        
        var a0: [UInt64] = []
        for v in i0 {
            a0.append(v as! UInt64)
        }
        #expect(a0.count == 0)
        
        let i3 = builder.build(uint8: [1, 2, 3])
        #expect(i3.type == .uint8)
        #expect(i3.count == 3)
        #expect(i3.getUInt64(0) == 1)
        #expect(i3.getUInt64(1) == 2)
        #expect(i3.getUInt64(2) == 3)
        #expect(i3.getUInt64(3) == nil)
        #expect(i3.getUInt64(0, 0) == nil)
        #expect((i3[0] as? UInt64) == 1)
        
        var a3: [UInt64] = []
        for v in i3 {
            a3.append(v as! UInt64)
        }
        #expect(a3 == [1, 2, 3])
        
        #expect(i3.getSECS2Body(0) == nil)
        #expect(i3.getBool(0) == nil)
        #expect(i3.getString() == nil)
        #expect(i3.getInt8(0) == nil)
        #expect(i3.getInt16(0) == nil)
        #expect(i3.getInt32(0) == nil)
        #expect(i3.getInt64(0) == nil)
        #expect(i3.getUInt8(0) == nil)
        #expect(i3.getUInt16(0) == nil)
        #expect(i3.getUInt32(0) == nil)
        #expect(i3.getUInt64(0) == 1)
        #expect(i3.getFloat(0) == nil)
        #expect(i3.getDouble(0) == nil)
        
        #expect((i3.value as? [UInt64]) == [1, 2, 3])
        #expect(i3.data == Data([0xA1, 0x18,
                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02,
                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03]))
        #expect((i3.getAny() as? [UInt64]) == [1, 2, 3])
        #expect((i3.getAny(0) as? UInt64) == 1)
        #expect((i3.getAny(3) as? UInt64) == nil)
        #expect((i3.getAny(0, 0) as? UInt64) == nil)
        #expect(i3.smlString == "<U8 [3] 1 2 3 >")
        
        let il = builder.build(list: [i0, i3])
        #expect(il.getUInt64(1, 0) == 1)
        #expect(il.getUInt64(1, 1) == 2)
        #expect(il.getUInt64(1, 2) == 3)
        #expect(il.getUInt64(1, 3) == nil)
        #expect(il.getUInt64(1, 0, 0) == nil)
        #expect(il.data == Data([0x01, 0x02,
                                 0xA1, 0x00,
                                 0xA1, 0x18,
                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02,
                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03]))
    }
    
    @Test func testBuildFloat4() async throws {
        
        let builder = SECS2BodyBuilder.shared
        
        let i0 = builder.build(float4: [])
        #expect(i0.type == .float4)
        #expect(i0.count == 0)
        #expect(i0.getFloat(0) == nil)
        #expect(i0.data == Data([0x91, 0x00]))
        #expect(i0.smlString == "<F4 [0] >")
        
        var a0: [Float] = []
        for v in i0 {
            a0.append(v as! Float)
        }
        #expect(a0.count == 0)
        
        let i3 = builder.build(float4: [1.0, 2.0, 3.0])
        #expect(i3.type == .float4)
        #expect(i3.count == 3)
        #expect(i3.getFloat(0) == 1.0)
        #expect(i3.getFloat(1) == 2.0)
        #expect(i3.getFloat(2) == 3.0)
        #expect(i3.getFloat(3) == nil)
        #expect(i3.getFloat(0, 0) == nil)
        #expect((i3[0] as? Float) == 1.0)
        
        var a3: [Float] = []
        for v in i3 {
            a3.append(v as! Float)
        }
        #expect(a3 == [1.0, 2.0, 3.0])
        
        #expect(i3.getSECS2Body(0) == nil)
        #expect(i3.getBool(0) == nil)
        #expect(i3.getString() == nil)
        #expect(i3.getInt8(0) == nil)
        #expect(i3.getInt16(0) == nil)
        #expect(i3.getInt32(0) == nil)
        #expect(i3.getInt64(0) == nil)
        #expect(i3.getUInt8(0) == nil)
        #expect(i3.getUInt16(0) == nil)
        #expect(i3.getUInt32(0) == nil)
        #expect(i3.getUInt64(0) == nil)
        #expect(i3.getFloat(0) == 1.0)
        #expect(i3.getDouble(0) == nil)
        
        #expect((i3.value as? [Float]) == [1.0, 2.0, 3.0])
        #expect(i3.data == Data([0x91, 0x0C,
                                 0x3F, 0x80, 0x00, 0x00,
                                 0x40, 0x00, 0x00, 0x00,
                                 0x40, 0x40, 0x00, 0x00]))
        #expect((i3.getAny() as? [Float]) == [1.0, 2.0, 3.0])
        #expect((i3.getAny(0) as? Float) == 1.0)
        #expect((i3.getAny(3) as? Float) == nil)
        #expect((i3.getAny(0, 0) as? Float) == nil)
        print(i3.smlString)
        //#expect(i3.smlString == "<F4 [3] 1 2 3 >")
        
        let il = builder.build(list: [i0, i3])
        #expect(il.getFloat(1, 0) == 1.0)
        #expect(il.getFloat(1, 1) == 2.0)
        #expect(il.getFloat(1, 2) == 3.0)
        #expect(il.getFloat(1, 3) == nil)
        #expect(il.getFloat(1, 0, 0) == nil)
        #expect(il.data == Data([0x01, 0x02,
                                 0x91, 0x00,
                                 0x91, 0x0C,
                                 0x3F, 0x80, 0x00, 0x00,
                                 0x40, 0x00, 0x00, 0x00,
                                 0x40, 0x40, 0x00, 0x00]))
    }
    
    @Test func testBuildFloat8() async throws {
        
        let builder = SECS2BodyBuilder.shared
        
        let i0 = builder.build(float8: [])
        #expect(i0.type == .float8)
        #expect(i0.count == 0)
        #expect(i0.getDouble(0) == nil)
        #expect(i0.data == Data([0x81, 0x00]))
        #expect(i0.smlString == "<F8 [0] >")
        
        var a0: [Double] = []
        for v in i0 {
            a0.append(v as! Double)
        }
        #expect(a0.count == 0)
        
        let i3 = builder.build(float8: [1.0, 2.0, 3.0])
        #expect(i3.type == .float8)
        #expect(i3.count == 3)
        #expect(i3.getDouble(0) == 1.0)
        #expect(i3.getDouble(1) == 2.0)
        #expect(i3.getDouble(2) == 3.0)
        #expect(i3.getDouble(3) == nil)
        #expect(i3.getDouble(0, 0) == nil)
        #expect((i3[0] as? Double) == 1.0)
        
        var a3: [Double] = []
        for v in i3 {
            a3.append(v as! Double)
        }
        #expect(a3 == [1.0, 2.0, 3.0])
        
        #expect(i3.getSECS2Body(0) == nil)
        #expect(i3.getBool(0) == nil)
        #expect(i3.getString() == nil)
        #expect(i3.getInt8(0) == nil)
        #expect(i3.getInt16(0) == nil)
        #expect(i3.getInt32(0) == nil)
        #expect(i3.getInt64(0) == nil)
        #expect(i3.getUInt8(0) == nil)
        #expect(i3.getUInt16(0) == nil)
        #expect(i3.getUInt32(0) == nil)
        #expect(i3.getUInt64(0) == nil)
        #expect(i3.getFloat(0) == nil)
        #expect(i3.getDouble(0) == 1.0)
        
        #expect((i3.value as? [Double]) == [1.0, 2.0, 3.0])
        #expect(i3.data == Data([0x81, 0x18,
                                 0x3F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                 0x40, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))
        #expect((i3.getAny() as? [Double]) == [1.0, 2.0, 3.0])
        #expect((i3.getAny(0) as? Double) == 1.0)
        #expect((i3.getAny(3) as? Double) == nil)
        #expect((i3.getAny(0, 0) as? Double) == nil)
        print(i3.smlString)
        //#expect(i3.smlString == "<F4 [3] 1 2 3 >")
        
        let il = builder.build(list: [i0, i3])
        #expect(il.getDouble(1, 0) == 1.0)
        #expect(il.getDouble(1, 1) == 2.0)
        #expect(il.getDouble(1, 2) == 3.0)
        #expect(il.getDouble(1, 3) == nil)
        #expect(il.getDouble(1, 0, 0) == nil)
        #expect(il.data == Data([0x01, 0x02,
                                 0x81, 0x00,
                                 0x81, 0x18,
                                 0x3F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                 0x40, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))
    }
    
}
