# Citizen Core — Web → Flutter Port Plan

Status: proposed, for review before implementation.
Source: `fox-passport-republic-app` (Next.js, port 6001). Target: this repo.
API: `fox-passport-republic-api` (`/api/v1`, port 6002).

Scope of this slice: the **Citizen** journey end to end — sign in, discover,
view detail, book, pay, hold a ticket, track Passport, get notified.
Foxer, creator-dashboard, mayor and admin are out of scope here.

Web-only UI is **redesigned for phone**, not ported 1:1 (bottom sheets, cards
instead of tables, single-column flows, thumb-reach actions).

---

## 1. Screens

| # | Mobile screen | Web source | Notes for phone |
|---|---|---|---|
| 1 | Sign in / Register / Verify OTP / Forgot + Reset | `/auth`, `features/auth` | Existing login/register pages kept; add verify-email OTP, forgot/reset |
| 2 | Home (feed of recommendations, upcoming) | `/`, `/user` dashboard hooks | Replace template home; sections as horizontal carousels |
| 3 | Search / Browse | `/search`, `features/search` | Search bar + filter bottom sheet; sections: events, venues, gear, services, foxers |
| 4 | Event detail | `/event/[eventId]`, `/booking/[id]` | Hero, sticky "Book" bar, collapsible supplier list |
| 5 | Venue detail | `/booking/venue/[id]` | Replace `BookingWidget` with sticky bottom CTA + availability calendar sheet |
| 6 | Asset / Service detail + booking | `/booking/asset/[id]`, `/booking/service/[id]` | Price preview inline |
| 7 | Booking flow (attendees → pay → success) | `/booking/*`, `/checkout/*` | Stepper; single column |
| 8 | My bookings / ticket (QR) | `/user`, `bookings/upcoming` | Ticket card with `ticketCode` QR; cancel with eligibility check |
| 9 | Passport (stamps, badges, leaderboard) | `/user/passport`, `features/gamification` | Badge grid + progress ring |
| 10 | Saved / Favorites | `/republic/saved` | List with swipe-to-remove |
| 11 | Notifications | `/notifications` | List, mark read / read-all |
| 12 | Profile & settings | `/user/settings`, `/user/[id]` | Extend existing profile page; opened from Passport, no longer a tab |
| 13 | Map (venues near me) | `features/venue` (Mapbox/Cesium) | Native map with venue pins + bottom sheet list; **no Cesium globe** |
| 14 | Messages (inbox, chat) | `/messages`, `features/messages` | **Added 2026-10-13.** Own tab; design in `docs/mobile-design.md` section 7 |

Out of this slice: calendar, reviews, scanner/check-in (Foxer side),
KYC, investments.

---

## 2. API mapping

All paths relative to `BASE_URL` (`/api/v1`). Response envelope:
`{ status, statusCode, data, message }` (already handled by `ApiService`).

| Area | Calls (from web `src/**/api`) |
|---|---|
| Auth | `POST /auth/login`, `/auth/register`, `/auth/verify-email`, `/auth/resend-verification-otp`, `/auth/forgot-password`, `/auth/reset-password`, `/auth/refresh-token`, `/auth/logout` |
| Profile | `GET /profile`, `GET /users/profile/:idOrUsername`, `POST /profile/change-password` |
| Browse | `GET /event-templates/browse`, `/event-templates/browse/:id`, `/event-templates/recommendations`, `/asset/browse`, `/service/browse`, `/users/foxers`, `/venues`, `/venues/near`, `/venues/catalog`, `/venues/:id`, `/venues/:id/unavailable-dates`, `/categories` |
| Search | same browse endpoints with `q`/filter params; aggregate client-side (web `fetchAllSearchSections`) |
| Booking | `POST /bookings/draft`, `PUT /bookings/:id/attendees`, `POST /bookings/from-template`, `GET /bookings/:id`, `GET /bookings/upcoming`, `POST /bookings/:id/cancel/check`, `POST /bookings/:id/cancel` |
| Asset/Service booking | `GET /asset/bookings/price-preview`, `GET /service/bookings/price-preview`, `POST /asset/bookings`, `POST /service/bookings`, `POST .../:id/confirm`, `GET .../:id` |
| Payment | `POST /payments/create-intent`, `POST /bookings/:id/confirm` (Stripe) |
| Passport | `GET /passport/me`, `/passport/badges`, `/passport/:userId`, `/passport/leaderboard` |
| Favorites | `GET /favorites/user/:userId` (+ add/remove — confirm in `shared/api/favorites.ts`) |
| Notifications | `GET /notifications`, `PATCH /notifications/:id/read`, `PATCH /notifications/read-all` |
| Messages | `GET /conversations`, `GET/POST /conversations/:id/messages`, `PATCH /conversations/:id/read`, `POST /conversations/:id/accept`, `/decline` |

