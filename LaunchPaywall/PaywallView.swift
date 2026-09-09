//
//  PaywallView.swift
//  LaunchPaywall
//
//  Created by LaunchApp Studio on 2026.
//

import RevenueCat
import SwiftUI

/// Customizable paywall presenting the current RevenueCat offering with an
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
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        header
                            .padding(.horizontal, 24)
                        Spacer().frame(height: 28)
                        benefits
                            .padding(.horizontal, 24)
                        Spacer().frame(height: 28)
                        planSelector
                        Spacer(minLength: 20)
                    }
                    .padding(.top, 36)
                    // Raise the carousel slightly above the floating footer.
                    .frame(minHeight: proxy.size.height - 100, alignment: .top)
                }
                .scrollBounceBehavior(.basedOnSize)
                .safeAreaInset(edge: .bottom) { footer }
                .task { await loadOfferings() }
                .onAppear { TelemetryService.log(.paywallImpression) }
                .alert("Couldn't complete", isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage ?? "Please try again later.")
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 30) {
            appIcon
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.accentColor.opacity(0.35), radius: 10, y: 6)

            VStack(spacing: 6) {
                Text("Unlock LaunchPaywall Pro")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Access all premium features without limits.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Benefits

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 8) {
            BenefitRow(icon: "infinity", title: "Unlimited usage",
                       subtitle: "No restrictions or watermarks.")
            BenefitRow(icon: "bolt.fill", title: "Advanced features",
                       subtitle: "Exclusive tools for Pro users.")
            BenefitRow(icon: "lock.open.fill", title: "Priority and support",
                       subtitle: "Preferential attention and news before anyone else.")
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
            VStack(spacing: 14) {
                ScrollView(.horizontal) {
                    HStack(spacing: 16) {
                        ForEach(packages, id: \.identifier) { package in
                            PlanCard(package: package,
                                     isSelected: selectedPackage?.identifier == package.identifier)
                                .containerRelativeFrame(.horizontal)
                                .id(package.identifier)
                                .onTapGesture {
                                    withAnimation(.snappy) {
                                        scrolledPackageID = package.identifier
                                        selectedPackage = package
                                    }
                                }
                        }
                    }
                    .padding(.top, 14) // Margen superior para alojar la insignia sin alterar el layout
                    .padding(.bottom, 10)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .safeAreaPadding(.horizontal, 48)
                .scrollPosition(id: $scrolledPackageID)
                .scrollIndicators(.hidden)
                .onChange(of: scrolledPackageID) { _, newID in
                    if let newID, let match = packages.first(where: { $0.identifier == newID }) {
                        withAnimation(.snappy) {
                            selectedPackage = match
                        }
                    }
                }

                if packages.count > 1 {
                    pageDots(packages)
                }
            }
        } else {
            Text("No plans available at the moment.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.vertical, 40)
        }
    }

    /// Orders the offering's packages as Annual, Monthly, Lifetime (available only).
    private func orderedPackages(_ offering: Offering) -> [Package] {
        [offering.annual, offering.monthly, offering.lifetime].compactMap { $0 }
    }

    /// Pagination dots reflecting the currently centered card.
    private func pageDots(_ packages: [Package]) -> some View {
        HStack(spacing: 8) {
            ForEach(packages, id: \.identifier) { package in
                Circle()
                    .fill(package.identifier == scrolledPackageID
                          ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary.opacity(0.3)))
                    .frame(width: 7, height: 7)
            }
        }
        .animation(.snappy, value: scrolledPackageID)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 12) {
            Button(action: { Task { await purchaseSelected() } }) {
                ZStack {
                    if subscriptions.isBusy {
                        ProgressView().tint(.white)
                    } else {
                        Text("Continue")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 26)
                .foregroundStyle(.white)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [Color(red: 0.071, green: 0.063, blue: 0.102),
                                            Color(red: 0.439, green: 0.208, blue: 0.871)],
                                   startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .opacity(selectedPackage == nil || subscriptions.isBusy ? 0.6 : 1)
            }
            .buttonStyle(.plain)
            .disabled(selectedPackage == nil || subscriptions.isBusy)

            Button("Restore purchases") {
                Task { await restore() }
            }
            .font(.subheadline)
            .disabled(subscriptions.isBusy)

            HStack(spacing: 16) {
                Button("Privacy Policy") { openURL(AppConfig.privacyPolicyURL) }
                Text("·").foregroundStyle(.secondary)
                Button("Terms of Service") { openURL(AppConfig.termsOfServiceURL) }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(.regularMaterial)
    }

    /// App icon loaded from the bundle, with a branded gradient fallback.
    @ViewBuilder
    private var appIcon: some View {
        if let uiImage = Bundle.main.appIcon {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "sparkles")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(appIconGradient)
        }
    }

    private var appIconGradient: LinearGradient {
        LinearGradient(colors: [Color(red: 0.29, green: 0.56, blue: 0.99),
                                Color(red: 0.13, green: 0.36, blue: 0.90)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
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

                // A brief delay ensures the ScrollView has calculated its geometry
                // before setting the initial position, avoiding layout glitches.
                try? await Task.sleep(nanoseconds: 50_000_000)
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
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.subheadline.bold())
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Plan card

private struct PlanCard: View {
    let package: Package
    let isSelected: Bool

    private var badgeText: LocalizedStringKey? {
        switch package.packageType {
        case .annual: return "Most Popular"
        case .lifetime: return "One-Time Payment"
        default: return nil
        }
    }

    private var localizedTitle: LocalizedStringKey {
        switch package.packageType {
        case .annual: return "Yearly"
        case .monthly: return "Monthly"
        case .lifetime: return "Lifetime"
        default: return LocalizedStringKey(package.storeProduct.localizedTitle)
        }
    }

    /// Main price line: monthly equivalent for the annual plan, full price otherwise.
    private var primaryPriceText: String {
        if package.packageType == .annual, let perMonth = pricePerMonthString {
            return String(localized: "\(perMonth)/mo")
        }
        return package.storeProduct.localizedPriceString
    }

    private var pricePerMonthString: String? {
        guard let perMonth = package.storeProduct.pricePerMonth,
              let formatter = package.storeProduct.priceFormatter else { return nil }
        return formatter.string(from: perMonth)
    }

    private var billingCaption: String {
        switch package.packageType {
        case .annual: return String(localized: "\(package.storeProduct.localizedPriceString) per year")
        case .lifetime: return String(localized: "Lifetime access")
        default: return String(localized: "Billed monthly")
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(localizedTitle)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(primaryPriceText)
                .font(.system(.title, design: .rounded).bold())
            Text(billingCaption)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 165)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isSelected ? Color.purple : Color.purple.opacity(0.15), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        .overlay(alignment: .top) { badge.offset(y: -11) }
        .scaleEffect(isSelected ? 1 : 0.94)
        .animation(.snappy, value: isSelected)
    }

    @ViewBuilder
    private var badge: some View {
        if let badgeText {
            Text(badgeText)
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    LinearGradient(colors: [.indigo, .purple],
                                   startPoint: .leading, endPoint: .trailing),
                    in: Capsule()
                )
        }
    }
}

#Preview("Paywall · Free") {
    PaywallView()
        .environment(SubscriptionManager())
}

#Preview("Paywall · Pro") {
    PaywallView()
        .environment(SubscriptionManager(isProMock: true))
}

extension Bundle {
    /// Highest-resolution app icon declared in the bundle, if available.
    var appIcon: UIImage? {
        guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let files = primary["CFBundleIconFiles"] as? [String],
              let name = files.last else { return nil }
        return UIImage(named: name)
    }
}
