//
//  SubscriptionManager.swift
//  LaunchPaywall
//
//  Created by LaunchApp Studio on 2026.
//

import Foundation
import RevenueCat

// MARK: - Probar compras en el simulador con StoreKit
//
// Para probar compras SIN conectarte a App Store Connect, añade un
// StoreKit Configuration File y actívalo en el scheme:
//
// 1. Xcode > File > New > File from Template… > busca "StoreKit Configuration File".
//    Guárdalo (p. ej. "Products.storekit") dentro del target LaunchPaywall.
// 2. Ábrelo y pulsa "+" para crear productos: usa auto-renewable subscriptions
//    con los MISMOS Product IDs que configuraste en RevenueCat / App Store Connect
//    (p. ej. "com.launchpaywall.pro.annual" y ".monthly").
// 3. Product > Scheme > Edit Scheme… > Run > pestaña Options >
//    "StoreKit Configuration" > selecciona tu archivo .storekit.
// 4. Ejecuta en el simulador: las compras se resolverán localmente y RevenueCat
//    las reconocerá en modo sandbox/StoreKit sin cargos reales.
// 5. Para reiniciar el estado: Debug > StoreKit > Manage Transactions… (borra compras).
//
// Nota: el archivo .storekit es solo para desarrollo; en producción los productos
// provienen de App Store Connect.

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

    /// - Parameter isProMock: Simulates an active Pro entitlement for the Canvas.
    init(isProMock: Bool = false) {
        self.isProMock = isProMock
    }

    // MARK: - Derived state

    /// Whether the user currently owns an active "pro_access" entitlement.
    var isProUser: Bool {
        if isProMock { return true }
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
}
