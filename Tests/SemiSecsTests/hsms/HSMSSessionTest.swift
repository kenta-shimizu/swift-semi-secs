//
//  HSMSSessionTest.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/05/04.
//

import Testing
import Foundation
@testable import SemiSecs

struct HSMSSessionTest {

    @Test func testSessionId() async throws {
        
        let sessionId: UInt16 = 100
        
        let session = HSMSSession()
        
        let messageBuilder = HSMSSSMessageBuilder()
        messageBuilder.isEquipment = { return true }
        
        let transactor = HSMSMessageTransactor()
        transactor.timeoutT3 = { return 45.0 }
        transactor.timeoutT6 = { return  5.0 }
        transactor.onWillSendMessage = { _, _ in
        }
        transactor.onDidReceiveMessage = { _, _ in
        }
        
        session.hsmsSessionId = { return sessionId }
        session.hsmsMessageBuilder = { return messageBuilder }
        session.hsmsMessageTransactor = { return transactor }
        
        await session.start()
        
        #expect(session.sessionId == sessionId)
        
        await session.shutdown()
    }
    
    // tests
    // state

}
