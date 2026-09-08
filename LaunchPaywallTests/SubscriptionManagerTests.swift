//
//  SubscriptionManagerTests.swift
//  LaunchPaywallTests
//
//  Created by LaunchApp Studio on 2026.
//

import Foundation
import Testing
@testable import LaunchPaywall

@MainActor
struct SubscriptionManagerTests {
    /// `isProMock` should force Pro on without any network or entitlement,
    /// which is what the SwiftUI previews rely on.
    @Test("isProMock unlocks Pro for previews")
    func proMockUnlocksPro() {
        let manager = SubscriptionManager(isProMock: true)
        #expect(manager.isProUser)
    }

    /// A freshly created manager with no entitlement and no debug override
    /// must report the user as not Pro.
    @Test("A default manager without entitlements is not Pro")
    func defaultManagerIsNotPro() {
        UserDefaults.standard.removeObject(forKey: "debugProUnlocked")
        let manager = SubscriptionManager()
        #expect(manager.isProUser == false)
    }

#if DEBUG
    /// The debug override should flip `isProUser` and persist the flag,
    /// then flip it back off when toggled again.
    @Test("toggleDebugPro unlocks, persists and re-locks Pro")
    func debugToggleControlsPro() {
        UserDefaults.standard.removeObject(forKey: "debugProUnlocked")
        let manager = SubscriptionManager()
        #expect(manager.isProUser == false)

        manager.toggleDebugPro()
        #expect(manager.debugProUnlocked)
        #expect(manager.isProUser)
        #expect(UserDefaults.standard.bool(forKey: "debugProUnlocked"))

        manager.toggleDebugPro()
        #expect(manager.debugProUnlocked == false)
        #expect(manager.isProUser == false)
        #expect(UserDefaults.standard.bool(forKey: "debugProUnlocked") == false)

        UserDefaults.standard.removeObject(forKey: "debugProUnlocked")
    }
#endif
}
