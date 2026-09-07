//
//  ContentView.swift
//  LaunchPaywall
//
//  Created by LaunchApp Studio on 2026.
//

import AuthenticationServices
import SwiftUI

struct ContentView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(AuthManager.self) private var authManager

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerCard
                        gatedFeatureCard
                        bottomActions
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Header card

    private var headerCard: some View {
        HStack(spacing: 16) {
            appIcon
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(AppConfig.appName)
                    .font(.title3.bold())
                HStack(spacing: 6) {
                    Circle()
                        .fill(subscriptionManager.isProUser ? Color.green : Color.secondary)
                        .frame(width: 8, height: 8)
                    Text(subscriptionManager.isProUser ? "Pro Plan Active" : "Free Plan")
                        .font(.subheadline)
                        .foregroundStyle(subscriptionManager.isProUser ? Color.green : Color.secondary)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    /// App icon from the bundle, with the brand gradient as fallback.
    @ViewBuilder
    private var appIcon: some View {
        if let uiImage = Bundle.main.appIcon {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "sparkles")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(LinearGradient(colors: [.indigo, .purple],
                                           startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }

    // MARK: - Gated feature card

    @ViewBuilder
    private var gatedFeatureCard: some View {
        VStack(spacing: 16) {
            if subscriptionManager.isProUser {
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.tint)
                Text("Welcome to Pro!")
                    .font(.title2.bold())
                Text("You have unlimited access to all premium features.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.tint)
                Text("Premium Features")
                    .font(.title2.bold())
                Text("Upgrade to Pro to unlock the app's full potential.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    LockedFeatureRow(icon: "infinity", title: "Unlimited usage")
                    LockedFeatureRow(icon: "bolt.fill", title: "Advanced features")
                    LockedFeatureRow(icon: "star.fill", title: "Priority support")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Primary button

    private var getProButton: some View {
        Button {
            showPaywall = true
        } label: {
            Text("Get Pro")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(
                    LinearGradient(colors: [Color(red: 0.071, green: 0.063, blue: 0.102),
                                            Color(red: 0.439, green: 0.208, blue: 0.871)],
                                   startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom actions

    private var bottomActions: some View {
        VStack(spacing: 12) {
            if !subscriptionManager.isProUser {
                getProButton
            }
            authSection

#if DEBUG
            VStack {
                Button(action: {
                    subscriptionManager.toggleDebugPro()
                }) {
                    Label(
                        subscriptionManager.debugProUnlocked ? "Debug: Switch to FREE" : "Debug: Switch to PRO",
                        systemImage: "ant.fill"
                    )
                    .font(.caption.bold())
                    .foregroundColor(.orange)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
                }
            }
            .padding(.top, 8)
#endif
        }
    }

    // MARK: - Authentication

    @ViewBuilder
    private var authSection: some View {
        if authManager.isAuthenticated {
            VStack(spacing: 8) {
                Label(authManager.userEmail ?? "Signed in", systemImage: "person.crop.circle.fill")
                    .font(.subheadline)
                Button("Sign out", role: .destructive) {
                    try? authManager.signOut()
                }
                .font(.subheadline)
            }
        } else {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                authManager.handleSignInWithApple(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Feature rows

private struct LockedFeatureRow: View {
    let icon: String
    let title: LocalizedStringKey
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.tint)
                .frame(width: 26)
            Text(title)
                .font(.subheadline)
        }
    }
}

#Preview("Free") {
    ContentView()
        .environment(AuthManager())
        .environment(SubscriptionManager())
}

#Preview("Pro + Authenticated") {
    ContentView()
        .environment(AuthManager(isAuthenticatedMock: true))
        .environment(SubscriptionManager(isProMock: true))
}
