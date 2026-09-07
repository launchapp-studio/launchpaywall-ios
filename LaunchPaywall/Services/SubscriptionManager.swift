//
//  SubscriptionManager.swift
//  LaunchPaywall
//
//  Created by LaunchApp Studio on 2026.
//

import Foundation
import RevenueCat

// MARK: - Testing purchases in the simulator with StoreKit
//
// To test purchases WITHOUT connecting to App Store Connect, add a
// StoreKit Configuration File and enable it in the scheme:
//
// 1. Xcode > File > New > File from Template… > search "StoreKit Configuration File".
//    Save it (e.g. "Products.storekit") inside the LaunchPaywall target.
// 2. Open it and tap "+" to create products: use auto-renewable subscriptions
//    with the SAME Product IDs you configured in RevenueCat / App Store Connect
//    (e.g. "com.launchpaywall.pro.annual" and ".monthly").
// 3. Product > Scheme > Edit Scheme… > Run > Options tab >
//    "StoreKit Configuration" > select your .storekit file.
// 4. Run in the simulator: purchases resolve locally and RevenueCat
//    recognizes them in sandbox/StoreKit mode with no real charges.
// 5. To reset state: Debug > StoreKit > Manage Transactions… (delete purchases).
//
// Note: the .storekit file is for development only; in production products
// come from App Store Connect.

/// Errors surfaced by the subscription / purchase flow.
enum SubscriptionError: LocalizedError {
    case notConfigured
    case noOfferings
    case purchaseCancelled
    case purchaseFailed(underlying: Error)
    case restoreFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "RevenueCat has not been configured yet."
        case .noOfferings:
            return "No offerings are currently available."
        case .purchaseCancelled:
            return "The purchase was cancelled."
        case .purchaseFailed(let underlying):
            return "Purchase failed: \(underlying.localizedDescription)"
        case .restoreFailed(let underlying):
            return "Restore failed: \(underlying.localizedDescription)"
        }
    }
}

/// Manages RevenueCat configuration, offerings, purchases and entitlement state.
/// Observable so SwiftUI paywalls react to changes in `isProUser` and offerings.
@Observable
@MainActor
final class SubscriptionManager {
    // MARK: - Published state

    /// The current offerings fetched from RevenueCat, if any.
    private(set) var offerings: Offerings?
    /// The latest known customer info snapshot.
    private(set) var customerInfo: CustomerInfo?
    /// True while a network operation (fetch/purchase/restore) is in flight.
    private(set) var isBusy = false

    private var isConfigured = false

    /// When true, forces `isProUser` on for SwiftUI previews (no network).
    private let isProMock: Bool

#if DEBUG
    /// Unlocks Pro locally after a simulated purchase while prototyping,
    /// even when the RevenueCat entitlement is not yet mapped in the dashboard.
    private(set) var debugProUnlocked = UserDefaults.standard.bool(forKey: "debugProUnlocked")
#endif

    /// - Parameter isProMock: Simulates an active Pro entitlement for the Canvas.
    init(isProMock: Bool = false) {
        self.isProMock = isProMock
    }

    // MARK: - Derived state

    /// Whether the user currently owns an active "pro_access" entitlement.
    var isProUser: Bool {
        if isProMock { return true }
        #if DEBUG
        if debugProUnlocked { return true }
        #endif
        return customerInfo?.entitlements[AppConfig.entitlementID]?.isActive == true
    }

    // MARK: - Configuration

    /// Configures the RevenueCat SDK. Safe to call once at app launch.
    /// - Parameter appUserID: Optional stable identifier to align RevenueCat with your auth system.
    func configure(appUserID: String? = nil) {
        guard !isConfigured else { return }

        Purchases.logLevel = .info
        Purchases.configure(
            with: Configuration.Builder(withAPIKey: AppConfig.revenueCatAPIKey)
                .with(appUserID: appUserID)
                .build()
        )
        isConfigured = true

        // Prime local state with the current customer info in the background.
        Task { await refreshCustomerInfo() }
    }

    // MARK: - Offerings

