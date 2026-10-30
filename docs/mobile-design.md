# FoxPassport Mobile — Design Spec

Status: **source of truth for visual design** (decided 2026-10-12).
Supersedes the ink-on-white system in `THEMING.md` and section 1 of
`DESIGN_SYSTEM_AND_INTEGRATION.md`.

The mobile app uses the **same dark / lime look as the web app**
(`fox-passport-republic-app`, `src/app/globals.css`). Screen list, API mapping
and build order stay in `docs/CITIZEN_CORE_PORT_PLAN.md`; this file only says
how things look and behave.

**Same brand, not the same screens** (decided 2026-10-13). The web sells
FoxPassport to a stranger; the signed-in app serves someone who already joined.
Colours, fonts and components are shared with the web. Layouts inside the app
are designed for the phone and are not ports of web pages. See section 6.

Mockups (open in a browser, they are the layout and copy reference):

- `docs/mockups/full-app.html` — **every screen**, in the order a guest meets
  them: welcome and sign-in, Home, planning by occasion, Search and map, venue
  and booking, Bookings, Messages, Passport
- `docs/mockups/onboarding-auth.html` — the welcome carousel (all six slides)
  and Log in / Create account, clickable

`full-app.html` uses `docs/mockups/mockup.css`.

---

## 1. Where the code is today

| Area | Current state | What this spec asks for |
|---|---|---|
| `lib/theme/tokens/*`, `light_theme.dart`, `dark_theme.dart` | Ink-on-white, Inter, light only | Replace with the tokens in section 2; app is dark only |
| `lib/features/onboarding/presentation/theme/onboarding_palette.dart` | Already holds the web's dark / lime values, local to onboarding | Promote these values into `AppColors`; onboarding then reads the shared tokens and this file can go |
| `lib/features/auth/presentation/**` (`AuthPageShell`, forms, social buttons) | White card on light grey, ink badge icon | Restyle per section 5 |
| `lib/shared/widgets/*` (buttons, inputs, cards, bottom nav) | Ink-on-white | Restyle per section 3 |
| Bottom bar | Home · Search · Map · Messages · Passport | Change to **Home · Search · Bookings · Messages · Passport** (decided 2026-10-15, section 6). Do not add the web's centre "Republic" button |

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
| Hero | Archivo 900, uppercase, letter-spacing −0.03em, line-height 0.95 | **Welcome carousel and auth screens only**, at most one per screen. Not used behind sign-in |

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
- **Chip**: pill, 1px `borderStrong`, 11–12px text. Selected: white fill with
  `canvas` text (lime stays reserved for the primary action). Status chips (Indoor / Outdoor) use a tinted border and text.
- **Bottom bar**: floating pill, `surface` with 1px `border`. Active item lime,
  inactive `textMuted`.
- **Bottom sheet**: `surfaceRaised` or `surface`, top radius 28, drag handle.
  Use for filters, date picking, role details and the booking steps.
- **Sticky action bar** (detail screens): card pinned above the safe area with
  price on the left and the primary button on the right.
- **Image placeholder**: `surfaceRaised` with a muted icon.

---

## 4. Welcome reel (new, shown before sign-in)

Design: the "Onboarding UX Pass" artifact, version 10.
`docs/mockups/onboarding-auth.html` (left phone) is the older six-slide
carousel it replaces.

A self-playing, story-style welcome in three scenes: plan, discover, go and
collect. It is **not** the existing `OnboardingPage` (Profile → Interests →
Roles), which runs after sign-in and stays as it is.

Flow: first launch → Welcome reel → Register (or Log in) → verify email →
existing `OnboardingPage` → Home. Show the reel once; store a "welcome seen"
flag next to the existing onboarding-seen flag.

Layout, top to bottom, full screen on `canvas`:

1. **Stage:** the scene, taking the space above the words, with a 70px fade
   into the panel below it. All the motion is here.
2. **Words:** a still panel on `canvas`: lime eyebrow label, a two-line hero
   headline (Archivo 900, 32, upper-case) and the body in `textSecondary`.
3. **Pinned footer, on every scene:** the primary `Create a free account`
   button (goes to Register) and `Already have an account? Log in` (goes to
   Log in). There is no Skip, Next or Back button.
