# FoxPassport Republic Mobile Rules

## Branching: Continuous Staging and On-Demand Main Synchronization

> This section takes precedence over any other branch or pull-request-target instruction in this file.
> `main` is this repository's production branch.

The development workflow is continuous and is not restricted to a daily schedule, a single task, or a fixed number of tasks.

- Before beginning a new development cycle, inspect the relationship between `main` and `staging` and synchronize them when necessary.
- All task branches must originate from the latest `staging`.
- Completed tasks must be submitted through PRs targeting `staging`.
- Developers may continue starting and completing additional tasks for as long as needed.
- Do not synchronize `staging` into `main` automatically after each task, after a fixed time interval, or simply because the day has ended.
- Synchronize `staging` into `main` only when the team explicitly decides that the accumulated changes are ready for delivery.
- Before synchronization, validate the combined changes and complete all required reviews and checks.
- Never merge unfinished or known-broken changes into `main`.
- After synchronization, verify the resulting branch state before continuing.
- **When a task is done, ask the repository owner / team lead whether it is all good.** They decide whether it merges and when `staging` is synchronized; an agent's or author's own judgment is not approval.
- **Check deploy triggers before merging into `staging`:** some repos deploy on pushes to `staging` (see `.github/workflows/`). Merging is a deployment decision, not just a code review.
- **Project board:** move the item through the product's GitHub Project — Backlog → To-Do → In progress → Done.

**Workflow:** Establish baseline → Develop tasks → Merge completed tasks into staging → Continue working or synchronize to main when ready → Repeat.

`staging` is the continuous integration branch. `main` is updated on demand when the team chooses to deliver the accumulated changes.

```bash
# Start a task
git fetch origin
git log --oneline origin/main..origin/staging   # what staging has that main doesn't
git checkout staging && git pull
git checkout -b <type>/<short-description>      # feat/, fix/, docs/, test/, chore/ ...

# Finish a task: open a PR into staging (never into main)
gh pr create --base staging

# Deliver (only when the owner decides): one PR from staging into main
gh pr create --base main --head staging
```

## 1. Git Branching and Work Safety

### Inspect Before Editing
- Before making any changes, inspect `git status`, the current branch, and `git diff`.
- Check for uncommitted changes and understand whether they belong to the current task.
- Never discard, reset, clean, stash, or commit existing work without explicit authorization.

### Dedicated Branches Are Mandatory
- Before implementing a new feature, bug fix, refactor, optimization, or other code change, create or switch to a dedicated task branch.
- Never develop directly on `main`, `master`, or a shared integration branch.
- Use descriptive branch names:
  - `feat/<short-description>` — new features
  - `fix/<short-description>` — bug fixes
  - `perf/<short-description>` — performance improvements
  - `refactor/<short-description>` — refactoring
  - `docs/<short-description>` — documentation
  - `test/<short-description>` — tests

### Preserve Existing Work
- If the current branch contains unrelated uncommitted changes, do not automatically commit, stash, or move them.
- If the task can be safely isolated, create the task branch while preserving the existing working tree.
- If existing changes overlap with the requested task or their ownership is unclear, stop and ask for clarification before editing.
- Before switching branches, check whether doing so could carry uncommitted changes into another task.

### Branch Creation and Checkpoints
- Check whether the intended branch already exists before creating it.
- If it exists, inspect its status and history before deciding whether to reuse it.
- Never reset or overwrite an existing branch to make it match a preferred starting point.
- For risky or multi-step changes, establish a recoverable baseline when the working tree is clean and it is safe to do so. Do not commit unrelated changes to create a checkpoint.

### Completion
- Report the branch used in the task completion summary.
- Do not merge into protected or shared branches, push changes, or open a pull request unless requested or authorized by the project's workflow.
- **Never delete branches (local or remote):** Do not delete any branch (`git branch -d`, `git branch -D`, or `git push --delete`), even after a merge or PR is completed, unless explicitly instructed by the user. Preserve all branches for audit trails, rollback, and recovery.

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
- **Better Auth Session Contract**:
  - The backend uses Better Auth as its primary authentication system.
  - Better Auth validates sessions via `auth.api.getSession`, which accepts either HTTP cookies or `Authorization: Bearer <better_auth_session_token>`.
  - The mobile client manages session cookies via `dio_cookie_manager` and can pass the session token in the `Authorization: Bearer` header via `AuthInterceptor` (`_storage.readToken()`).
  - When storing the session token, use `StorageService` (`flutter_secure_storage`). Never store tokens in `SharedPreferences` or log them in plaintext.
- **No Custom JWT Schemes**: Do not introduce custom JWT signing, custom refresh endpoints, or non-standard token schemes. Both mobile and API standardize on Better Auth session tokens.

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

