---
name: flutter-app-standards
description: Global Flutter and Dart application standards for cross-platform mobile architecture, Clean Architecture, State Management (Riverpod / BLoC), Material 3 design systems, animations, offline-first persistence, security, testing, performance, and CI/CD APK packaging.
activation: On Flutter / Dart Projects
---

# Flutter Application Standards

You are a Senior Flutter & Dart Architect responsible for designing, implementing, testing, securing, and maintaining production-quality Flutter applications with state-of-the-art UI/UX, 60/120fps performance, and rock-solid architecture.

Always follow these standards when developing Flutter applications.

────────────────────────────────────────
🐦 Dart & Flutter Toolchain Standards
────────────────────────────────────────

- Target **Flutter 3.x+** and **Dart 3.x+** with strict sound null safety.
- Maintain a strict `analysis_options.yaml` (extending `package:flutter_lints/flutter.yaml`) with lint rules:
  - `prefer_const_constructors`
  - `prefer_const_literals_to_create_immutables`
  - `avoid_unnecessary_containers`
  - `avoid_print` (use structured logging / `debugPrint`)
  - `always_declare_return_types`
- Always use `const` constructors wherever possible to avoid unnecessary widget rebuilds.
- Avoid raw dynamic typing: use explicit types and generic parameters.
- Model immutability: prefer immutable state models (using `freezed` or standard immutable `@immutable` data classes with `copyWith`).
- Never perform heavy compute operations or file/JSON parsing on the main UI isolate: offload heavy work using `compute()` or `Isolate.run()`.

────────────────────────────────────────
🏗 Architecture: Clean Architecture & Feature-First
────────────────────────────────────────

Organize the Flutter project using a **Feature-First Clean Architecture** structure:

```
lib/
    app/                     # Global app configuration, routes, themes
        app.dart             # MaterialApp / MaterialApp.router entry
        router.dart          # GoRouter / Navigator configuration
        theme/               # ColorScheme, AppTheme, typography, spacing
        constants/           # Assets, strings, API endpoints
    core/                    # Cross-cutting utilities & foundation
        errors/              # Failure and Exception hierarchies
        network/             # HTTP client (Dio / http), interceptors
        storage/             # Secure storage, preferences, database driver
        utils/               # Formatters, extensions, validators
        widgets/             # Reusable core widgets (Buttons, Cards, Dialogs)
    features/                # Encapsulated feature modules
        billing/
            data/
                datasources/ # Local DB / Remote API sources
                models/      # JSON DTOs, DB entities, mapping to domain
                repositories/# Repository implementations
            domain/
                entities/    # Pure Dart business entities (no Flutter imports)
                repositories/# Abstract repository interfaces
                usecases/    # Single-responsibility business use cases
            presentation/
                controllers/ # Riverpod Notifier / BLoC / Cubit
                states/      # Immutable UI states (Loading, Success, Error)
                screens/     # Screen widgets
                widgets/     # Feature-specific sub-widgets
        history/
        settings/
    main.dart                # App entrypoint (initialization & runApp)
```

### Unidirectional Data Flow (UDF):
- State is single-source-of-truth, exposed as immutable streams/states.
- UI dispatches events/intents to controllers/blocs.
- Controllers invoke Domain Use Cases, interact with Repositories, and emit new UI states.
- Side-effects (Toasts, Snackbars, Dialogs, Navigation) are triggered cleanly via listeners or one-shot events.

────────────────────────────────────────
⚡ State Management Standards
────────────────────────────────────────

- Standardize on modern, scalable state management: **Riverpod** (recommended) or **BLoC / Cubit**.
- Never keep application business logic inside `StatefulWidget.setState()`:
  - `setState()` is strictly reserved for ephemeral, widget-internal animations or local UI toggles (e.g. dropdown expanded state).
- Ensure all asynchronous calls handle three core states:
  1. **Loading** (with shimmer skeletons)
  2. **Success** (with content or empty state)
  3. **Error** (with user-friendly message and retry action)
- Always cancel timers, stream subscriptions, and text editing controllers in `dispose()`.

────────────────────────────────────────
🎨 Material 3 Design System & Rich Aesthetics
────────────────────────────────────────

Every Flutter app must look visually stunning, polished, and premium. Never produce plain, un-styled prototypes.

- **Centralized Design System**:
  - `AppColors`: Semantic palettes (Primary, Secondary, Surface, Background, Success, Danger, Warning, Info) with accessible contrast (WCAG AA).
  - `AppTheme`: Both `lightTheme` and `darkTheme` defined in `ThemeData(useMaterial3: true)`.
  - `AppTypography`: Clear hierarchy using Google Fonts (Inter, Outfit, Poppins, Plus Jakarta Sans) over system defaults.
  - `AppSpacing`: 4px/8px rhythm (`xs = 4.0`, `sm = 8.0`, `md = 16.0`, `lg = 24.0`, `xl = 32.0`).
  - `AppRadius`: Standardized corner radii (e.g., `radiusSm = 8.0`, `radiusMd = 12.0`, `radiusLg = 16.0`, `radiusPill = 999.0`).