Existing `ApiEndpoints` in `lib/core/constants/api_endpoints.dart` needs
extending; the current `/stores/nearby` and `/quiz/*` entries are template
leftovers and should be removed once their features are retired.

---

## 3. Mobile architecture

Keep the repo's existing clean architecture per feature
(`data/ domain/ presentation/`), Riverpod controllers, `fpdart` `Either`,
`go_router`. New feature folders:

```
lib/features/
  auth/            (extend: verify OTP, forgot/reset)
  browse/          (events, venues, assets, services, foxers, categories)
  search/
  event_detail/
  venue_detail/
  booking/         (draft, attendees, price preview, cancel)
  payment/         (Stripe intent + confirm)
  tickets/         (my bookings, QR)
  passport/
  favorites/
  notifications/
  profile/         (extend)
```

Shell navigation (bottom bar): **Home · Search · Bookings · Messages ·
Passport** (decided 2026-10-15; built today as Home · Search · Map · Messages
· Passport). Map becomes a List / Map switch inside Search; Bookings holds
tickets, requests and the calendar; profile and settings open from Passport.
Details in `docs/mobile-design.md` section 6. Notifications via app-bar bell. Replace template routes (`quiz`,
`recommendations`, `cart`, `worldMap`) as each real feature lands.

---

## 4. Web-only → phone decisions

| Web component | Phone treatment |
|---|---|
| Cesium globe / spatial views | Dropped. Mapbox-style map becomes `flutter_map` (OSM) or `mapbox_maps_flutter` — **decision needed** |
| `BookingWidget` (sticky sidebar) | Sticky bottom bar → full-height sheet |
| `AvailabilityCalendar` | Month sheet, range select, blocked dates greyed |
| `SearchFilters` (sidebar) | Filter bottom sheet with chips + apply |
| Wide tables/cards grids | Single-column cards / horizontal carousels |
| `StripePaymentForm` | `flutter_stripe` PaymentSheet |
| Hover states / tooltips | Removed; tap-through detail |
| `html5-qrcode` scanner | Not in citizen slice (ticket shows QR; scanning is Foxer) |

---

## 5. Cross-cutting

- **Auth transport:** web uses cookies; mobile uses Bearer + refresh via
  secure storage (already built). Confirm the API accepts Bearer on every route
  listed above.
- **CORS (Flutter web dev only):** API `CORS_ORIGIN` is pinned to `:6001`.
  Either add the Flutter dev port to API config or run Flutter web on a
  whitelisted port.
- **Models:** derive Dart models from web `types.ts` files
  (`features/*/types`), validate against API Prisma schema where they disagree
  (schema wins, per `CONTEXT.md`).
- **Roles:** Citizen = `systemRole: user`, `roleType: []`. This slice assumes
  Citizen only; expose `roleType` on the user entity now so the Foxer slice can
  gate on it later.
- **Tests:** unit-test datasources/repositories with `mocktail`; widget-test
  each screen's loading / error / empty / data states.

---

## 6. Build order (milestones)

1. **Foundation** — extend `ApiEndpoints`, shell nav, shared card / sheet /
   state widgets, env + CORS sorted so Flutter web hits the API.
2. **Auth complete** — verify OTP, forgot/reset, role on user entity.
3. **Browse + Search** — events, venues, filters, categories.
4. **Detail screens** — event, venue, asset, service.
5. **Booking + Payment** — draft → attendees → intent → confirm → success.
6. **Tickets** — upcoming/past, QR, cancel flow.
7. **Passport, Favorites, Notifications.**
8. **Map** — venue map with bottom sheet.
9. **Polish** — empty/error states, skeletons, a11y, l10n strings.
10. **Messages** — inbox, chat, requests, shared inbox, socket updates. The
    first mobile slice now has an API-backed inbox and text chat, request
    accept/decline, read receipts, and the new Messages tab. Search and basic
    filters are local. Socket presence/live updates, shared-inbox author
    details, attachments, message actions, and new-conversation creation
    remain.
