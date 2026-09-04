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
            ScrollView {
                VStack(spacing: 28) {
                    if subscriptionManager.isProUser {
                        proContent
                    } else {
                        freeContent
                    }
                    authSection
                }
                .padding(24)
            }
            .navigationTitle("LaunchPaywall")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Free tier

    private var freeContent: some View {
        VStack(spacing: 24) {
            Text("Plan Gratuito")
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.secondary.opacity(0.15), in: Capsule())
                .foregroundStyle(.secondary)

            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.secondary)
                Text("Funciones bloqueadas")
                    .font(.title2.bold())
                Text("Actualiza a Pro para desbloquear todas las funciones premium.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                LockedFeatureRow(title: "Uso ilimitado")
                LockedFeatureRow(title: "Funciones avanzadas")
                LockedFeatureRow(title: "Soporte prioritario")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                showPaywall = true
            } label: {
                Text("Obtener Pro")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 26)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    // MARK: - Pro tier

    private var proContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "crown.fill")
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(.yellow)
                .padding(24)
                .background(.yellow.opacity(0.15), in: Circle())

            VStack(spacing: 8) {
                Text("Acceso Pro Activo")
                    .font(.largeTitle.bold())
                Text("¡Gracias por tu apoyo! Ya tienes todo desbloqueado.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                UnlockedFeatureRow(title: "Uso ilimitado")
                UnlockedFeatureRow(title: "Funciones avanzadas")
                UnlockedFeatureRow(title: "Soporte prioritario")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Authentication

    @ViewBuilder
    private var authSection: some View {
        Divider().padding(.vertical, 8)

        if authManager.isAuthenticated {
            VStack(spacing: 8) {
                Label(authManager.userEmail ?? "Sesión iniciada", systemImage: "person.crop.circle.fill")
                    .font(.subheadline)
                Button("Cerrar sesión", role: .destructive) {
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
    let title: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill").foregroundStyle(.secondary)
            Text(title).foregroundStyle(.secondary)
        }
    }
}

private struct UnlockedFeatureRow: View {
    let title: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            Text(title)
        }
    }
}

#Preview("Gratuito") {
    ContentView()
        .environment(AuthManager())
        .environment(SubscriptionManager())
}

#Preview("Pro + Autenticado") {
    ContentView()
        .environment(AuthManager(isAuthenticatedMock: true))
        .environment(SubscriptionManager(isProMock: true))
}
