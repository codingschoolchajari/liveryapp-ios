# AGENTS.md - liveryapp-ios

SwiftUI iOS app for the Livery delivery platform. Xcode project (no CocoaPods/SPM Package.swift). Firebase Auth + FCM push.

## Build & run

Open `livery.xcodeproj` in Xcode. No external dependency manager needed — all dependencies are bundled or system frameworks.

## Project structure

```
livery/
  app/             # AppDelegate, liveryApp.swift (entry point)
  view/            # SwiftUI views (per screen)
  viewmodel/       # MVVM ViewModels (per screen)
  data/
    api/           # Service classes for API calls
    model/         # Codable data models (per domain)
    repository/    # Token storage, etc.
  components/      # Reusable SwiftUI components
  navigation/      # NavigationManager (phase-based routing)
  helpers/         # Utility helpers
  services/        # Location service, notification manager, etc.
  utils/           # StringUtils, ConfigUtils, etc.
  singleton/       # Shared singletons (ImageCache, etc.)
```

## Key architecture

- **State**: `liveryApp` creates shared `@StateObject`s: `NavigationManager`, `PerfilUsuarioState`, `NotificacionesState`, `CarritoViewModel`. Passed via `.environmentObject()`.
- **Navigation**: Phase-based (`loading → auth → registration → main`). `NavigationManager.replaceRoot(with:)` switches phases.
- **Cart**: `CarritoViewModel` is shared across the app; only one merchant at a time. Adding a product from a different merchant prompts to clear cart.
- **MVVM**: Views talk to ViewModels via `@EnvironmentObject` or `@StateObject`. ViewModels call Service classes which hit the REST API (Base URL in `ConfiguracionesUtil`).

## Rewards + purchases combined flow

When a user taps a won reward → `PremiosViewModel.inicializarProductoSeleccionado()` calls `comerciosService.buscarComercioPorProducto()`. The returned `Comercio` is set on `CarritoViewModel.comercio`. Bank details shown at checkout come from `comercio.datosBancarios`. If the API endpoint omits `datosBancarios` from its projection, bank details show empty.