//
//  PaywallView.swift
//  LaunchPaywall
//
//  Created by LaunchApp Studio on 2026.
//

import RevenueCat
import SwiftUI

/// High-conversion paywall presenting the current RevenueCat offering with an
/// annual (highlighted) and monthly plan, purchase and restore actions.
struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    /// Locally selected package the user intends to purchase.
    @State private var selectedPackage: Package?
    /// Identifier of the card currently snapped in the horizontal carousel.
    @State private var scrolledPackageID: String?
    /// Error message backing the failure alert.
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                header
                benefits
                planSelector
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 180)
        }
        .safeAreaInset(edge: .bottom) { footer }
        .background(backgroundGradient.ignoresSafeArea())
        .task { await loadOfferings() }
        .onAppear { TelemetryService.log(.paywallImpression) }
        .alert("No se pudo completar", isPresented: $showError) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Inténtalo de nuevo más tarde.")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(.tint)
                .padding(24)
                .background(.tint.opacity(0.12), in: Circle())

            Text("Desbloquea LaunchPaywall Pro")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Accede a todas las funciones premium sin límites.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Benefits

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 16) {
            BenefitRow(icon: "infinity", title: "Uso ilimitado",
                       subtitle: "Sin restricciones ni marcas de agua.")
            BenefitRow(icon: "bolt.fill", title: "Funciones avanzadas",
                       subtitle: "Herramientas exclusivas para usuarios Pro.")
            BenefitRow(icon: "lock.open.fill", title: "Prioridad y soporte",
                       subtitle: "Atención preferente y novedades antes que nadie.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Plan selector

    @ViewBuilder
    private var planSelector: some View {
        if subscriptions.isBusy && subscriptions.offerings == nil {
            ProgressView().controlSize(.large).padding(.vertical, 40)
        } else if let offering = subscriptions.offerings?.current,
                  !orderedPackages(offering).isEmpty {
            let packages = orderedPackages(offering)
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(packages, id: \.identifier) { package in
                        PlanCard(package: package,
                                 isSelected: selectedPackage?.identifier == package.identifier)
                            .containerRelativeFrame(.horizontal)
                            .id(package.identifier)
                            .onTapGesture {
                                withAnimation(.snappy) { scrolledPackageID = package.identifier }
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .safeAreaPadding(.horizontal, 32)
            .scrollPosition(id: $scrolledPackageID)
            .scrollIndicators(.hidden)
            .onChange(of: scrolledPackageID) { _, newID in
                // Keep the selected package in sync with the centered card.
                if let newID, let match = packages.first(where: { $0.identifier == newID }) {
                    selectedPackage = match
                }
            }
        } else {
            Text("No hay planes disponibles en este momento.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.vertical, 40)
        }
    }

    /// Orders the offering's packages as Annual, Monthly, Lifetime (available only).
    private func orderedPackages(_ offering: Offering) -> [Package] {
        [offering.annual, offering.monthly, offering.lifetime].compactMap { $0 }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 12) {
            Button(action: { Task { await purchaseSelected() } }) {
                ZStack {
                    if subscriptions.isBusy {
                        ProgressView().tint(.white)
                    } else {
                        Text("Continuar")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 26)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selectedPackage == nil || subscriptions.isBusy)

            Button("Restaurar compras") {
                Task { await restore() }
            }
            .font(.subheadline)
            .disabled(subscriptions.isBusy)

            HStack(spacing: 16) {
                Button("Política de privacidad") { openURL(AppConfig.privacyPolicyURL) }
                Text("·").foregroundStyle(.secondary)
                Button("Términos de servicio") { openURL(AppConfig.termsOfServiceURL) }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(.regularMaterial)
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(colors: [Color.accentColor.opacity(0.10), .clear],
                       startPoint: .top, endPoint: .center)
    }

    // MARK: - Actions

    /// Loads offerings and preselects the annual plan by default.
    private func loadOfferings() async {
        do {
            let offerings = try await subscriptions.fetchOfferings()
            if selectedPackage == nil, let current = offerings.current {
                // Prefer Annual, then Monthly, then Lifetime as the default.
                let initial = current.annual ?? current.monthly ?? current.lifetime
                selectedPackage = initial
                scrolledPackageID = initial?.identifier
            }
        } catch {
            present(error)
        }
    }

    /// Attempts to purchase the selected package and dismisses on success.
    private func purchaseSelected() async {
        guard let package = selectedPackage else { return }
        do {
            try await subscriptions.purchase(package: package)
            if subscriptions.isProUser { dismiss() }
        } catch SubscriptionError.purchaseCancelled {
            // User cancelled: no alert needed.
        } catch {
            present(error)
        }
    }

    /// Restores prior purchases and dismisses if entitlement becomes active.
    private func restore() async {
        do {
            try await subscriptions.restorePurchases()
            if subscriptions.isProUser { dismiss() }
        } catch {
            present(error)
        }
    }

    private func present(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}

// MARK: - Benefit row

private struct BenefitRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Plan card

private struct PlanCard: View {
    let package: Package
    let isSelected: Bool

    private var isLifetime: Bool { package.packageType == .lifetime }

    private var badgeText: LocalizedStringKey? {
        switch package.packageType {
        case .annual: return "Más Popular"
        case .lifetime: return "Pago Único"
        default: return nil
        }
    }

    private var billingCaption: LocalizedStringKey {
        switch package.packageType {
        case .annual: return "Facturado anualmente"
        case .lifetime: return "Acceso de por vida"
        default: return "Facturado mensualmente"
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            badge

            Image(systemName: isLifetime ? "crown.fill" : "sparkles")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(isLifetime ? AnyShapeStyle(goldGradient) : AnyShapeStyle(.tint))

            VStack(spacing: 6) {
                Text(package.storeProduct.localizedTitle)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                Text(package.storeProduct.localizedPriceString)
                    .font(.system(.largeTitle, design: .rounded).bold())
                Text(billingCaption)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? AnyShapeStyle(.tint.opacity(0.08)) : AnyShapeStyle(.background))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(borderStyle, lineWidth: isSelected ? 2.5 : 1)
        )
        .scaleEffect(isSelected ? 1 : 0.93)
        .animation(.snappy, value: isSelected)
    }

    @ViewBuilder
    private var badge: some View {
        if let badgeText {
            Text(badgeText)
                .font(.caption2.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isLifetime ? AnyShapeStyle(goldGradient) : AnyShapeStyle(.tint), in: Capsule())
                .foregroundStyle(.white)
        } else {
            // Reserve the badge height so all cards align vertically.
            Color.clear.frame(height: 26)
        }
    }

    private var goldGradient: LinearGradient {
        LinearGradient(colors: [Color(red: 0.80, green: 0.60, blue: 0.10),
                                Color(red: 1.0, green: 0.84, blue: 0.0)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var borderStyle: AnyShapeStyle {
        if isLifetime { return AnyShapeStyle(goldGradient) }
        return isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary.opacity(0.25))
    }
}

#Preview("Paywall · Gratuito") {
    PaywallView()
        .environment(SubscriptionManager())
        .tint(.blue)
}

#Preview("Paywall · Pro") {
    PaywallView()
        .environment(SubscriptionManager(isProMock: true))
        .tint(.blue)
}
