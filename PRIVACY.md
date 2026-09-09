# Privacy Policy

**Last updated:** September 2026

**LaunchApp Studio** ("we", "our", or "us") operates the **LaunchPaywall** open-core iOS boilerplate. This Privacy Policy explains how data is handled when using this codebase and within applications built using this template.

---

## 1. Information Collection and Use

The **LaunchPaywall** boilerplate code itself does not directly collect, harvest, or sell personal identifiable information (PII) to external servers owned by LaunchApp Studio.

When configured in a live environment, the template interacts with trusted third-party services:

* **Authentication (Sign in with Apple):** Authentication credentials and stable user identifiers are handled directly by Apple's `AuthenticationServices` framework and stored locally on the user's device using the native iOS **Keychain**.
* **In-App Purchases & Subscriptions (RevenueCat):** Subscription status, transaction history, and anonymous app user IDs are processed via the RevenueCat SDK to validate entitlements.
* **Anonymous Telemetry (OSLog / TelemetryDeck):** Non-identifying usage metrics (e.g., paywall impressions, purchase events) may be logged to improve user experience without tracking individuals across third-party apps.

---

## 2. Local Data Storage

All persistent user data managed directly by this boilerplate (such as onboarding status or authentication keys) is saved locally on the device using Apple's standard framework APIs (`@AppStorage` / `UserDefaults` and `Keychain Services`).

---

## 3. Third-Party Services Privacy Policies

If you publish an application based on this template, you are encouraged to review the privacy policies of the underlying service providers:

* [Apple Privacy Policy](https://www.apple.com/legal/privacy/)
* [RevenueCat Privacy Policy](https://www.revenuecat.com/privacy/)
* [TelemetryDeck Privacy Policy](https://telemetrydeck.com/privacy/)

---

## 4. Developer Responsibility

Developers utilizing this open-core template to publish their own applications on the App Store are legally responsible for deploying their own user-facing Privacy Policy, configuring App Privacy Details (*Privacy Nutrition Labels*) in App Store Connect, and complying with local privacy regulations (GDPR, CCPA).

---

## 5. Contact Information

For questions or inquiries regarding the codebase privacy practices, please open an issue in the official GitHub repository or reach out via [https://github.com/launchapp-studio](https://github.com/launchapp-studio).