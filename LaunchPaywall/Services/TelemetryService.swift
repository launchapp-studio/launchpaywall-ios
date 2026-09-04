//
//  TelemetryService.swift
//  LaunchPaywall
//
//  Created by LaunchApp Studio on 2026.
//

import Foundation
import OSLog

/// Lightweight, static abstraction for recording anonymous analytics events.
///
/// This wrapper deliberately hides the concrete analytics backend (e.g. TelemetryDeck)
/// behind a small surface so the rest of the app depends only on a stable API.
/// Swap the body of `send(_:parameters:)` to plug in the real SDK.
enum TelemetryService {
    /// Strongly-typed catalogue of the anonymous events the app can emit.
    enum Event: String {
        case paywallImpression = "paywall_impression"
        case purchaseStarted = "purchase_started"
        case purchaseSuccess = "purchase_success"
        case purchaseFailed = "purchase_failed"
        case restoreStarted = "restore_started"
        case restoreSuccess = "restore_success"
        case restoreFailed = "restore_failed"
        case signInStarted = "sign_in_started"
        case signInSuccess = "sign_in_success"
        case signInFailed = "sign_in_failed"
    }

    private static let logger = Logger(subsystem: "com.launchpaywall.telemetry", category: "analytics")

    /// Records a single anonymous event with optional string parameters.
    /// - Parameters:
    ///   - event: The predefined event to record.
    ///   - parameters: Optional, non-identifying metadata (avoid PII).
    static func log(_ event: Event, parameters: [String: String] = [:]) {
        send(event.rawValue, parameters: parameters)
    }

    /// Internal dispatch point. Replace the implementation to forward events
    /// to TelemetryDeck (or any other backend) while keeping the public API stable.
    private static func send(_ signal: String, parameters: [String: String]) {
        // TODO: forward to TelemetryDeck using AppConfig.telemetryDeckAppID.
        // Kept as a structured log during development so events are observable.
        logger.info("📊 \(signal, privacy: .public) \(parameters.description, privacy: .public)")
    }
}
