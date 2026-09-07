# LaunchPaywall iOS

> An open-core SwiftUI boilerplate to launch apps with a paywall, subscriptions, and authentication in minutes.

![Swift 6](https://img.shields.io/badge/Swift-6-orange?logo=swift)
![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue?logo=apple)
![RevenueCat v5](https://img.shields.io/badge/RevenueCat-v5-9354FF)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

## Overview

**LaunchPaywall** is an **open-core** boilerplate that gives you the foundational service layer every subscription app needs: sign-in, purchase management, and a production-ready paywall experience. It is written entirely in **Swift 6** with modern **SwiftUI** syntax (`@Observable`, `@Environment`, `async/await`, `@MainActor`), so you can focus on your product instead of rewriting the plumbing.

The open-core version includes everything required for a working MVP. Premium templates, additional components, and paywall variants are available in the Pro version (see below).

## Features

- 🔐 **Sign in with Apple + native Keychain** — authentication with `AuthenticationServices` and secure persistence of the user identifier via the `Security` API.
- 💳 **RevenueCat v5 integration** — configuration, `Offerings`, package purchases, restoring purchases, and identity sync (`logIn`/`logOut`).
- 🎯 **High-conversion paywall + 3-step onboarding** — annual/monthly plan selector with a highlighted badge, and paged onboarding persisted with `@AppStorage`.
- 🌍 **Native multi-language localization (i18n)** — 6 languages out of the box (English, Spanish, German, French, Italian, Portuguese) powered by the `Localizable.xcstrings` String Catalog, with English as the source language.
- 🧪 **Local debug testing mode** — a `#if DEBUG` flow with `UserDefaults` persistence lets you exercise the entire paywall and switch between Free/Pro plans without wiring up real RevenueCat accounts or StoreKit during development.
- 🔬 **Xcode Canvas mocks & structured OSLog telemetry** — preview initializers (`isProMock`, `isAuthenticatedMock`) to preview states without networking, and a lightweight analytics abstraction built on `OSLog`.

## Project structure

```
LaunchPaywall/
├── LaunchPaywallApp.swift        # Entry point: injects managers and picks onboarding vs. content
├── ContentView.swift            # Main view: Free / Pro states + Sign in with Apple
├── PaywallView.swift            # High-conversion paywall (plans, purchase, restore)
├── OnboardingView.swift         # 3-screen paged onboarding
├── Localizable.xcstrings        # String Catalog: 6 languages (en source + es, de, fr, it, pt)
└── Services/
    ├── AppConfig.swift          # Centralized configuration (keys and URLs)
    ├── AuthManager.swift        # Sign in with Apple + Keychain (@Observable, @MainActor)
    ├── SubscriptionManager.swift# RevenueCat v5 (@Observable, @MainActor)
    └── TelemetryService.swift   # Anonymous structured analytics with OSLog
```

## Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/launchappstudio/launchpaywall-ios.git
   cd launchpaywall-ios
   ```

2. **Open the project in Xcode 26.5+**

   ```bash
   open LaunchPaywall.xcodeproj
   ```

3. **Resolve dependencies**

   Xcode automatically downloads the RevenueCat package via Swift Package Manager (`https://github.com/RevenueCat/purchases-ios`, v5.x).

4. **Replace the keys in `Services/AppConfig.swift`**

   ```swift
   enum AppConfig {
       static let revenueCatAPIKey = "appl_YOUR_REVENUECAT_PUBLIC_KEY"
       static let telemetryDeckAppID = "YOUR_TELEMETRYDECK_APP_ID"
       static let entitlementID = "pro_access" // must match your entitlement in RevenueCat
       static let privacyPolicyURL = URL(string: "https://github.com/launchappstudio/launchpaywall-ios/blob/main/PRIVACY.md")!
       static let termsOfServiceURL = URL(string: "https://github.com/launchappstudio/launchpaywall-ios/blob/main/TERMS.md")!
   }
   ```

5. **Enable "Sign in with Apple"**

   In the `LaunchPaywall` target → *Signing & Capabilities* → add the **Sign in with Apple** capability.

6. **(Optional) Test purchases in the simulator**

   Add a *StoreKit Configuration File* (`.storekit`) with the same Product IDs as RevenueCat and select it in *Edit Scheme → Run → Options → StoreKit Configuration*. See the detailed instructions in the header of `SubscriptionManager.swift`. During development you can also use the built-in `#if DEBUG` toggle to switch between Free/Pro without any store setup.

7. **Build and run** on an iOS 17+ simulator or a real device.

---

## ⭐ Upgrade to Pro Version

Want to accelerate your launch even further? The **Pro version** of LaunchPaywall includes:

- 🎨 Multiple A/B-tested, high-conversion paywall templates.
- 📊 Preconfigured analytics dashboard and advanced events.
- 🌍 Ready-to-use multi-language localization.
- 🧩 Premium components (account management, promo codes, upsells).
- 🚀 Priority support and continuous updates.

The Pro version will be **available soon on Lemon Squeezy**. ⭐ Star and watch this repository to be notified as soon as it launches.

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/launchappstudio">LaunchApp Studio</a>
</p>
