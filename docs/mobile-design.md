# FoxPassport Mobile — Design Spec

Status: **source of truth for visual design** (decided 2026-10-12).
Supersedes the ink-on-white system in `THEMING.md` and section 1 of
`DESIGN_SYSTEM_AND_INTEGRATION.md`.

The mobile app uses the **same dark / lime look as the web app**
(`fox-passport-republic-app`, `src/app/globals.css`). Screen list, API mapping
and build order stay in `docs/CITIZEN_CORE_PORT_PLAN.md`; this file only says
how things look and behave.

Mockups (open in a browser, they are the layout and copy reference):

- `docs/mockups/app-screens.html` — Home, Venue detail, Passport
- `docs/mockups/onboarding-auth.html` — Welcome carousel, Log in / Create account

---

## 1. Where the code is today

| Area | Current state | What this spec asks for |
|---|---|---|
| `lib/theme/tokens/*`, `light_theme.dart`, `dark_theme.dart` | Ink-on-white, Inter, light only | Replace with the tokens in section 2; app is dark only |
| `lib/features/onboarding/presentation/theme/onboarding_palette.dart` | Already holds the web's dark / lime values, local to onboarding | Promote these values into `AppColors`; onboarding then reads the shared tokens and this file can go |
| `lib/features/auth/presentation/**` (`AuthPageShell`, forms, social buttons) | White card on light grey, ink badge icon | Restyle per section 5 |
| `lib/shared/widgets/*` (buttons, inputs, cards, bottom nav) | Ink-on-white | Restyle per section 3 |
| Bottom bar | Home · Search · Tickets · Passport · Profile | **Keep these five tabs.** Do not add the web's centre "Republic" button |

Do the token change first, then shared widgets, then screens. Do not leave a
screen half light and half dark.

---

## 2. Tokens

### Colour

| Token | Value | Use |
|---|---|---|
| `canvas` | `#02040A` | App background |
| `surface` | `#0F111A` | Cards, inputs, bottom bar |
| `surfaceRaised` | `#1A1A24` | Nested surfaces, image placeholders, sheets |
| `border` | white at 10% (≈ `#20232E` on canvas) | Hairline on cards and inputs |
| `borderStrong` | `#2A2D3A` | Outlined buttons, chips |
| `accent` | `#CCFF00` | Primary button, active tab, key labels |
| `accentPressed` | `#B8E600` | Pressed state of accent |
| `onAccent` | `#1A2000` | Text and icons on lime (never white) |
| `accentTintBg` / `accentTintBorder` | `#1A2000` / `#55660A` | Lime-tinted tiles, highlighted card border |
| `textPrimary` | `#FFFFFF` | Headings, body |
| `textSecondary` | `#A9ADBA` | Supporting copy |
| `textMuted` | `#8B90A0` | Placeholders, captions, inactive icons |
| `textFaint` | `#5A5F70` | Dividers' "or", disabled |
| `error` / `success` / `warning` | `#F87171` / `#4ADE80` / `#FBBF24` | Status |

Foxer role colours (chips and role labels only, never buttons):
Event `#CCFF00` · Venue `#A78BFA` · Gear `#F97316` · Talent `#00D2FF` ·
Performer `#F59E0B`. Role label on Foxer cards: `#FF00AA`.

Rules:

- Lime is for **one primary action per screen**, the active tab, and small
  uppercase labels. Everything else is white or grey on dark.
- No gradients, glows or blurred blobs. Flat fills and hairline borders.
- No hard-coded colours in widgets. Everything goes through `AppColors`.

### Type (via `google_fonts`)

| Role | Font | Notes |
|---|---|---|
| Display / titles / buttons | Space Grotesk 700 | Screen titles, card titles, button labels |
| Body | Plus Jakarta Sans 500 | Already used by `OnboardingPalette.body` |
| Label | Space Mono 400, 11px, uppercase, letter-spacing 0.12em | Eyebrows ("WELCOME BACK"), counters ("1 / 6"), meta |
| Hero | Archivo 900, uppercase, letter-spacing −0.03em, line-height 0.95 | **At most one per screen**: onboarding and auth headlines, Home headline |

Scale: hero 30–34 · title 20–24 · card title 16 · body 14 · caption 12 ·
label 11. Nothing below 11.

### Shape and spacing

- Spacing keeps the existing 4 / 8 / 16 / 24 / 32 / 48 scale (`AppSpacing`).
- Radius: inputs and primary buttons 16 · cards 16–20 · sheets 28 (top
  corners) · chips, search bar and bottom bar fully rounded (999).
- Screen side padding 16–20. Minimum touch target 48.

---

## 3. Components

- **Primary button**: lime fill, `onAccent` text, Space Grotesk 700 14–15,
  height 52, radius 16, full width. No shadow.
- **Secondary button**: transparent, 1px `borderStrong`, white text, same size.
  Used for social sign-in and secondary actions.