11. **Navigation and Home** (added 2026-10-15) — tab bar to Home · Search ·
    Bookings · Messages · Passport (Map into Search as a List / Map switch;
    Tickets, My requests and the calendar into the Bookings tab; Passport
    icon is the profile photo); Home rebuilt from `GET /categories` with
    occasion tiles, "book just one thing", "happening soon" and the
    returning-user layout; the occasion results page. Design:
    `docs/mobile-design.md` section 6, mockup `docs/mockups/full-app.html`.

Each milestone ends with `flutter analyze` clean and tests passing.

---

## 7. Decisions

1. **Map:** Mapbox (`mapbox_maps_flutter`). Note: no Flutter-web support, so
   the map screen only renders on Android/iOS; web dev shows a fallback list.
2. **Stripe:** deferred. Milestone 5 builds the booking flow up to the payment
   step; the payment sheet is stubbed until revisited.
3. **Template `quiz` / `worldMap`:** retired (removed in milestone 1).
4. **Bundle ID / deep-link scheme:** deferred (needed for social login return
   URLs, so decide before milestone 2 finishes social login).
5. **Social login (Google/Facebook):** required in v1.

## 8. Progress

- [x] **M1 Foundation** — endpoints extended, `quiz`/`worldMap` removed, shell
      nav is Home · Search · Tickets · Passport · Profile, notifications bell,
      placeholder pages, l10n updated. `flutter analyze` clean (1 pre-existing
      info), 36 tests passing.
- [x] **M2 Auth** — email OTP verification (after sign-up and after a 403
      login), forgot/reset password, `roleType`/`systemRole`/`username`/
      `isEmailVerified` on the user, `EmailNotVerifiedFailure`, and
      Google/Facebook sign-in via **both** paths below.

### Social sign-in

| Path | When used | How |
|---|---|---|
| **Native SDK** (option 3) | `GOOGLE_SERVER_CLIENT_ID` set (Google) / `FACEBOOK_NATIVE=true` (Facebook) | App gets an ID token / access token on-device → `POST /auth/google/mobile {idToken}` or `/auth/facebook/mobile {accessToken}` → session in the body |
| **Browser redirect** (option 1) | Otherwise (default) | System browser → `GET /auth/<p>?origin=foxpassport://app` → API redirects to `foxpassport://app/auth/<p>/callback?xc=<code>` → app `POST /auth/<p>/exchange {code}` |

- **API** (`fox-passport-republic-api`, uncommitted): `MOBILE_REDIRECT_ORIGINS`
  (exact-match allow-list), `GOOGLE_MOBILE_CLIENT_IDS`, `/auth/google/mobile`,
  `/auth/facebook/mobile` (verifies the token belongs to this app via
  `debug_token`). Shared find-or-create logic with the redirect flows.
- **Mobile:** `SocialCredentialSource` (platform seam), `SocialAuthButtons` on
  login + register, Android `CallbackActivity` for the `foxpassport` scheme.
- **Flutter web:** buttons are hidden (neither flow runs in a browser tab);
  use a device/emulator to test social sign-in.

#### Setup still needed (credentials I do not have)
1. **Google:** create Android + iOS OAuth clients in Google Cloud (package
   `com.example.flutter_template` / bundle `com.example.flutterTemplate` —
   change these first, see below). Put the **web** client ID in the mobile
   `.env.dev` as `GOOGLE_SERVER_CLIENT_ID`; iOS client ID as `GOOGLE_CLIENT_ID`.
   On iOS also add the reversed client ID as a URL scheme in `Info.plist`.
2. **Facebook:** add the app ID + client token to `AndroidManifest.xml`
   (`com.facebook.sdk.ApplicationId`, `ClientToken`) and `Info.plist`, then set
   `FACEBOOK_NATIVE=true`. Native login uses *enabled* tracking (not iOS
   "limited") so the token is accepted by `debug_token`.
3. **Registered redirect:** the Google/Facebook consoles need the API's own
   `/auth/<provider>/callback` URL (already the case for the web app) — the
   `foxpassport://` scheme itself does **not** go in those consoles.
4. **Identifiers:** the Android `applicationId` and iOS bundle ID are still the
   template's `com.example.*`. Rename before registering OAuth clients.
- [ ] M3 Browse + Search
- [ ] M4 Detail screens
- [ ] M5 Booking (+ payment stub)
- [ ] M6 Tickets
- [ ] M7 Passport, Favorites, Notifications
- [ ] M8 Map (Mapbox)
- [ ] M9 Polish
- [ ] M10 Messages (partial: inbox, text chat, requests, and tab connected; realtime and advanced chat actions remain)
- [ ] M11 Navigation and Home (Bookings tab, Map into Search, data-driven Home, occasion results)
