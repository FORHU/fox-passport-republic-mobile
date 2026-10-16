# FoxPassport Mobile

Flutter app (package name `flutter_template`) for FoxPassport. It is the phone
version of the web app `fox-passport-republic-app` and talks to
`fox-passport-republic-api` (`/api/v1`, port 6002).

## Design — read before building or restyling any screen

- **`docs/mobile-design.md` is the source of truth for how the app looks**:
  dark canvas, lime accent, same as the web app. Read it first.
- **`docs/mockups/*.html`** are the layout and copy reference for the screens
  designed so far (welcome carousel, auth, home, search, venue detail, tickets,
  passport, messages, venue booking flow). Match them.
- The app shares the web's brand but not its page layouts. Screens behind
  sign-in follow the rules in section 6 of the design spec.
- `THEMING.md` and section 1 of `DESIGN_SYSTEM_AND_INTEGRATION.md` describe the
  old ink-on-white look. They are **superseded**; do not follow them for
  colours, fonts or component styling. Parts of `lib/theme` and the auth
  screens still use the old look and are to be migrated (see section 1 of the
  design spec).
- Colours and text styles go through the theme tokens (`lib/theme/tokens`),
  never hard-coded in widgets.

## Scope and plan

- `docs/CITIZEN_CORE_PORT_PLAN.md` — screen list, API mapping, milestones and
  progress. Bottom bar is to become Home · Search · Tickets · Messages ·
  Passport (the code still has Profile as the fifth tab).
- `docs/BACKEND_INTEGRATION.md` and `SYSTEM_ARCHITECTURE.md` — API and
  architecture.

## Conventions

- Clean architecture per feature: `lib/features/<name>/{data,domain,presentation}`.
- Riverpod controllers, `fpdart` `Either` for failures, `go_router` for routes.
- User-facing strings go through `lib/l10n`.
- Finish a change with `flutter analyze` clean and `flutter test` passing.
- Flutter web dev runs on port 8085: `flutter run -d chrome --web-port=8085`.
