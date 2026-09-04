# LaunchPaywall iOS

> Boilerplate open-core en SwiftUI para lanzar apps con paywall, suscripciones y autenticación en minutos.

![Swift 6](https://img.shields.io/badge/Swift-6-orange?logo=swift)
![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue?logo=apple)
![RevenueCat v5](https://img.shields.io/badge/RevenueCat-v5-9354FF)
![Xcode 26](https://img.shields.io/badge/Xcode-26-147EFB?logo=xcode)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

## Descripción general

**LaunchPaywall** es un boilerplate **open-core** que te da la capa de servicios base que toda app de suscripción necesita: inicio de sesión, gestión de compras y una experiencia de paywall lista para producción. Está escrito íntegramente en **Swift 6** con sintaxis moderna de **SwiftUI** (`@Observable`, `@Environment`, `async/await`, `@MainActor`), para que puedas concentrarte en tu producto en lugar de reescribir la fontanería.

La versión open-core incluye todo lo necesario para un MVP funcional. Las plantillas premium, componentes adicionales y variantes de paywall están disponibles en la versión Pro (ver abajo).

## Características

- 🔐 **Sign in with Apple + Keychain nativo** — autenticación con `AuthenticationServices` y persistencia segura del identificador de usuario mediante la API `Security`.
- 💳 **Integración con RevenueCat v5** — configuración, ofertas (`Offerings`), compra de paquetes, restauración de compras y sincronización de identidad (`logIn`/`logOut`).
- 🎯 **Paywall de alta conversión + Onboarding en 3 pasos** — selector de planes anual/mensual con badge destacado, y onboarding paginado persistido con `@AppStorage`.
- 🧪 **Mocks para Xcode Canvas y telemetría estructurada con OSLog** — inicializadores de prueba (`isProMock`, `isAuthenticatedMock`) para previsualizar estados sin red, y una abstracción de analítica ligera basada en `OSLog`.

## Estructura del proyecto

```
LaunchPaywall/
├── LaunchPaywallApp.swift        # Punto de entrada: inyecta managers y decide onboarding vs. contenido
├── ContentView.swift            # Vista principal: estados Gratuito / Pro + Sign in with Apple
├── PaywallView.swift            # Paywall de alta conversión (planes, compra, restauración)
├── OnboardingView.swift         # Onboarding paginado de 3 pantallas
└── Services/
    ├── AppConfig.swift          # Configuración centralizada (claves y URLs)
    ├── AuthManager.swift        # Sign in with Apple + Keychain (@Observable, @MainActor)
    ├── SubscriptionManager.swift# RevenueCat v5 (@Observable, @MainActor)
    └── TelemetryService.swift   # Analítica anónima estructurada con OSLog
```

## Instalación

1. **Clona el repositorio**

   ```bash
   git clone https://github.com/launchappstudio/launchpaywall-ios.git
   cd launchpaywall-ios
   ```

2. **Abre el proyecto en Xcode 26.5+**

   ```bash
   open LaunchPaywall.xcodeproj
   ```

3. **Resuelve las dependencias**

   Xcode descargará automáticamente el paquete de RevenueCat vía Swift Package Manager (`https://github.com/RevenueCat/purchases-ios`, v5.x).

4. **Reemplaza las claves en `Services/AppConfig.swift`**

   ```swift
   enum AppConfig {
       static let revenueCatAPIKey = "appl_TU_CLAVE_PUBLICA_DE_REVENUECAT"
       static let telemetryDeckAppID = "TU_TELEMETRYDECK_APP_ID"
       static let entitlementID = "pro_access" // debe coincidir con tu entitlement en RevenueCat
       static let privacyPolicyURL = URL(string: "https://tudominio.com/privacy")!
       static let termsOfServiceURL = URL(string: "https://tudominio.com/terms")!
   }
   ```

5. **Activa "Sign in with Apple"**

   En el target `LaunchPaywall` → *Signing & Capabilities* → añade la capability **Sign in with Apple**.

6. **(Opcional) Prueba compras en el simulador**

   Añade un *StoreKit Configuration File* (`.storekit`) con los mismos Product IDs de RevenueCat y selecciónalo en *Edit Scheme → Run → Options → StoreKit Configuration*. Consulta las instrucciones detalladas en la cabecera de `SubscriptionManager.swift`.

7. **Compila y ejecuta** en un simulador iOS 17+ o dispositivo real.

---

## ⭐ Upgrade to Pro Version

¿Quieres acelerar aún más tu lanzamiento? La **versión Pro** de LaunchPaywall incluye:

- 🎨 Múltiples plantillas de paywall A/B testeadas y de alta conversión.
- 📊 Dashboard de analítica y eventos avanzados preconfigurados.
- 🌍 Localización multi-idioma lista para usar.
- 🧩 Componentes premium (gestión de cuenta, promo codes, upsells).
- 🚀 Soporte prioritario y actualizaciones continuas.

**[👉 Obtén la versión Pro completa](https://launchappstudio.com/launchpaywall-pro)**

---

<p align="center">
  Hecho con ❤️ por <a href="https://launchappstudio.com">LaunchApp Studio</a>
</p>
