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

### Shutdown

Cancel communication. Release all resources. Cannot be restarted after shutdowned.

```swift
active.shutdown()
```

## Send primary-maessage and await response-message.

1. Create SECS-II-Body

```swift
let builder = SECS2BodyBuilder.shared

let secs2Body =
builder.build(list: [                       // <L
    builder.build(binary: Data([0x81])),    //   <B  0x81 >
    builder.build(uint2:  [1001]),          //   <U2 1001 >
    builder.build(ascii:  "ON FIRE")        //   <A "ON FIRE" >
])                                          // >
```

2. Send message

```swift
let response = try await passive.send(
    stream: 5,              // Stream-Number
    function: 1,            // Function-Number
    wbit: true,             // W-Bit
    secs2Body: secs2Body    // SECS-II-Body
)
```

3. Await response message

The response message is Optional.  
It contains a value if W-Bit is true, and is nil if W-Bit is false.  
If T3-Timeout, throw SECSWaitReplyError.  

```swift
if let response = response {
    let stream   = response.stream
    let function = response.function
    let wbit     = response.wbit
    if let secs2Body = response.secs2Body {
        // something...
    }
}
```

## Receive primary-message and reply message

1. Set handler

```swift
active.didReceivePrimaryDataSECSMessage = { primaryMessage in
    let stream = primaryMessage.stream          // Stream-Number
    let function = primaryMessage.function      // Function-Number
    let wbit = primaryMessage.wbit              // W-Bit
    let secs2Body = primaryMessage.secs2Body    // SECS-II-Body
}
```

2. Parse SECS-II

```swift
/* example receive message */
S5F1 W
<L [3]
    <B  [1] 0x81>           // ALCD (0, 0)
    <U2 [1] 1001>           // ALID (1, 0)
    <A  "ON FIRE">          // ALTX (2)
>. 

if let secs2Body = primaryMessage.secs2Body {
    let alid: UInt8?  = secs2Body.uint8Value(at: 0, 0)
    let alcd: UInt16? = secs2Body.uint16Value(at: 1, 0)
    let altx: String? = secs2Body.stringValue(at: 2)
}
```

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

3. Reply message

```swift
try await active.reply(
    primaryMessage: primaryMessage,
    stream: 5,
    function: 2,
    wbit: false,
    secs2Body: SECS2BodyBuilder.shared.build(binary: Data([0x00]))
)
```

## state

building...

// Wait until the status updates to Communicating.

## SML

building...

## GEM

building...