4. **Over the stage:** three story bars (3px, lime while a scene plays, full
   once seen). There is no pause or play button.

Behaviour:

- Each scene plays for 6.5 s, then the next fades in (0.5 s). After the last
  scene the reel starts again from the first, and keeps looping until the user
  signs up or logs in. Going on from the last scene by hand also wraps to the
  first; going back from the first does nothing.
- Tap the left third of the stage to go back and anywhere else to go on. Swipe
  (more than 40px) or use the arrow keys to move.
- Everything on the stage stops while a finger is held down (after 220 ms;
  lifting it carries on from the same spot, and letting go after a hold is not a
  tap) and while the app is in the background or its page is hidden (it carries
  on when the app comes back).
- Each scene zooms from 1.06 to 1 while it plays. The headline lines snap up
  one after the other.
- Reduced motion (`MediaQuery.disableAnimations`): still frames, no
  auto-advance and no looping effects.
- Screen reader on (`MediaQuery.accessibleNavigation`): no auto-advance, so the
  content does not change while it is being read. The
  words are a live region.

| # | Scene | Eyebrow | Headline | Body |
|---|---|---|---|---|
| 1 | Any occasion: a pile of things you would hold for one, each lifting in turn: a birthday sticker ("Kai turns 30"), a wedding invitation (Ana & Leo, 15·11·2026, Lisbon), a conference speaker badge on its lanyard and a VIP wristband | FoxPassport | Plan any / occasion | Weddings, birthdays, corporate nights and nights out: book the venue, the gear and the crew in one app. |
| 2 | Near you: a split-flap departure board, "What's on · Tonight" with the phone's local time, five rows of city, event and status (Live, Few left, Tonight, Sat, Sun). Rows flip one at a time to other cities around the world and back, and a "Every Foxer is verified" pill sits below | Explore | What's on / near you | Tokyo, Paris, New York or your own city: events this week and venues free on your date, wherever you are. |
| 3 | Your passport: a passport visa page (security pattern, microtext, page number, fox watermark) with three worn ink stamps (Tokyo, Paris, New York) and, over it, a thermal ticket for a garden wedding that works offline | Your passport | Tickets and / stamps | Your ticket works offline at the door, and every event adds a stamp. Want to earn? Apply as a Foxer. |

All three scenes are drawn in code (`reel_scenes.dart`), with no video, image
or map assets and no network, and each is scaled up or down to fill the stage
above the fade (no wider than 440px), so it is not left small on a tall phone.
The welcome reel does not use the globe.

One 24 s loop drives all the motion on the stage (the props lifting, the board
flipping, the stamps settling). Each frame is worked out from where the loop
is, so pausing freezes it exactly and the loop ends where it began. The board
turns one row every 2.4 s, its letters flipping a few milliseconds apart. With
reduced motion everything sits on its first frame. Scenery colours that are not
brand colours live in `lib/theme/tokens/reel_palette.dart`; the invitation
names use `AppTypography.script` (Cormorant Garamond italic).

Text on the scenes is labels only: names, cities, events and stamp codes. It
carries no counts of events, people or cities, which would be made-up numbers.
The board rows, the invitation and the ticket ("Garden Wedding", Sun 15 Nov,
16:00, Lisbon) are illustrations, not real listings or bookings.

Claims to check before launch: that tickets work offline at the door, that
venues can be filtered to those free on a date, and that the cities named are
where FoxPassport has listings. Slide 3's line should also say what stamps unlock
once the team decides that (an open decision, §9).

