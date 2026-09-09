# 🚀 Launch Checklist

A step-by-step guide to take LaunchPaywall from this boilerplate to a production-ready App Store submission. This covers the essential configuration steps for Apple Developer, App Store Connect, and RevenueCat.

## 1. Apple Developer Portal
- [ ] **Create App ID:** Register a new Bundle ID matching your Xcode project.
- [ ] **Enable Capabilities:** Turn on **Sign In with Apple** and **In-App Purchase** for your App ID.
- [ ] **Generate Keys:** If using external servers to validate auth, generate a Sign in with Apple private key.

## 2. App Store Connect
- [ ] **Create App:** Create the new app record using the Bundle ID from Step 1.
- [ ] **Set up Subscriptions:** Go to *Monetization > Subscriptions*.
- [ ] **Create Subscription Group:** e.g., `Pro Features`.
- [ ] **Create Auto-Renewable Subscriptions:** Add your products (e.g., `app_monthly_299`, `app_yearly_2999`).
- [ ] **Add Metadata:** Add localizations, prices, and the mandatory review screenshot for each product.
- [ ] **Generate Shared Secret:** (Required for RevenueCat) Go to *App Information > App-Specific Shared Secret* and generate one.

## 3. RevenueCat Configuration
- [ ] **Create Project & App:** Add a new App in the RevenueCat dashboard and input your Bundle ID and the Shared Secret from App Store Connect.
- [ ] **Create Products:** Add the exact same Product IDs you created in App Store Connect.
- [ ] **Create Entitlements:** Create an entitlement (e.g., `pro_access`) that unlocks the premium features.
- [ ] **Attach Products:** Link your created Products to the `pro_access` entitlement.
- [ ] **Create Offerings:** Create a `default` offering and attach the packages (e.g., Monthly, Annual) that contain your products.

## 4. Xcode Project Setup
- [ ] **Update Bundle ID:** Change the default bundle identifier in target settings.
- [ ] **Update API Keys:** Open `AppConfig.swift` and paste your RevenueCat Public API Key.
- [ ] **Update Local StoreKit File:** Update `Products.storekit` with your new Product IDs for local simulator testing.
- [ ] **Localization:** Review `Localizable.xcstrings` and update the app name and core strings.

## 5. Final Testing
- [ ] **Local Testing:** Test purchases in the Simulator using the local `.storekit` environment.
- [ ] **Sandbox Testing:** Build on a real physical device and test purchases using an Apple Sandbox Account.
- [ ] **Auth Edge Cases:** Test credential revocation (Settings -> Apple ID -> Password & Security -> Apps Using Apple ID -> Stop using).