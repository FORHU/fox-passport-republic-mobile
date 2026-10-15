# FoxPassport Republic Mobile Rules

## 1. Mandatory Branching & Checkpoint Safety
- **Dedicated Branches**: Before modifying or creating code for any feature, bug fix, or optimization, inspect the current Git state and create or check out a dedicated branch (e.g., `feat/<name>`, `fix/<name>`, `perf/<topic>`). Never develop directly on `main` or `master`.
- **Protect Existing Work**: Run `git status` and `git diff` before taking action. Never automatically stash, commit, reset, clean, or discard another developer's uncommitted work.
- **Dirty Working Trees**: If changes can be cleanly isolated without disturbing existing work, proceed on a dedicated branch. If changes overlap or isolation is unclear, ask for clarification before editing existing files.
- **Baseline Checkpoints**: For risky, multi-step, or architectural changes, commit or tag a clean, recoverable baseline. Never include unrelated changes in a checkpoint.

---

## 2. Flutter & Dart Standards
- **SDK & Dependencies**: Target Dart SDK `>=3.5.0 <4.0.0` (verified in `pubspec.yaml`) and Flutter SDK. Inspect `pubspec.yaml` before adding dependencies; prefer existing packages (`dio`, `flutter_riverpod`, `fpdart`, `go_router`) over introducing redundant libraries.
- **Strict Null Safety**: Preserve Dart null safety. Avoid raw `dynamic`, force unwrapping (`!`), and unsafe casts when typed alternatives exist.
- **Async & Lifecycle Safety**: Always check `mounted` or handle controller lifecycle before updating UI state across async gaps. Prevent memory leaks on controllers, streams, and animations.
- **Localization**: User-facing strings must never be hard-coded; route all copy through `lib/l10n/` ARB files and run `flutter gen-l10n`.

---

## 3. Architecture & State Management (Riverpod + Clean Architecture)
The repository enforces Clean Architecture per feature under `lib/features/<name>/`:
- **Data Layer (`data/`)**:
  - `datasources/`: Dio-backed HTTP requests (`ApiService`).
  - `models/`: DTOs with manual `fromJson` / `toJson` serialization matching the API schema.
  - `repositories/`: Implement domain repository interfaces, catch typed `AppException`, and return `Either<Failure, T>`.
- **Domain Layer (`domain/`)**:
  - `entities/`: Pure Dart models free of third-party or framework dependencies.
  - `usecases/`: Single-responsibility callable classes invoking repositories.
- **Presentation Layer (`presentation/`)**:
  - `controllers/`: Riverpod `Notifier` or `AsyncNotifier` managing immutable state. Presentation `.fold()`s `Either` results; **never use `try/catch` in UI widgets**.
  - `pages/` & `widgets/`: Pure presentation consuming Riverpod providers (`ConsumerWidget`, `ConsumerStatefulWidget`).
- **Feature Isolation Rule**: Features under `lib/features/` must **never import each other**, except for the shared `auth` feature. Shared non-feature utilities belong in `lib/core/` or `lib/shared/`.

---

## 4. Navigation & Application Routing
- **GoRouter Declarative Routing**: Use `go_router` conventions defined in `lib/routes/app_routes.dart` and `route_names.dart`.
- **Auth Guard & Session Redirects**: Preserve top-level redirect logic watching `authControllerProvider`. Do not duplicate redirect checks in individual pages.
- **State Preservation**: Preserve tab index, scroll positions, and form state where appropriate. Avoid destructive `context.go()` navigation when pushing/popping views.

---

## 5. API Integration & Authentication (Better Auth & Dio)
- **Backend as Source of Truth**: The `fox-passport-republic-api` (`/api/v1`, default port 6002) is the authority on models, status enums, permissions, and validation.
- **Session & Token Storage Handling**:
  - The client supports both cookie-based Better Auth session management (via `CookieService` / `dio_cookie_manager`) and bearer token attachment via `AuthInterceptor` (`_storage.readToken()`).
  - Follow the established implementation and backend contract: **do not assume every request requires an explicit bearer token**, and do not assume tokens must always be manually stored when cookie-based sessions are active.
  - When tokens or persistent credentials are used, store them exclusively via `StorageService` (`flutter_secure_storage`). Never store tokens or secrets in `SharedPreferences` or ordinary logs.
