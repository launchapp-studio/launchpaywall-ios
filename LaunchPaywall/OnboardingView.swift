//
//  OnboardingView.swift
//  LaunchPaywall
//
//  Created by LaunchApp Studio on 2026.
//

import SwiftUI

/// Model backing a single onboarding page.
private struct OnboardingPage: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let description: String
}

/// Three-page, value-oriented onboarding shown once on first launch.
struct OnboardingView: View {
    /// Persists completion so the onboarding is not shown again.
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var selection = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(symbol: "sparkles",
                       title: "Bienvenido a LaunchPaywall",
                       description: "La forma más rápida de lanzar tu app con un paywall de alta conversión."),
        OnboardingPage(symbol: "bolt.fill",
                       title: "Todo lo que necesitas",
                       description: "Suscripciones, restauración de compras y analítica, listos desde el primer día."),
        OnboardingPage(symbol: "crown.fill",
                       title: "Empieza a monetizar",
                       description: "Desbloquea funciones Pro y haz crecer tus ingresos sin complicaciones.")
    ]

    private var isLastPage: Bool { selection == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selection) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    pageView(page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(action: advance) {
                Text(isLastPage ? "Comenzar" : "Continuar")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 26)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(backgroundGradient.ignoresSafeArea())
    }

    // MARK: - Page

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: page.symbol)
                .font(.system(size: 96, weight: .bold))
                .foregroundStyle(.tint)
                .padding(40)
                .background(.tint.opacity(0.12), in: Circle())

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(colors: [Color.accentColor.opacity(0.10), .clear],
                       startPoint: .top, endPoint: .center)
    }

    // MARK: - Actions

    /// Advances to the next page, or completes onboarding on the last page.
    private func advance() {
        if isLastPage {
            hasCompletedOnboarding = true
        } else {
            withAnimation { selection += 1 }
        }
    }
}

#Preview {
    OnboardingView()
}
