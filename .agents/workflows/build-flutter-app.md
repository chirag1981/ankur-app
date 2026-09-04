---
description: Build high-performance Flutter mobile application from scratch using Dart 3, Clean Architecture, Riverpod/BLoC, Material 3, and CI/CD APK packaging.
---

────────────────────────────────────────
🧠 Core Execution Philosophy (Karpathy Principles)
────────────────────────────────────────

1. **Think Before Coding**: Never assume or hide ambiguity. State architecture decisions, state management, dependencies, and target platforms explicitly before modifying files.
2. **Simplicity First**: Write clean, idiomatic Dart with sound null safety. Avoid premature complexity or excessive boilerplate.
3. **Surgical Precision**: Touch only the exact files, widgets, and providers required. Never reformat unrelated files or break working configurations.
4. **Read Before Writing**: Inspect existing models, repositories, and theme tokens before creating duplicates.
5. **Goal-Driven Verification**: Define success criteria upfront and verify with `flutter analyze`, unit/widget tests, and signed APK artifact generation before declaring completion.


# Build Flutter App From Scratch (Dart & Material 3 Edition)

## Description

An end-to-end, production-grade workflow to design, architect, code, secure, test, and package cross-platform mobile applications in **Flutter 3.x** and **Dart 3.x** with **Material 3**, **Clean Architecture**, and **Offline-First Persistence**.

---

# Phase 1. Requirements & Flutter Environment Analysis

### Analysis & Scoping
Determine:
- Target Platforms: Android, iOS, Web, Desktop.
- State Management: **Riverpod** (recommended) or **BLoC / Cubit**.
- Local Storage: **sqflite / Drift** (relational) or **Hive / Isar** (NoSQL / fast cache).
- App Type: Standalone Offline-First, Client-Server (REST/GraphQL), or Hybrid.
- Clarification questions covering:
  1. Main user journeys & offline data requirements.
  2. Native capabilities required (Camera, Biometrics, PDF generation, WhatsApp sharing, Thermal Printing).
  3. Visual branding mood & preferred color palette (e.g., "Indigo SaaS", "Emerald Fintech", "Material 3 Dynamic").

Summarize requirements and obtain user approval before generating the technical plan.

---

# Phase 2. Architecture & Technical Plan

Generate a comprehensive implementation plan artifact detailing:

## 1. Dependency & Module Strategy
- `pubspec.yaml` with pinned package versions (e.g. `flutter_riverpod`, `go_router`, `drift`/`sqflite`, `flutter_secure_storage`, `pdf`, `share_plus`, `intl`).
- Feature-First Clean Architecture (`core/`, `features/`, `app/`).
- Routing strategy (`go_router`).

## 2. Data & Domain Modeling
- Domain Entities (pure Dart objects with immutability).
- Data Models with JSON/DB serialization (`freezed` or standard immutable models).
- Repository contracts (abstract classes) and concrete implementations.

## 3. State Management & Navigation Flow
- Riverpod Providers / AsyncNotifiers (or BLoC/Cubit).
- Immutable UI states (`Loading`, `Success(data)`, `Empty`, `Error(message)`).
- Route map and deep link declarations.

## 4. Security & Permissions Checklist
- Android Keystore / iOS Keychain (`flutter_secure_storage`).
- Runtime permissions strategy (`permission_handler`).
- Android manifest hardening (`exported="false"`, network security config).

*Pause and wait for user approval before scaffolding.*

---

# Phase 2A. Flutter Material 3 Design System

Before building screens, establish the design system in `lib/app/theme/`:

1. **`app_colors.dart`**: Curated, WCAG AA compliant palette (Primary, OnPrimary, Surface, Background, Success, Error, Warning).
2. **`app_typography.dart`**: Google Fonts typography scale (`displayMedium`, `headlineSmall`, `titleMedium`, `bodyMedium`, `labelSmall`).
3. **`app_spacing.dart`**: Consistent spacing tokens (`xs = 4.0`, `sm = 8.0`, `md = 16.0`, `lg = 24.0`, `xl = 32.0`).
4. **`app_theme.dart`**: Light and Dark `ThemeData(useMaterial3: true)` with refined card elevations, input decorations, and smooth page transitions.
5. **Reusable Atoms (`lib/core/widgets/`)**:
   - `AppPrimaryButton` with tactile press bounce animation.
   - `AppCard` with subtle borders, gentle shadows, and optional glassmorphic backdrop.
   - `AppEmptyState` with vector icon, supportive copy, and action button.
   - `AppShimmer` skeleton loader for async states.

---

# Phase 3. Project Scaffolding & Setup

Initialize or configure the Flutter project:
```bash
flutter create --org com.vendor.invoice --platforms android,ios app
```

Directory structure:
```
lib/
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── feature_a/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
└── main.dart
```

Verify setup:
```bash
flutter pub get
flutter analyze
```

---

# Phase 4. Data Layer & Persistence Development

Implement:
- Database tables, DAOs, and queries with reactive streams.
- Repository layer implementing Domain interfaces (Single Source of Truth).
- Key-value preferences (`shared_preferences`) for settings.
- Secure storage (`flutter_secure_storage`) for sensitive credentials.
- Unit tests for local database operations and repository mappings.

