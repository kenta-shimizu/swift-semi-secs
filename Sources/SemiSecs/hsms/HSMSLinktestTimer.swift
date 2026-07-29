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
    private var timerTask: Task<Void, Never>?
    
    internal nonisolated(unsafe) var autoLinktest: (() -> Bool)?
    internal nonisolated(unsafe) var linktestDuration: (() -> Duration)?
    internal nonisolated(unsafe) var linktest: (() -> Void)?
    
    internal init() {
        self.started = false
        self.shutdowned = false
        self.timerTask = nil
        self.autoLinktest = nil
        self.linktestDuration = nil
        self.linktest = nil
    }
    
    internal func start() async {
        guard self.shutdowned == false else { return }
        guard self.started == false else { return }
        self.started = true
        self.timerTask = self.newTask()
    }
    
    internal func reset() async {
        guard self.shutdowned == false else { return }
        guard self.started == true else { return }
        self.timerTask?.cancel()
        self.timerTask = self.newTask()
    }
    
    internal func shutdown() async {
        guard self.shutdowned == false else { return }
        self.shutdowned = true
        self.timerTask?.cancel()
        self.timerTask = nil
        self.autoLinktest = nil
        self.linktestDuration = nil
        self.linktest = nil
    }
    
    private func newTask() -> Task<Void, Never> {
        return Task {
            guard self.autoLinktest!() else { return }
            do {
                while !Task.isCancelled {
                    try await Task.sleep(for: self.linktestDuration!())
                    try Task.checkCancellation()
                    self.linktest?()
                }
            }
            catch {
            }
        }
    }
    
}