**Exception to §2:** this reel keeps a few soft glows, gradients and textures
(the board's glow, the paper grain, the worn stamp ink) that the rest of the
app does not use. They sit only in the welcome stage, never behind the words.

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

## 6. Signed-in screens

Mockup: `docs/mockups/full-app.html` (sections 2 to 8). It is the layout and
copy reference for every signed-in screen; the numbers in brackets below point
to its sections.

### Rules for everything behind sign-in

These come from problems seen on the web app. Do not carry them over.

- **No hero headlines inside.** The uppercase Archivo headline is for the
  welcome carousel and auth only. Inside, screen titles are Space Grotesk 20.
- **One primary action per screen.** One lime button. Never repeat the same
  action two or three times on a page.
- **Plain words for guests.** Say "owner", "venue", "photographer". Foxer role
  names appear only as a role label on a person (for example "Event Foxer").
  Do not show provider features (partnerships, builders) to a guest.
- **Empty states say one thing once.** "No reviews yet" or "New", never a 0
  rating, 0% bars or an empty quote.
- **One price unit.** Venues are priced "per day" everywhere (see section 9).
- **Signed-out access to a private screen shows a sign-in prompt**, not a
  silent redirect.
- Every screen needs loading, empty and error states, not only the filled one.

### Bottom bar

**Home · Search · Bookings · Messages · Passport** (decided 2026-10-15,
replacing Home · Search · Map · Messages · Passport).

- **Map** stops being a tab. It becomes a List / Map switch inside Search
  (the existing globe can be the map view).
- **Bookings** is a new tab holding tickets, requests and the calendar (see
  below). It shows a lime badge with the number of bookings that need the user
  (for example an approved request waiting for payment).
- **Messages** shows the unread count as a lime badge.
- **Passport** uses the user's profile photo as its icon (first initial on a
  `surfaceRaised` circle when there is no photo): grey ring when inactive, lime
  ring and lime label when selected. The label stays "Passport".
- Notifications stay behind the bell on Home.
- Labels 11px minimum (the current bar uses 10px labels and 9px badge
  numbers); badges at least 16px tall.
- Tapping the tab you are on returns to its first screen (already built).

### Home [2]

The page is built from data, not a fixed set of tiles. `GET /categories`
returns every category with live counts across event templates, venues,
services and assets. Event occasions are the `EventCategory` enum (`wedding`,
`birthday`, `corporate`, `social`, `other`); service categories are the
`ServiceCategory` enum.

Top to bottom, first visit:

1. Location selector (city, chevron) and the bell in a round outlined button
   with the unread count as a lime badge.
2. Only when there is an upcoming booking: the slim lime strip (countdown in
   label style, venue and date, "Ticket" button that opens the ticket).
3. "What are you planning?" in Space Grotesk 20.
4. A 3 × 2 grid: the five occasions, **sorted by count**, each with its count
   ("34 ideas"), plus an **All** tile (dashed border, "{n} more") that opens
   the all-categories screen. Tapping an occasion opens the occasion results
   (below). Tile colours (background / border / icon): Wedding `#1A1428` /
   `#3B2D5C` / `#A78BFA`; Birthday `#24140A` / `#5C3214` / `#F97316`;
   Corporate `#081C24` / `#0E4A5C` / `#00D2FF`; Social `#1A2000` / `#55660A`
   / `#CCFF00`; Other `#0F111A` / `#2A2D3A` / `#A9ADBA`. An occasion the app
   does not know yet gets the Other style and a generic icon.
5. "Or book just one thing": a horizontal row of round icons for single
   bookings (Venues, then the service and gear categories with the most
   listings: Photos, DJ, Catering, Sound and so on). Each opens Search on that
   category.
6. "Happening soon near you": public events with a date badge (month in
   label style, day in Space Grotesk), name, city and how many are going.

Returning user: the strip, then a "Continue: {occasion}" card (saved count,
date, guests, from what they last browsed and saved), then "Plan something
new" with the same grid ordered by their history, then "Because you saved
{venue}" suggestions.

All-categories screen: title "Everything you can book", a search field, then
every category grouped under Occasions, People, Gear and Venues, each row with
icon and count. Categories with no listings show "None yet" here; on Home they
are hidden.

States on Home:

- The five occasion tiles are built into the app, so they render immediately
  and work offline. Counts fill in when `/categories` answers; if it fails,
  the tiles show without counts.
- Upcoming tickets fail or are empty: no strip, no error. Pull-to-refresh
  retries.
- Any other section with no results, or that fails, is **hidden**, heading
  included. No "No Foxers here yet" box and no "Become one" on Home (the Foxer
  pitch is "Earn as a Foxer" in Passport).
