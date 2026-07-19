//
//  HSMSMessageAndNWConnection.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/06/14.
//

import Foundation
import Network

/// pair of HSMSMessage and NWConnection
internal struct HSMSMessageAndNWConnection: Hashable {
    
    internal let message: HSMSMessage
    internal let connection: NWConnection
    
    internal init(message: HSMSMessage, connection: NWConnection) {
        self.message = message
        self.connection = connection
    }
    
    static func == (lhs: HSMSMessageAndNWConnection, rhs: HSMSMessageAndNWConnection) -> Bool {
        return lhs.message.system4BytesKeyValue == rhs.message.system4BytesKeyValue && lhs.connection === rhs.connection
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.message.system4BytesKeyValue)
    }

}
