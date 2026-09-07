//
//  OnboardingView.swift
//  LaunchPaywall
//
//  Created by LaunchApp Studio on 2026.
//

import SwiftUI

/// Model backing a single onboarding page.
struct OnboardingPage: Identifiable {
    let id = UUID()
    var symbol: String? = nil
    let title: String
    let description: String
    var usesAppIcon = false
}

/// Three-page, value-oriented onboarding sequence that can be used standalone
/// or as a pre-sell funnel in existing apps.
struct OnboardingView: View {
    /// Persists completion so the onboarding is not shown again.
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    let pages: [OnboardingPage]
    let onComplete: (() -> Void)?

    @State private var selection = 0

    /// Default pages shown by the boilerplate.
    static let defaultPages: [OnboardingPage] = [
        OnboardingPage(title: "Welcome to LaunchPaywall",
                       description: "The perfect foundation to launch your subscription app in record time.",
                       usesAppIcon: true),
        OnboardingPage(symbol: "creditcard.fill",
                       title: "Purchase Management",
                       description: "Ready-made RevenueCat integration to manage plans and subscriptions."),
        OnboardingPage(symbol: "applelogo",
                       title: "Secure Authentication",
                       description: "Sign in with Apple natively integrated with the iOS Keychain.")
    ]

    /// Initializes the onboarding view with optional custom pages and a completion closure.
    init(
        pages: [OnboardingPage] = OnboardingView.defaultPages,
        onComplete: (() -> Void)? = nil
    ) {
        self.pages = pages
        self.onComplete = onComplete
    }

    private var isLastPage: Bool { selection == pages.count - 1 }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $selection) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        pageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageDots
                    .padding(.bottom, 24)

                Button(action: advance) {
                    Text(isLastPage ? "Get started" : "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 26)
                        .foregroundStyle(.white)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [Color(red: 0.071, green: 0.063, blue: 0.102),
                                                    Color(red: 0.439, green: 0.208, blue: 0.871)],
                                           startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            Button("Skip") {
                completeOnboarding()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Page

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 28) {
            Spacer()
            stepIcon(page)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.accentColor.opacity(0.35), radius: 16, y: 8)

            VStack(spacing: 12) {
                Text(LocalizedStringKey(page.title))
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text(LocalizedStringKey(page.description))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }

    /// Step icon: the app icon on the first page, a gradient SF Symbol otherwise.
    @ViewBuilder
    private func stepIcon(_ page: OnboardingPage) -> some View {
        if page.usesAppIcon, let uiImage = Bundle.main.appIcon {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: page.symbol ?? "app")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(colors: [Color(red: 0.071, green: 0.063, blue: 0.102),
                                            Color(red: 0.439, green: 0.208, blue: 0.871)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        }
    }

    // MARK: - Page dots

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Circle()
                    .fill(index == selection
                          ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary.opacity(0.3)))
                    .frame(width: 7, height: 7)
            }
        }
        .animation(.snappy, value: selection)
    }

    // MARK: - Actions

    /// Advances to the next page, or completes onboarding on the last page.
    private func advance() {
        if isLastPage {
            completeOnboarding()
        } else {
            withAnimation { selection += 1 }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        onComplete?()
    }
}

#Preview("Default Onboarding") {
    OnboardingView()
}

#Preview("Custom Pages + Callback") {
    OnboardingView(
        pages: [
            OnboardingPage(symbol: "sparkles", title: "Discover Pro", description: "Unlock all premium features."),
            OnboardingPage(symbol: "bolt.fill", title: "Lightning Fast", description: "Save hours of setup time.")
        ],
        onComplete: {
            print("Onboarding completed")
        }
    )
}
