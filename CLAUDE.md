# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

Single Xcode project, no CocoaPods. SPM resolves dependencies automatically.

```bash
xcodebuild -project FlowCash.xcodeproj -scheme FlowCash \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

- Deployment target: iOS 26.2; Swift language mode 5.0.
- No test target exists yet.
- Sole SPM dependency: Factory (FactoryKit) for DI.
- Requires a signing team for CloudKit; the simulator falls back to a local store when CloudKit is unavailable (see `makeContainer()`).

## Architecture

FlowCash is a personal finance tracker (income/expenses, UI in Ukrainian). MVVM over SwiftData with CloudKit sync.

### Persistence & DI
- `FlowCashApp.makeContainer()` (`FlowCash/FlowCashApp.swift`) builds the `ModelContainer`: a CloudKit private-DB config with a fallback to a local store. Schema = `Transaction`, `Category`, `Account`, `Budget`.
- **Every `@Model` property MUST have a default value** (and relationships must be optional) — CloudKit sync breaks otherwise. Follow this when adding fields.
- Data access goes through `DataStoreProtocol` (`@MainActor`, CRUD for all four models). The production impl is `SwiftDataStore` (wraps `container.mainContext`); previews/tests use `MockDataStore`.
- DI uses Factory: `Container.dataStore` (`Extensions/Container+Registration.swift`) is a `.singleton`. Swap it in previews with `.injectMockStore()`.

### ViewModels (the pattern to copy)
ViewModels are `@MainActor @Observable final class`, conform to `ErrorDisplayable`/`AlertDisplayable`, and inject the store via `@ObservationIgnored @Injected(\.dataStore)`. Run async work through the custom `Task(handlingError: self) { [weak self] in ... }` initializer (`Extensions/Task+HandlingError.swift`), which routes thrown errors into the VM's `error` property for alert display. See `Core/Home/HomeViewModel.swift`.

### Navigation
`NavigationStack` driven by per-screen `Hashable` route enums (e.g. `HomeRoute` in `HomeView.swift`) plus `.sheet` for add/edit flows. After onboarding the root is `HomeView` — there is no tab bar.

### First-launch flow
`@AppStorage` flags gate startup: `hasCompletedOnboarding` switches between `OnboardingView` and `AppRootView`; `hasSeedCompleted` guards one-time seeding of Ukrainian categories and accounts in `seedIfNeeded()`.

### Conventions
- UI strings are hardcoded in Ukrainian; currency/dates formatted with `uk_UA` locale.
- Dark mode is forced (`.preferredColorScheme(.dark)`).
- Use semantic color tokens from `Extensions/Color+Tokens.swift` (`Color.bgPrimary`, `.accentPrimary`, etc.) and `Color(hex:)`; don't hardcode colors in views.
- Domain errors: throw/wrap `AppError` (`Domain/Errors/AppError.swift`).
