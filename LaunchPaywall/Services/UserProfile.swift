//
//  UserProfile.swift
//  LaunchPaywall
//
//  Created by LaunchApp Studio on 2026.
//

import Foundation

/// Represents the authenticated user's profile information.
struct UserProfile: Identifiable, Codable, Sendable {
    let id: String
    var email: String?
    var fullName: String?
    var isPro: Bool
    var createdAt: Date

    init(
        id: String,
        email: String? = nil,
        fullName: String? = nil,
        isPro: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.isPro = isPro
        self.createdAt = createdAt
    }

    /// Sample profile for Xcode Canvas previews.
    static let mock = UserProfile(
        id: "preview.user.id",
        email: "preview@example.com",
        fullName: "Jane Appleseed",
        isPro: true
    )
}

