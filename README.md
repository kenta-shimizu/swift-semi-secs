# Swift-SEMI-SECS

SEMI-SECS for Swift Package

Building...

## Introduction

building...

This package is SEMI-SECS-communicate implementation on Swift6.

## Supports

- SECS-II (E5)
- HSMS-SS (E37.1)
- [SML (PEER Group)](https://www.peergroup.com/expertise/resources/secs-message-language/)

## Setup

building...

## Create Communicator instance and start

building...

### shutdown

## Send primary-maeesage and receive response-message.

buiding...

## Receive primary-message and reply message.

### Parse SECS-II

| method | B | BOOLEAN | A | I1 | I2 | I4 | I8 | U1 | U2 | U4 | U8 | F4 | F8 |
|:-|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| func boolValue(at:)   -> Bool?   |   | ✓ |   |   |   |   |   |   |   |   |   |   |   |
| func stringValue(at:) -> String? |   |   | ✓ |   |   |   |   |   |   |   |   |   |   |
| func int8Value(at:)   -> Int8?   |   |   |   | ✓ |   |   |   |   |   |   |   |   |   |
| func int16Value(at:)  -> Int16?  |   |   |   |   | ✓ |   |   |   |   |   |   |   |   |
| func int32Value(at:)  -> Int32?  |   |   |   |   |   | ✓ |   |   |   |   |   |   |   |
| func int64Value(at:)  -> Int64?  |   |   |   |   |   |   | ✓ |   |   |   |   |   |   |
| func uint8Value(at:)  -> UInt8?  | ✓ |   |   |   |   |   |   | ✓ |   |   |   |   |   |
| func uint16Value(at:) -> UInt16? |   |   |   |   |   |   |   |   | ✓ |   |   |   |   |
| func uint32Value(at:) -> UInt32? |   |   |   |   |   |   |   |   |   | ✓ |   |   |   |
| func uint64Value(at:) -> UInt64? |   |   |   |   |   |   |   |   |   |   | ✓ |   |   |
| func floatValue(at:)  -> Float?  |   |   |   |   |   |   |   |   |   |   |   | ✓ |   |
| func doubleValue(at:) -> Double? |   |   |   |   |   |   |   |   |   |   |   |   | ✓ |
| func anyValue(at:)    -> any?    | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

## GEM

building...
