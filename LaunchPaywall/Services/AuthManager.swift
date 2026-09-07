//
//  AuthManager.swift
//  LaunchPaywall
//
//  Created by LaunchApp Studio on 2026.
//

import AuthenticationServices
import Foundation
import Security
import UIKit

/// Errors surfaced by the authentication flow.
enum AuthError: LocalizedError {
    case invalidCredential
    case cancelled
    case failed(underlying: Error)
    case keychainFailure(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "The received Apple credential was invalid."
        case .cancelled:
            return "Sign in was cancelled."
        case .failed(let underlying):
            return "Sign in failed: \(underlying.localizedDescription)"
        case .keychainFailure(let status):
            return "Keychain operation failed with status \(status)."
        }
    }
}

/// Manages the "Sign in with Apple" flow and persists the stable user identifier
/// securely in the Keychain. Observable so SwiftUI views react to auth state changes.
@Observable
@MainActor
final class AuthManager: NSObject {
    // MARK: - Published state

    /// Whether a valid, persisted user identifier exists.
    private(set) var isAuthenticated = false
    /// The stable Apple user identifier (persisted across launches).
    private(set) var userId: String?
    /// The user's email, only available on the first authorization.
    private(set) var userEmail: String?

    // MARK: - Identity sync hooks

    /// Invoked with the Apple user id after a successful sign-in, so other
    /// services (e.g. RevenueCat) can bind the session. Keeps this manager
    /// decoupled from the subscription layer.
    var onDidSignIn: ((String) async -> Void)?
    /// Invoked after sign-out so other services can clear their session.
    var onDidSignOut: (() async -> Void)?

    // MARK: - Keychain constants

    private let keychainService = "com.launchappstudio.launchpaywall.auth"
    private let keychainAccount = "appleUserId"

    // MARK: - Continuation bridging the delegate callback to async/await

    private var authContinuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    // MARK: - Lifecycle

    /// - Parameter isAuthenticatedMock: Simulates a signed-in session for the
    ///   SwiftUI Canvas without touching the Keychain or Apple servers.
    init(isAuthenticatedMock: Bool = false) {
        super.init()
        if isAuthenticatedMock {
            isAuthenticated = true
            userId = "preview.user.id"
            userEmail = "preview@example.com"
        } else {
            restoreSession()
        }
    }

    // MARK: - Public API

    /// Starts the Sign in with Apple request and awaits the delegate result.
    /// On success, persists the user identifier and updates published state.
    func signInWithApple() async throws {
        TelemetryService.log(.signInStarted)
        do {
            let credential = try await performAppleSignIn()
            try handle(credential: credential)
            TelemetryService.log(.signInSuccess)
        } catch {
            TelemetryService.log(.signInFailed, parameters: ["reason": String(describing: error)])
            throw error
        }
    }

    /// Clears the persisted identifier and resets published state.
    func signOut() throws {
        try deleteUserIdFromKeychain()
        userId = nil
        userEmail = nil
        isAuthenticated = false
        // Clear the RevenueCat session (or any other) via the hook.
        Task { await onDidSignOut?() }
    }

    /// Handles the result delivered by SwiftUI's native `SignInWithAppleButton`.
    func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                TelemetryService.log(.signInFailed, parameters: ["reason": "invalid_credential"])
                return
            }
            do {
                try handle(credential: credential)
                TelemetryService.log(.signInSuccess)
            } catch {
                TelemetryService.log(.signInFailed, parameters: ["reason": String(describing: error)])
            }
        case .failure(let error):
            TelemetryService.log(.signInFailed, parameters: ["reason": String(describing: error)])
        }
    }

    // MARK: - Session restoration

    /// Loads any previously stored identifier from the Keychain on launch.
    private func restoreSession() {
        if let storedId = try? readUserIdFromKeychain() {
            userId = storedId
            isAuthenticated = true
        }
    }

    // MARK: - Apple Sign In request

    /// Configures and dispatches the authorization controller, wrapping its
    /// delegate callbacks in a checked continuation for async/await ergonomics.
    private func performAppleSignIn() async throws -> ASAuthorizationAppleIDCredential {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        return try await withCheckedThrowingContinuation { continuation in
            self.authContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    /// Extracts the identifier/email from a credential and persists it securely.
    private func handle(credential: ASAuthorizationAppleIDCredential) throws {
        let id = credential.user
        guard !id.isEmpty else { throw AuthError.invalidCredential }

        try saveUserIdToKeychain(id)
        userId = id
        // Email is only delivered on the first authorization; keep it if present.
        if let email = credential.email {
            userEmail = email
        }
        isAuthenticated = true
        // Sync the identity with other services (e.g. RevenueCat) via the hook.
        Task { await onDidSignIn?(id) }
    }

    // MARK: - Keychain (native Security API)

    /// Inserts or updates the user identifier in the Keychain.
    private func saveUserIdToKeychain(_ id: String) throws {
        guard let data = id.data(using: .utf8) else { throw AuthError.invalidCredential }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]

        // Try updating first; if the item is missing, add it.
        let attributes: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = data
            newItem[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(newItem as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw AuthError.keychainFailure(status: addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw AuthError.keychainFailure(status: updateStatus)
        }
    }

    /// Reads the stored user identifier, returning nil if none exists.
    private func readUserIdFromKeychain() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data, let id = String(data: data, encoding: .utf8) else {
                throw AuthError.invalidCredential
            }
            return id
        case errSecItemNotFound:
            return nil
        default:
            throw AuthError.keychainFailure(status: status)
        }
    }

    /// Removes the stored user identifier from the Keychain.
    private func deleteUserIdFromKeychain() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthError.keychainFailure(status: status)
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthManager: ASAuthorizationControllerDelegate {
    /// Resumes the continuation with the Apple credential on success.
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                self.authContinuation?.resume(throwing: AuthError.invalidCredential)
                self.authContinuation = nil
                return
            }
            self.authContinuation?.resume(returning: credential)
            self.authContinuation = nil
        }
    }

    /// Resumes the continuation with a mapped error on failure/cancellation.
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            let mapped: AuthError
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                mapped = .cancelled
            } else {
                mapped = .failed(underlying: error)
            }
            self.authContinuation?.resume(throwing: mapped)
            self.authContinuation = nil
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    /// Provides the anchor window used to present the Apple sign-in sheet.
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let scene = windowScenes.first { $0.activationState == .foregroundActive } ?? windowScenes.first
            // A foreground window scene always exists while the sign-in sheet is presented.
            guard let scene else { preconditionFailure("No UIWindowScene available to anchor Sign in with Apple") }
            return scene.keyWindow ?? UIWindow(windowScene: scene)
        }
    }
}