- **No Custom JWT Schemes**: Better Auth is the primary authentication system. Do not invent custom JWT signing, refresh schemes, or ad-hoc headers not supported by the backend contract.

---

## 6. Design System & UI/UX Standards
- **Source of Truth for Styling**: Follow `docs/mobile-design.md` (dark canvas `#0A0A0A`, lime accent `#CEFF00`, high-contrast typography). Note: `THEMING.md` is superseded.
- **Theme Tokens**: Consume styles exclusively from `lib/theme/tokens/` (`AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`). Never hard-code hex colors or ad-hoc margins.
- **Reusable Components**: Prefer components in `lib/shared/widgets/` (`AppButton`, `AppInput`, `AppCard`) over building one-off primitives.
- **State Feedback**: Every asynchronous screen must provide explicit UI treatments for loading (skeletons/spinners), error (actionable retry), and empty states.

---

## 7. Data Integrity & Offline Considerations
- **No Authoritative Local Mutations**: Treat cached data as transient. Never assume local state is authoritative for tickets, bookings, payments, or capability permissions.
- **Clean Invalidation**: Invalidate or refetch affected Riverpod providers after executing data mutations (e.g., `ref.invalidate(...)`).
- **Safe Logout Wipe**: Clear all secure storage and in-memory caches upon user sign-out to prevent credential or profile leakage.

---

## 8. Testing & Code Quality
- **Static Analysis**: Enforce `very_good_analysis` rules (`analysis_options.yaml`). Do not add `// ignore:` comments without explicit rationale.
- **Unit & UseCase Tests**: Verify repositories, use cases, and Riverpod controllers using `mocktail` for mocks.
- **Widget Tests**: Test screen rendering, loading states, error states, and user interactions with mocked dependencies.
- **Deterministic Tests**: Mock all network calls via `mocktail` or `MockInterceptor`. Never hit live endpoints in automated tests.

---

## 9. Scope Control & Task Discipline
- **Minimal Scope**: Avoid unsolicited refactorings, mass reformatting, or updating dependencies in `pubspec.yaml` unless required by the task.
- **Generated Code**: Run code generators (`flutter gen-l10n`) rather than hand-editing generated files.

---

## 10. Proportional Pre-Completion Verification
Run verification checks appropriate to the scope of your changes:
1. `flutter gen-l10n` — Verify localization generation (required when touching `.arb` files or localizable copy)
2. `dart format --output=none --set-exit-if-changed .` — Check formatting
3. `flutter analyze` — Run static analysis (must be 0 errors/warnings)
4. Feature isolation scan — Verify no cross-feature imports outside `auth`
5. `flutter test` — Run automated tests (full suite for substantial changes, targeted test files for minor changes)

**Proportional Execution & Reporting Requirements**:
- **Substantial changes** (architectural, auth, routing, core services): Run all 5 checks.
- **Localized / Small changes** (single widget styling, minor bug fix, text change): Run relevant checks (e.g., `flutter analyze` and targeted test) and explicitly note any skipped checks with rationale.
- For each check, categorize as:
  - **Passed**: Clean execution.
  - **Failed (Changes)**: Failed due to recent changes (must be fixed).
  - **Pre-existing Failure**: Unrelated failure that existed prior to this task.
  - **Skipped**: Deliberately skipped due to localized scope (reason required).
  - **Blocked**: Tooling or environment unavailable (e.g., missing Flutter SDK on host).
*Never misrepresent a skipped or blocked check as passed.*

---

## 11. Mandatory Completion Report
Before concluding any task, provide a structured completion report:
- **Branch**: Dedicated branch used.
- **Changes**: Summary of what was implemented or resolved.
- **Files**: Key files created, modified, or removed.
- **API & Authentication**: Backend contract, Dio interceptor, cookie session, or secure storage implications.
- **Data & State**: Riverpod controllers, models, or state changes.
- **Verification**: Exact status of checks (`Passed`, `Failed`, `Pre-existing`, `Skipped`, or `Blocked`) with reasons for any skipped items.
- **Remaining Work**: Known limitations, follow-up tickets, or platform-specific considerations (iOS/Android).

*Never declare a task complete when required verification remains unsuccessful or unperformed.*

