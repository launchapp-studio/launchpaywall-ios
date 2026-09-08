//
//  AuthManagerTests.swift
//  LaunchPaywallTests
//
//  Created by LaunchApp Studio on 2026.
//

import Foundation
import Testing
@testable import LaunchPaywall

@MainActor
struct AuthManagerTests {
    /// The mock initializer must expose a fully signed-in preview session
    /// without touching the Keychain or Apple servers.
    @Test("isAuthenticatedMock exposes a signed-in preview session")
    func authenticatedMockSession() {
        let auth = AuthManager(isAuthenticatedMock: true)
        #expect(auth.isAuthenticated)
        #expect(auth.userId == "preview.user.id")
        #expect(auth.userEmail == "preview@example.com")
    }
}

struct AuthErrorTests {
    /// Every error case must surface a non-empty, user-facing description.
    @Test("Every AuthError case has a user-facing description")
    func errorDescriptionsArePresent() {
        #expect(AuthError.invalidCredential.errorDescription?.isEmpty == false)
        #expect(AuthError.cancelled.errorDescription?.isEmpty == false)

        let underlying = NSError(domain: "test", code: 42)
        #expect(AuthError.failed(underlying: underlying).errorDescription?.isEmpty == false)

        let keychainDescription = AuthError.keychainFailure(status: -25300).errorDescription
        #expect(keychainDescription?.contains("-25300") == true)
    }
}
