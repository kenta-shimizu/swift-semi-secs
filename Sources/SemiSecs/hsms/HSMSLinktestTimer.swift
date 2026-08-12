//
//  HSMSLinktestTimer.swift
//  swift-semi-secs
//
//  Created by kenta-shimizu on 2026/07/18.
//

import Foundation

internal actor HSMSLinktestTimer {
    
    private var started: Bool
    private var shutdowned: Bool
    
    private let reset = StateUpdateNotifier<Bool>(state: false)
    
    internal nonisolated(unsafe) var autoLinktest: (() -> Bool)?
    internal nonisolated(unsafe) var linktestDuration: (() -> Duration)?
    internal nonisolated(unsafe) var linktest: (() -> Void)?
    
    internal init() {
        self.started = false
        self.shutdowned = false
        self.autoLinktest = nil
        self.linktestDuration = nil
        self.linktest = nil
    }
    
    internal func start() async {
        guard self.shutdowned == false else { return }
        guard self.started == false else { return }
        self.started = true
        
        Task.detached {
            do {
                while !Task.isCancelled {
                    await self.reset.yield(false)
                    guard let funcAutoLinktest = self.autoLinktest else { return }
                    if funcAutoLinktest() {
                        guard let funcLinktestDuration = self.linktestDuration else { return }
                        let result = try await self.reset.until(true, timeout: funcLinktestDuration())
                        if result == false {
                            // timeout, do linktest.
                            self.linktest?()
                        }
                    } else {
                        // wait until reset
                        try await self.reset.until(true)
                    }
                }
            }
            catch {
                // nothing
            }
        }
    }
    
    internal func reset() async {
        guard self.shutdowned == false else { return }
        guard self.started == true else { return }
        await self.reset.yield(true)
    }
    
    internal func shutdown() async {
        guard self.shutdowned == false else { return }
        self.shutdowned = true
        await self.reset.shutdown()
        self.autoLinktest = nil
        self.linktestDuration = nil
        self.linktest = nil
    }
    
}
