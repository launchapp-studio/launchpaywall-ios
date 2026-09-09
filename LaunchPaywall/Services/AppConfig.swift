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
    /// Public-facing product name shown across the UI.
    static let appName = "LaunchPaywall"

    /// RevenueCat public SDK API key (found in the RevenueCat dashboard).
    static let revenueCatAPIKey = "appl_YOUR_REVENUECAT_PUBLIC_KEY"

    /// TelemetryDeck application identifier used to route anonymous analytics.
    static let telemetryDeckAppID = "YOUR_TELEMETRYDECK_APP_ID"

    /// Entitlement identifier configured in RevenueCat that unlocks pro features.
    static let entitlementID = "pro_access"

    /// Public-facing legal URLs surfaced in the paywall and settings.
    static let privacyPolicyURL = URL(string: "https://github.com/launchapp-studio/launchpaywall-ios/blob/main/PRIVACY.md")!
    static let termsOfServiceURL = URL(string: "https://github.com/launchapp-studio/launchpaywall-ios/blob/main/TERMS.md")!
}
