//
//  LaunchPaywallApp.swift
//  LaunchPaywall
//
//  Created by LaunchApp Studio on 2026.
//

import SwiftUI

@main
struct LaunchPaywallApp: App {
    // Managers owned by the app and shared through the environment.
    @State private var authManager = AuthManager()
    @State private var subscriptionManager = SubscriptionManager()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .environment(authManager)
            .environment(subscriptionManager)
            .task {
                // Keep RevenueCat identity in sync with sign-in/out that happen
                // after launch, without coupling AuthManager to RevenueCat.
                authManager.onDidSignIn = { userID in
                    try? await subscriptionManager.logIn(appUserID: userID)
                }
                authManager.onDidSignOut = {
                    try? await subscriptionManager.logOut()
                }

                // Configure RevenueCat with the existing session, if any.
                subscriptionManager.configure(appUserID: authManager.userId)
            }
        }
    }
}