### Database Backup & Restore Standard (Offline-First Resiliency)
- **Export / Backup**:
  - Checkpoint WAL (`PRAGMA wal_checkpoint(FULL)`).
  - Snapshot active database into `[AppName]_Backup_YYYYMMDD_HHMMSS.db`.
  - Native Share Sheet (`share_plus`) integration for 1-tap sharing to Google Drive, WhatsApp, Email, or local storage.
  - Optional direct copy to public `/storage/emulated/0/Download`.
- **Import / Restore**:
  - Use native Android `MethodChannel` (`Intent.ACTION_OPEN_DOCUMENT`) in `MainActivity.kt` to avoid third-party plugin/Gradle version mismatches.
  - Pre-restore validation: verify required SQLite tables exist before touching active data.
  - Atomic swap: close active DB, clean temporary `-wal`/`-shm` files, overwrite, and re-open.
  - State refresh: immediately invalidate Riverpod/BLoC state caches to reflect restored records without restarting the app.

---

# Phase 5. Domain & State Management Development

Implement:
- Pure Dart Domain Use Cases.
- State controllers (`AsyncNotifier` or `Bloc`) emitting immutable UI states.
- Asynchronous error handling with typed `Failure` classes.
- Reactive state updates on database stream changes.

---

# Phase 5A. Mobile Security Hardening Pass

Perform mandatory security check:
- [ ] No hardcoded API keys, tokens, or passwords in Dart code.
- [ ] Sensitive tokens saved in `flutter_secure_storage`.
- [ ] Android components explicitly secured in `AndroidManifest.xml`.
- [ ] `cleartextTrafficPermitted="false"` for production network security.
- [ ] Storage Access Framework / Photo Picker used instead of broad storage permissions.
- [ ] Android ProGuard / R8 rules configured to prevent reverse-engineering.

---

# Phase 6. UI Layer & Presentation Screens

Build user interface screens using Phase 2A Design System:
- Navigation bar / drawer responsive layout.
- High-performance scrollable lists using `ListView.builder` or `CustomScrollView` with unique keys.
- Form inputs with inline validation and uppercase formatting where required.
- Empty states and animated skeleton shimmer loaders.
- Modal bottom sheets and confirmation dialogs for destructive actions.

---

# Phase 7. UI/UX & Flutter Performance Review

Audit the application performance:
- Maintain 60/120 FPS: minimize widget rebuilds with `const` constructors and localized listeners.
- Verify safe area and soft keyboard insets (`resizeToAvoidBottomInset: true`).
- Test Dark Mode and Light Mode contrast and legibility.
- Test state persistence across screen rotations and app lifecycle changes.

---

# Phase 8. Integration & Automated Testing

Run automated test suite:
```bash
flutter test
```
- Unit tests for Use Cases, Repositories, and formatters.
- Widget tests for critical user flows and error feedback.

---

# Phase 8A. Mobile Bug-Fix Loop (Runs to Convergence)

1. **Collect**: Run `flutter analyze` and `flutter test`, gather compiler warnings, exceptions, or layout overflows (RenderFlex).
2. **Triage**:
   - **Critical**: Crash, data loss, unhandled async exceptions.
   - **Major**: State desync, broken navigation, layout overflow errors.
   - **Minor**: Cosmetic misalignment, padding quirks.
3. **Fix Critical & Major issues first.**
4. **Re-test downstream components** after every state or database modification.
5. **Repeat** until zero Critical/Major issues remain.

---

# Phase 9. Build Verification & Device/Emulator Testing

Execute build and test APK generation:
```bash
flutter build apk --debug
```
Inspect:
- Zero build errors.
- Both v1 and v2 signing present for reliable sideloading.

---

# Phase 10. Code Quality & Lint Audit

- Run static code analysis:
  ```bash
  flutter analyze
  ```
- Format all files:
  ```bash
  dart format .
  ```
- Ensure zero warnings, dead code removed, and unused dependencies cleaned up.

---

# Phase 11. Documentation

Update `README.md`:
- Architecture overview (Clean Architecture + Riverpod).
- Prerequisites (Flutter 3.x, Dart 3.x, Android SDK).
- Setup & run commands (`flutter pub get`, `flutter run`, `flutter build apk`).
- Key features, database structure, and WhatsApp / PDF export workflow.

---

# Phase 12. Final Release Validation Checklist

✓ App compiles with zero Flutter errors (`flutter analyze` clean)
✓ Database operates with reactive streams and offline-first reliability
✓ State management handles Loading / Content / Empty / Error gracefully
✓ Edge-to-edge UI renders smoothly with responsive insets
✓ Dark theme and Light theme render with WCAG AA compliance
✓ Unit and widget tests pass (`flutter test`)
✓ Security checklist (Phase 5A) passed with zero open issues
✓ Bug-Fix Loop (Phase 8A) converged
✓ Database Backup & Restore verified (Export to Google Drive/WhatsApp & safe restore with table validation and UI cache refresh)
✓ Android v1 & v2 signing verified for sideloading

---

# Phase 13. CI/CD & Production Build Packaging

1. Create/update GitHub Actions workflow (`.github/workflows/build-apk.yml`):
   - Set up Java 17 and Flutter SDK.
   - Run `flutter pub get`, `flutter analyze`, and `flutter test`.
   - Build signed Release APK:
     ```bash
     flutter build apk --release --split-per-abi
     ```
   - Upload APK artifacts to GitHub Releases / Actions.