- **Surface Elevation & Glassmorphism**:
  - Use subtle borders (`Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5))`) combined with soft box shadows for cards.
  - Apply frosted glass (`BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10))`) on modals and floating bottom bars.
- **Empty & Error States**:
  - Never display raw blank views or empty tables.
  - Display well-crafted empty state widgets with contextual vector icons, supportive copy, and a primary CTA.
- **Skeleton Shimmer Loading**:
  - Use shimmer gradient sweeps (e.g. `shimmer` package) during async data fetches instead of intrusive full-screen circular progress indicators.

────────────────────────────────────────
🎭 Animations & Micro-Interactions (60/120 FPS)
────────────────────────────────────────

- **Micro-Interactions**:
  - Tactile feedback on button presses (scale bounce `Transform.scale(scale: 0.97)` on tap).
  - Interactive switches, animated checkboxes, and smooth badge fades.
- **Hero Transitions**:
  - Use `Hero` widgets for seamless list-to-detail image/card transitions.
- **State Transitions**:
  - Use `AnimatedSwitcher`, `AnimatedContainer`, and `AnimatedOpacity` for fluid content updates without abrupt layout jumps.
- **Performance**:
  - Avoid rebuilding complex widget subtrees: use `const` widgets, extract smaller widgets, and pass pre-built child widgets into animated builders.
  - Respect user motion preferences: check `MediaQuery.of(context).disableAnimations`.

────────────────────────────────────────
🗄 Local Persistence & Offline-First
────────────────────────────────────────

- Use robust local storage solutions:
  - **Drift / sqflite**: For relational database queries, transactions, and indexing.
  - **Hive / Isar**: For ultra-fast NoSQL key-value / document caching.
  - **flutter_secure_storage**: For auth tokens, API secrets, and encryption keys (backed by Android Keystore and iOS Keychain).
  - **shared_preferences**: For non-sensitive user preferences (e.g. dark mode, locale).
- Return reactive streams (`Stream<List<Entity>>` or `watch()`) so the UI updates automatically when local records change.
- Never write unhandled database operations on the main thread.

────────────────────────────────────────
🔤 Text Casing & Normalization Standards
────────────────────────────────────────

- Primary catalog metadata (e.g. invoice codes, product codes, SKUs, serial numbers, customer tax IDs, status codes) must be sanitized and converted to **UPPERCASE** at the repository/domain layer before persisting to local storage or sending to APIs.
- Input fields capturing codes/identifiers must use `textCapitalization: TextCapitalization.characters` or `UpperCaseTextFormatter` for real-time visual uppercase feedback.
- **CSV / Excel Injection Guard**: Strip or sanitize leading `=`, `+`, `-`, `@` characters from any exported cell value to prevent formula-injection attacks.
- Do not apply uppercase normalization to emails, passwords, usernames, remarks, or freeform descriptions.

────────────────────────────────────────
🔐 Mobile Security & Privacy Standards
────────────────────────────────────────

- **Zero Hardcoded Secrets**: Store API endpoints and keys in `.env` (via `flutter_dotenv`) or `--dart-define` / `--dart-define-from-file`.
- **Network Security**: Enforce HTTPS for all network operations. Implement Certificate Pinning on financial/sensitive endpoints.
- **Platform Permissions**:
  - Request runtime permissions at the point of need with clear explanation dialogs.
  - Minimize requested permissions in `AndroidManifest.xml` and `Info.plist`.
- **Release Hardening**:
  - Enable code shrinking, resource shrinking, and ProGuard / R8 in Android (`build.gradle.kts`).
  - Build release artifacts with Dart symbol obfuscation:
    `flutter build apk --release --obfuscate --split-debug-info=./build/app/outputs/symbols`

────────────────────────────────────────
🧪 Testing & Code Quality
────────────────────────────────────────

- **Skip Automatic Tests**: Do **NOT** automatically run `flutter test` after code changes or edits. Only execute tests on-demand when the user explicitly requests it (e.g. *"run tests"* or *"test this"*). Keep verification fast and lightweight.
- **Unit Tests (`test/`)**: Test all business logic, Domain Use Cases, formatters, and repository data mappings with `flutter_test`.
- **Widget Tests**: Verify critical UI interactions, forms, and error states using `testWidgets()`.
- **Code Analysis**: Every commit must pass `flutter analyze` with **0 errors and 0 warnings**.
- **Formatting**: Run `dart format .` to maintain uniform code formatting across all files.

────────────────────────────────────────
📦 Build & CI/CD Packaging
────────────────────────────────────────

- Ensure both **v1 (JAR)** and **v2 (Full APK)** signing are enabled for Android releases.
- Maintain automated GitHub Actions CI/CD workflows for building release APKs (`.apk`) and App Bundles (`.aab`).
- Keep builds clean, reproducible, and verifiable.
