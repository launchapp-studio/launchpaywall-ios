//
//  TelemetryServiceTests.swift
//  LaunchPaywallTests
//
//  Created by LaunchApp Studio on 2026.
//

import Testing
@testable import LaunchPaywall

struct TelemetryServiceTests {
    /// The event raw values are the wire keys sent to the analytics backend,
    /// so they must remain stable snake_case strings.
    @Test("Event raw values map to stable analytics keys")
    func eventRawValues() {
        #expect(TelemetryService.Event.paywallImpression.rawValue == "paywall_impression")
        #expect(TelemetryService.Event.purchaseStarted.rawValue == "purchase_started")
        #expect(TelemetryService.Event.purchaseSuccess.rawValue == "purchase_success")
        #expect(TelemetryService.Event.purchaseFailed.rawValue == "purchase_failed")
        #expect(TelemetryService.Event.restoreStarted.rawValue == "restore_started")
        #expect(TelemetryService.Event.restoreSuccess.rawValue == "restore_success")
        #expect(TelemetryService.Event.restoreFailed.rawValue == "restore_failed")
        #expect(TelemetryService.Event.signInStarted.rawValue == "sign_in_started")
        #expect(TelemetryService.Event.signInSuccess.rawValue == "sign_in_success")
        #expect(TelemetryService.Event.signInFailed.rawValue == "sign_in_failed")
    }
}
