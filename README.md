# Swift-SEMI-SECS

SEMI-SECS for Swift6 Package

## Introduction

This package is SEMI-SECS communication implementation on Swift6.

## Supports

- SECS-II (E5)
- HSMS-SS (E37.1)
- [SML (PEER Group)](https://www.peergroup.com/expertise/resources/secs-message-language/)

## Setup

### Xcode

1. **File** > **Add Package Dependencies...**
2. Paste: `https://github.com/kenta-shimizu/swift-semi-secs`

### Usage

```swift
import SemiSecs
```

## Create Communicator instance and start

### HSMS-SS Active

```swift
let host = HSMSSSCommunicator()
host.config.connectionMode   = .active
host.config.ipAddress        = "127.0.0.1"
host.config.port             = 5000
host.config.isEquipment      = false
host.config.sessionId        = 10
host.config.timeout.t3       = .seconds(45.0)
host.config.timeout.t5       = .seconds(10.0)
host.config.timeout.t6       = .seconds( 5.0)
host.config.timeout.t8       = .seconds( 6.0)
host.config.autoLinktest     = true
host.config.linktestDuration = .seconds(120.0)

try host.start()
```

### HSMS-SS Passive

```swift
let equip = HSMSSSCommunicator()
equip.config.connectionMode = .passive
equip.config.port           = 5000
equip.config.isEquipment    = true
equip.config.sessionId      = 10
equip.config.timeout.t3     = .seconds(45.0)
equip.config.timeout.t6     = .seconds( 5.0)
equip.config.timeout.t7     = .seconds(10.0)
equip.config.timeout.t8     = .seconds( 6.0)
equip.config.autoLinktest   = false
equip.config.rebindDuration = .seconds(10.0)

try equip.start()
```

### Shutdown

Cancel communication. Release all resources. Cannot be restarted after shutdown.

```swift
host.shutdown()
```

## Send primary-message and await response-message.

1. Create SECS-II-Body

```swift
let secs2Body =
SECS2Body(list: [                       // <L
    SECS2Body(binary: Data([0x81])),    //     <B  0x81 >
    SECS2Body(uint4:  [1001]),          //     <U4 1001 >
    SECS2Body(ascii:  "ON FIRE")        //     <A  "ON FIRE" >
])                                      // >
```

2. Send message

```swift
let response = try await equip.send(
    stream:    5,           // Stream-Number
    function:  1,           // Function-Number
    wbit:      true,        // W-Bit
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
host.didReceivePrimaryDataSECSMessage = { primaryMessage in
    let stream    = primaryMessage.stream       // Stream-Number
    let function  = primaryMessage.function     // Function-Number
    let wbit      = primaryMessage.wbit         // W-Bit
    let secs2Body = primaryMessage.secs2Body    // SECS-II-Body
}
```

2. Parse SECS-II

```swift
/* example receive message */
S5F1 W
<L [3]
    <B  [1] 0x81>       // ALCD (0, 0)
    <U4 [1] 1001>       // ALID (1, 0)
    <A  "ON FIRE">      // ALTX (2)
>. 

if let secs2Body = primaryMessage.secs2Body {
    let alcd: UInt8?  = secs2Body.uint8Value(at: 0, 0)
    let alid: UInt32? = secs2Body.uint32Value(at: 1, 0)
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
try await host.reply(
    primaryMessage: primaryMessage,
    stream:         5,
    function:       2,
    wbit:           false,
    secs2Body:      SECS2Body(binary: Data([0x00]))
)
```

## Detect communication state

### Set handler

```swift
host.didUpdateCommunicationState = { communicating in
    print("communicating is \(communicating)")
}
```

### Wait until communicating

```swift
try await host.untilCommunicating()
```

## SML

### Send SML

```swift
let smlMessageString = """
    S5F1 W
    <L
        <B  0x81>
        <U4 1001>
        <A  "ON FIRE">
    >.
"""

if let smlMessage = try? SMLMessageParser.shared.parse(smlMessageString) {
    let response = try await equip.send(smlMessage: smlMessage)
}
```

### Reply SML

```swift
if let smlMessage = try? SMLMessageParser.shared.parse("S5F2 <B 0x00>.") {
    try await host.reply(
        primaryMessage: primaryMessage,
        smlMessage:     smlMessage
    )
}
```

## GEM

### Establish Communications

```swift
// Equipment receive S1F13 and reply S1F14
equip.didReceivePrimaryDataSECSMessage = { primaryMessage in
    Task {
        if primaryMessage.stream == 1 &&
            primaryMessage.function == 13 &&
            primaryMessage.wbit {
            
            do {
                // reply S1F14
                try await equip.gem.s1f14(
                    primaryMessage: primaryMessage,
                    commack: .accepted,
                    mdln: "MDLN-A",
                    softrev: "000001")
                    
            }
            catch {
                // error
            }
        }
    }
}

// Host send S1F13 and receive S1F14 COMMACK
let commack: GEM.COMMACK = try await host.gem.s1f13()
```

### Control State

```swift
// Equipment receive primary-message and reply message.
equip.didReceivePrimaryDataSECSMessage = { primaryMessage in
    Task {
        do {
            switch primaryMessage.stream {
            case 1:
                switch primaryMessage.function {
                case 1:
                    if primaryMessage.wbit {
                        // reply S1F2
                        try await equip.gem.s1f2(
                            primaryMessage: primaryMessage,
                            mdln: "MDLN-A",
                            softrev: "000001")
                    }
                case 15:
                    if primaryMessage.wbit {
                        // reply S1F16
                        try await equip.gem.s1f16(
                            primaryMessage: primaryMessage,
                            oflack: .acknowledge)
                    }
                case 17:
                    if primaryMessage.wbit {
                        // reply S1F18
                        try await equip.gem.s1f18(
                            primaryMessage: primaryMessage,
                            onlack: .accepted)
                    }
                default:
                    break
                }
            default:
                break
            }
        }
        catch {
            // error
        }
    }
}

// Host send message and await response
let onlack: GEM.ONLACK = try await host.gem.s1f17()
let s1f2 = try await host.gem.s1f1()
let oflack: GEM.OFLACK = try await host.gem.s1f15()
```

### Clock

```swift
// Host receive S2F17 and reply S2F18
host.didReceivePrimaryDataSECSMessage = { primaryMessage in
    Task {
        if primaryMessage.stream == 2 &&
            primaryMessage.function == 17 &&
            primaryMessage.wbit {
            
            do {
                // reply S2F18
                try await host.gem.s2f18Now(
                    primaryMessage: primaryMessage,
                    clockType: .a16)
            }
            catch {
                // error
            }
        }
    }
}

// Equipment send S2F17 and receive S2F18 Date
let date: Date = try await equip.gem.s2f17()
```

```swift
// Equipment receive S2F31 and reply S2F32
equip.didReceivePrimaryDataSECSMessage = { primaryMessage in
    Task {
        if primaryMessage.stream == 2 &&
            primaryMessage.function == 31 &&
            primaryMessage.wbit {
            
            do {
                // parse from String to Date
                guard let string = primaryMessage.secs2Body?.stringValue(),
                      let date: Date = GEM.Clock.date(from: string) else {
                    try await equip.gem.s2f32(
                        primaryMessage: primaryMessage,
                        tiack: .notAccepted)
                    return
                }
                
                // reply S2F32
                try await equip.gem.s2f32(
                    primaryMessage: primaryMessage,
                    tiack: .ok)
            }
            catch {
                // error
            }
        }
    }
}

// Host send S2F31 and receive S2F32 TIACK
let tiack: GEM.TIACK = try await host.gem.s2f31Now(clockType: .a16)
```

### System Errors

```swift
try await equip.gem.s9f1(referenceMessage: primaryMessage)
try await equip.gem.s9f3(referenceMessage: primaryMessage)
try await equip.gem.s9f5(referenceMessage: primaryMessage)
try await equip.gem.s9f7(referenceMessage: primaryMessage)
try await equip.gem.s9f9(referenceMessage: message)
try await equip.gem.s9f11(referenceMessage: message)
```
