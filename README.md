# Swift-SEMI-SECS

SEMI-SECS for Swift6 Package

## Introduction

This package is SEMI-SECS-communicate implementation on Swift6.

## Supports

- SECS-II (E5)
- HSMS-SS (E37.1)
- [SML (PEER Group)](https://www.peergroup.com/expertise/resources/secs-message-language/)

## Setup

building...

## Create Communicator instance and start

- HSMS-SS Active

```swift
let active = HSMSSSCommunicator()
active.config.connectionMode = .active
active.config.ipAddress = "127.0.0.1"
active.config.port = 5000
active.config.isEquipment = false
active.config.sessionId = 10
active.config.timeout.t3 = .seconds(45.0)
active.config.timeout.t5 = .seconds(10.0)
active.config.timeout.t6 = .seconds( 5.0)
active.config.timeout.t8 = .seconds( 6.0)
active.config.autoLinktest = true
active.config.linktestDuration = .seconds(120.0)

try active.start()
```

- HSMS-SS Passive

```swift
let passive = HSMSSSCommunicator()
passive.config.connectionMode = .passive
passive.config.port = 5000
passive.config.isEquipment = true
passive.config.sessionId = 10
passive.config.timeout.t3 = .seconds(45.0)
passive.config.timeout.t6 = .seconds( 5.0)
passive.config.timeout.t7 = .seconds(10.0)
passive.config.timeout.t8 = .seconds( 6.0)
passive.config.autoLinktest = false
passive.config.rebindDuration = .seconds(10.0)

try passive.start()
```

### shutdown


## Send primary-maessage and receive response-message.

building...

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

## SML

building...

## GEM

building...
