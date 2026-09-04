//
//  AppConfig.swift
//  LaunchPaywall
//
//  Created by LaunchApp Studio on 2026.
//

import Foundation

/// Centralized, immutable configuration for the app's third-party services.
/// Replace the placeholder values with your real credentials before shipping.
enum AppConfig {
    /// RevenueCat public SDK API key (found in the RevenueCat dashboard).
    static let revenueCatAPIKey = "appl_YOUR_REVENUECAT_PUBLIC_SDK_KEY"

    /// TelemetryDeck application identifier used to route anonymous analytics.
    static let telemetryDeckAppID = "YOUR_TELEMETRYDECK_APP_ID"

    /// Entitlement identifier configured in RevenueCat that unlocks pro features.
    static let entitlementID = "pro_access"

    /// Public-facing legal URLs surfaced in the paywall and settings.
    static let privacyPolicyURL = URL(string: "https://example.com/privacy")!
    static let termsOfServiceURL = URL(string: "https://example.com/terms")!
}