- Loading: skeletons in each section's shape, not spinners.

Known API gaps: `/categories` counts are nationwide, not per city (add a city
filter or label the counts as nationwide); "Continue" needs the app to store
the last occasion, date and guests on the device.

### Planning by occasion [3]

Opened by an occasion tile. No question sheet.

- Header "{Occasion}s in {city}" with back and search.
- Chips: **Add date** and **Guests** (dashed lime until set) and the city.
  Tapping Add date or Guests opens one sheet with a month calendar and guest
  ranges (Up to 20, 20–50, 50–100, 100+); its button shows the live result
  count ("Show 9 options"). No budget question.
- One page, three paths in this order:
  1. **Ready-made packages**: horizontal cards from event templates of that
     category (photo, name, icons for what is included, total or "Ask for a
     price").
  2. **Have a Foxer plan it**: one card with a Foxer pink border (`#5C1A46`),
     planner avatars and "Find a planner".
  3. **Plan it yourself**: category rows (Venues, Sound and lights,
     Performers and so on) with counts, each opening Search on that category.
     A category with nothing shows "None here yet".
- With no packages in the city: one line ("No ready-made {occasion} packages
  in {city} yet") and the other two paths move up. No empty tab.
- **Customize** (from a package): each part with keep, swap, upgrade or
  remove; every row shows its price change; the part the package depends on
  (usually the venue) is locked; a summary shows package price, "Your
  changes" and the new total, with "Book this". Only parts available on the
  chosen date are offered.
- There is **no shared basket** across different owners until the API
  supports booking them together. "Plan it yourself" books each item on its
  own.

### Search [4]

- Search bar with filter icon (filters open a bottom sheet); one row of chips
  to switch between Events, Venues, Foxers and Gear; result count in label
  style and a **List / Map** segmented switch on the same row.
- List: large photo cards (photo, favourite button, type chip, name, rating or
  "New", city and capacity, price per day). Infinite scroll.
- Map: full-bleed, price pins (selected pin lime, clusters show a number), a
  locate button, and a sheet with the selected place's card that drags up into
  the full list.
- Only venue cards are drawn; event, Foxer and gear cards still need designing.

### Venue detail [5]

Full-width photo header with round back, share and favourite buttons; label
("Venue · City"); name; chips for capacity, type and rating or "No reviews
yet"; an owner row with a message icon; a short description; rows that open
sheets (Amenities, Rules and cancellation); and the sticky action bar with
price per day and the only "Book now". The booking flow is section 8.

### Bookings [6]

- Title "Bookings" with a calendar icon (opens the existing month calendar).
- Upcoming · Requests · Past switch.
- On top, anything that needs the user, in a card with a lime border: for
  example "Approved · pay to confirm" with a "Pay ₱…" button. These are what
  the tab badge counts.
- Then bookings grouped by month: date block (month in label style, day in
  Space Grotesk), name, type, guests and status, and a QR icon.
- **Ticket** (full screen): a stub with status label, name, date / doors /
  guests, a dashed tear line with side notches, the QR on a white tile, the
  reference in mono and "Works offline". Below: Message and Directions, and a
  quiet "Cancel booking" link.
- The current Tickets page, "My requests" and the calendar move here; Passport
  no longer needs rows for them.

### Passport [8]

Also the profile. An ID card with photo, "Republic of Foxers", name, level and
an XP bar; tapping it opens the profile, the gear icon opens settings. Then
stamps as a grid of circles (earned: tilted solid ring in a role colour with a
city code and month; empty: grey dashed ring), badges with a link to the
leaderboard, then rows for **Saved** and **Earn as a Foxer**.

Not designed yet: event detail and the event booking flow, Foxer profile and
"Match Me", asset and service booking, reviews, notifications list,
cancellation and refund, settings, and the whole Foxer / provider side. Where
Republic (the web's social feed) lives in the app is undecided (section 9).

---

## 7. Messages

Mockup: `docs/mockups/full-app.html`, section 7. Web source: `src/features/messages` in
the web repo (types in `types.ts`, calls in `api/messages.ts`).

**Inbox**

- Title, search icon, new-message icon.
- Filter chips: All · Bookings · Groups · Requests (with a count of incoming
  requests). "Bookings" means conversations that have a context
  (`contextType` / `contextLabel`) or are a shared inbox.
- Row: avatar with a green online dot, name with a verified tick when the
  person is identity-verified, time, last message on one line, unread count as
  a lime badge. Under the name, a small grey label with the booking or venue
  the chat is about (`contextLabel`).
- A venue's or event's shared inbox (`isInbox`) uses a **square** avatar and
  the venue or event name, labelled "Venue inbox" / "Event inbox".
- Groups use a group icon. Pinned chats show a pin and sort first; muted chats
  show a bell-off icon.
- Requests: an incoming request opens with Accept and Decline in place of the
  composer.
- Swipe a row for pin, mute and delete.

**Chat**

- Header: back, avatar, name, role label and presence; overflow menu (search
  in conversation, mute, group members, leave group).
- When the chat has a booking context, a card is pinned under the header:
  "About this booking", name and date, and a "View ticket" link.
- Incoming bubbles: `surface` with a hairline border. Outgoing bubbles:
  `accentTintBg` with `accentTintBorder`. Not solid lime; the send button is
  the only lime element.
- Supported, as on web: quoted reply, emoji reactions, image attachments,
  forwarded and edited marks, one pinned message per conversation, "Seen" read
  receipt, centred system notices for group changes. In a shared inbox, show
  the real author's name on each team reply.
- Long-press a message: reply, react, edit (own), forward, pin, delete (own).
- Composer: image button, text field ("Type a message…"), lime send button.

---

## 8. Venue booking flow

Mockup: `docs/mockups/full-app.html`, section 5. Web source: `VenueBookingClient`,
`VenueCheckoutClient`, `VenueBookingSuccessClient`,
`VenueRequestPendingClient`. Same rules as the web, split into steps.

Starts from "Book now" on venue detail. Full-screen flow with a three-segment
progress bar and "1 of 3" in label style. The current selection and the Next
button are pinned at the bottom of each step.

1. **Dates** — "When is it?" Month calendar; unavailable dates
   (`/venues/:id/unavailable-dates`) are struck out and disabled; the selection
   is a lime circle.
2. **Guests** — "How many guests?" Stepper with the venue's capacity under the
   number. Going over capacity is allowed and shows an amber note: the owner
   has to approve before payment. Below: an optional free-text field for the
   owner (the web's "Special requests").
3. **Review** — venue, date and guests (each editable), then the price lines:
   rate × days, service fee (from the API, never computed in the app), voucher
   (opens a code sheet), total. Cancellation policy in one line. Button:
   "Continue to payment", or "Request to book" when over capacity.
4. **Pay** — total, then Stripe's payment sheet: Apple Pay / Google Pay first,
   card as fallback. Stubbed until Stripe is taken up (port plan, decision 2).
5. Ending, one of:
   - **Confirmed** ("You're booked") — after payment. Summary card with
     reference and total charged, "View ticket" (primary), "Message the owner".
   - **Request sent** — when guests exceed capacity. No payment is taken. Three
     steps (request delivered, you'll be notified, pay only after approval),
     reference and "amount if approved", "Message the owner" (primary), "Back
     to home". Amber, not lime, is the status colour here.

Not drawn yet: multi-day selection, the voucher sheet, a declined request, a
failed payment.

---

## 9. Open decisions

- **Price unit.** The web shows the same venue as "/night" and "/ day". The
  mockups use "per day". Confirm, then use it everywhere.
- **Republic.** The web's social feed has no place in the app yet.
- **Foxer side.** Listings, calendar, earnings and door check-in are not
  designed; the first release is assumed to be guests only.
- **Sign in with Apple.** In the auth mockup, not built (section 5).
- **Stamps and levels.** What a stamp or a level gives the user should be
  stated on the Passport screen once the rules are settled.

---

## 10. Copy

Sentence case for buttons and body. Uppercase only for the mono labels and the
hero headline. Verb-first buttons ("Book now", "Create account"). No
exclamation marks. Currency: `₱25,000` with a muted `/day`.

All user-facing strings go through `lib/l10n` like the rest of the app.