    /// Fetches the available offerings from RevenueCat.
    @discardableResult
    func fetchOfferings() async throws -> Offerings {
        try ensureConfigured()
        isBusy = true
        defer { isBusy = false }

        do {
            let fetched = try await Purchases.shared.offerings()
            offerings = fetched
            guard fetched.current != nil else { throw SubscriptionError.noOfferings }
            return fetched
        } catch let error as SubscriptionError {
            throw error
        } catch {
            throw SubscriptionError.purchaseFailed(underlying: error)
        }
    }

    // MARK: - Purchase

    /// Purchases the given package and updates entitlement state on success.
    func purchase(package: Package) async throws {
        try ensureConfigured()
        TelemetryService.log(.purchaseStarted, parameters: ["package": package.identifier])
        isBusy = true
        defer { isBusy = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled {
                TelemetryService.log(.purchaseFailed, parameters: ["reason": "user_cancelled"])
                throw SubscriptionError.purchaseCancelled
            }
            customerInfo = result.customerInfo
            logEntitlementState(result.customerInfo, context: "purchase")
            #if DEBUG
            // Prototype flow: a successful simulated purchase unlocks Pro even
            // if the entitlement is not mapped on the RevenueCat dashboard yet.
            debugProUnlocked = true
            UserDefaults.standard.set(true, forKey: "debugProUnlocked")
            #endif
            TelemetryService.log(.purchaseSuccess, parameters: ["package": package.identifier])
        } catch let error as SubscriptionError {
            throw error
        } catch {
            TelemetryService.log(.purchaseFailed, parameters: ["reason": String(describing: error)])
            throw SubscriptionError.purchaseFailed(underlying: error)
        }
    }

    // MARK: - Restore

    /// Restores previous purchases and refreshes entitlement state.
    func restorePurchases() async throws {
        try ensureConfigured()
        TelemetryService.log(.restoreStarted)
        isBusy = true
        defer { isBusy = false }

        do {
            let info = try await Purchases.shared.restorePurchases()
            customerInfo = info
            TelemetryService.log(.restoreSuccess)
        } catch {
            TelemetryService.log(.restoreFailed, parameters: ["reason": String(describing: error)])
            throw SubscriptionError.restoreFailed(underlying: error)
        }
    }

    // MARK: - Identity Management

    /// Binds RevenueCat purchases to the authenticated Apple User ID.
    func logIn(appUserID: String) async throws {
        try ensureConfigured()
        let result = try await Purchases.shared.logIn(appUserID)
        customerInfo = result.customerInfo
    }

    /// Unbinds the current user session in RevenueCat on sign out.
    func logOut() async throws {
        try ensureConfigured()
        let info = try await Purchases.shared.logOut()
        customerInfo = info
    }

    // MARK: - Helpers

    /// Refreshes the cached customer info without throwing (best-effort).
    private func refreshCustomerInfo() async {
        guard isConfigured else { return }
        customerInfo = try? await Purchases.shared.customerInfo()
    }

    /// Guards operations that require the SDK to be configured first.
    private func ensureConfigured() throws {
        guard isConfigured else { throw SubscriptionError.notConfigured }
    }

    /// Logs which entitlements RevenueCat returned so mismatches between the
    /// configured `pro_access` entitlement and the dashboard are easy to spot.
    private func logEntitlementState(_ info: CustomerInfo, context: String) {
        #if DEBUG
        let active = info.entitlements.active.keys.sorted().joined(separator: ", ")
        let all = info.entitlements.all.keys.sorted().joined(separator: ", ")
        let expected = AppConfig.entitlementID
        let isActive = info.entitlements[expected]?.isActive == true
        print("""
        [RevenueCat][\(context)] expected='\(expected)' active=\(isActive) \
        activeKeys=[\(active)] allKeys=[\(all)]
        """)
        #endif
    }

#if DEBUG
    func toggleDebugPro() {
        debugProUnlocked.toggle()
        UserDefaults.standard.set(debugProUnlocked, forKey: "debugProUnlocked")
    }
#endif
}