- **Text link**: lime, bold, no underline ("Forgot password?", "Create an
  account"). Muted variant in `textMuted` for "Skip" / "Back".
- **Input**: `surface` fill, 1px `border`, radius 16, height 52, placeholder in
  `textMuted`, focused border lime 1.5px, error border `error`.
- **Card**: `surface`, 1px `border`, radius 16–20, padding 12–16, no elevation.
- **Chip**: pill, 1px `borderStrong`, 11–12px text. Selected: lime fill with
  `onAccent` text. Status chips (Indoor / Outdoor) use a tinted border and text.
- **Bottom bar**: floating pill, `surface` with 1px `border`. Active item lime,
  inactive `textMuted`.
- **Bottom sheet**: `surfaceRaised` or `surface`, top radius 28, drag handle.
  Use for filters, date picking, role details and the booking steps.
- **Sticky action bar** (detail screens): card pinned above the safe area with
  price on the left and the primary button on the right.
- **Image placeholder**: `surfaceRaised` with a muted icon.

---

## 4. Welcome carousel (new, shown before sign-in)

Mockup: `docs/mockups/onboarding-auth.html` (left phone).

This is the phone version of the web's `WelcomeGuide.tsx`. It is **not** the
existing `OnboardingPage` (Profile → Interests → Roles), which runs after
sign-in and stays as it is.

Flow: first launch → Welcome carousel → Register (or Log in) → verify email →
existing `OnboardingPage` → Home. Show the carousel once; store a "welcome
seen" flag next to the existing onboarding-seen flag.

Layout, top to bottom, full screen on `canvas`:

1. Row: counter `1 / 6` (label style, muted) on the left, `Skip` on the right
   (hidden on the last slide; jumps to the last slide).
2. Vertically centred block: 72px icon tile (radius 20, `accentTintBg` fill,
   `accentTintBorder` border, lime icon) → lime eyebrow label → hero headline →
   body in `textSecondary`.
3. Page dots: 6px grey dots, the active one is an 18px lime bar.
4. Primary button, then a muted `Back` link (hidden on slide 1).

Swipe left / right also changes slide.

Slides (copy is the web's, keep it verbatim):

| # | Eyebrow | Headline | Body | Button |
|---|---|---|---|---|
| 1 | FoxPassport | Welcome to FoxPassport | Plan, book and live unforgettable events — and meet the people who make them happen. | Show me around |
| 2 | Explore | Discover experiences | Browse trending events, venues, gear and talent near you. Filter by vibe — birthdays, weddings, corporate nights and more. | Next |
| 3 | Foxers | Book Foxers in one place | Foxers are the verified pros behind every event. See their real availability, book them directly and pay securely. | Next |
| 4 | Passport | Stamp your passport | Every event you attend earns stamps, badges and levels on your digital FoxPassport. | Next |
| 5 | Republic | Join the Republic | Follow friends, post to the feed, chat with hosts and match with Foxers who fit your plans. | Next |
| 6 | Get started | Ready when you are | Create a free account to book and earn stamps. Want to earn instead? Apply as a Foxer once you're signed up. | Create a free account |

Slide 1 uses the fox logo in the tile (the paw in the mockup is a placeholder).
Slide 3 shows the five role chips in their role colours under the body.
Slide 6's button goes to Register; add a muted "I already have an account" link
to Log in.

---

## 5. Auth screens

Mockup: `docs/mockups/onboarding-auth.html` (right phone). Reference: the web
`/auth` page.

Applies to Log in, Register, Verify email, Forgot password and Reset password.
Replace the white card and ink badge in `AuthPageShell` with:

- `canvas` background, no card. Content sits in the upper-middle of the screen:
  spare height is split 1 : 2 above and below the form. (It was bottom-weighted,
  which left a large empty gap under the wordmark.) Scrollable when the
  keyboard is open.
- Small centred wordmark "FoxPassport" at the top (with a back arrow when the
  screen is not the first in the stack).
- Lime eyebrow label, then the hero headline, then the form.

| Screen | Eyebrow | Headline | Primary button |
|---|---|---|---|
| Log in | Welcome back | Log in to your account | Log in |
| Register | Free to join | Create your account | Create account |

Log in: Email address, Password (with show / hide eye), right-aligned lime
"Forgot password?", primary button, "OR" divider, social buttons, then
"New here? **Create an account**".

Register: Full name, Email address, Password, primary button, "OR", social
buttons, then "Already have an account? **Log in**".

**Social buttons are shown but disabled for now** (`kSocialSignInEnabled` in
`social_auth_buttons.dart`): social sign-in is not being launched yet.

Social buttons are secondary buttons with the provider icon: Google and
Facebook (already wired in `SocialAuthButtons`). **Sign in with Apple** is in
the mockup because the App Store generally requires it alongside other social
logins on iOS; it is not built yet and needs API support, so treat it as an
open task, not something to fake.

Verify email, Forgot and Reset follow the same shell: eyebrow, hero headline,
one short line of body copy, fields, one primary button.

Keep all existing auth logic, validation and controllers. This is a restyle.

---

## 6. Main screens

Mockup: `docs/mockups/app-screens.html`.

- **Home**: no marketing hero. Location selector and bell on top, one hero
  headline, a pill search bar ("What, where, when") with a filter icon,
  category chips, then horizontally scrolling sections of event and venue
  cards.
- **Search**: results as single-column cards; filters in a bottom sheet;
  infinite scroll, not numbered pages. Map (milestone 8) is full-bleed with a
  draggable list sheet over it.
- **Detail (event / venue / asset / service)**: full-width photo header with
  round back and favourite buttons, label + hero-style name, meta chips
  (capacity, type, rating), tappable rows that open sheets ("Pick a date",
  "Add gear and crew"), and the sticky action bar with price and "Book now".
- **Tickets**: ticket cards; the QR sits on a white tile so scanners can read
  it on a dark screen.
- **Passport**: next-event ticket card with a lime-tinted border and QR on top,
  then stamps as a grid of circles (earned: lime dashed ring with a check;
  empty: grey dashed ring), level and XP in label style.

---

## 7. Copy

Sentence case for buttons and body. Uppercase only for the mono labels and the
hero headline. Verb-first buttons ("Book now", "Create account"). No
exclamation marks. Currency as on web: `₱25,000` with a muted `/night`.

All user-facing strings go through `lib/l10n` like the rest of the app.
