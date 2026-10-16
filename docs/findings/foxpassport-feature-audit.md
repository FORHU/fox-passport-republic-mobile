# FoxPassport Republic — Full Feature Audit vs. BUSINESS-STRATEGY-MASTER.md

Checked 15 Oct 2026 against [BUSINESS-STRATEGY-MASTER.md](./BUSINESS-STRATEGY-MASTER.md) (v3.0, all 44 sections), the API Prisma schema (90 models) and 54 `src/modules`, the 86 web pages (`page.tsx`) in `src/app`, and the mobile app.

**Updated 16 Oct 2026:** the mobile app grew from 13 to 29 pages after the stacked citizen-app PRs were merged (mobile #9–#32). Mobile rows below and §2a reflect the 16 Oct state; API and web rows are unchanged from 15 Oct.

**Legend:** ✅ Built · 🟡 Partial · ❌ Not built · 📄 = mentioned in the strategy doc · 🚫 = built but **not mentioned** in the strategy doc

---

## 1. Common misconceptions

| Claim | Actual state |
|---|---|
| Citizens "register for full curated events with instant ticketing" | ❌ Public self-service registration (`EventRegistration`) **does not exist** in code. Only the private EventFoxer-curated flow is live (strategy §1a item 2 confirms). |
| Mobile app does "QR ticket verification" | ❌ Mobile has no scanner. QR check-in is **web only** (`/scanner`, `/creator-dashboard/check-in`). |
| Mobile is a full client | 🟡 Citizen side, mostly yes as of 16 Oct (booking checkout, messages, feed, reviews; see §2a). Creator side, no: dashboards deep-link to the web, Foxer applications are finished on the web, and there is no QR scanner. |
| "Escrow" | ✅ Exists but is labeled **Payment Protection** in UI (`PaymentProtectionTimeline`) with confirmation-deadline sweeps. |

---

## 2. Feature inventory mapped to the strategy

### A. Discovery (📄 §9 Journey A, §18, §21 Phase 1)
| Feature | Status | Evidence |
|---|---|---|
| Search (events, venues, foxers) | ✅ | API `search`, web `/search`, mobile `search` |
| Map discovery (Mapbox, polygons, radius, nearby-first) | ✅ | web `/venues/map`, `MapBoxView`, `polygonGeo`, `useNearbyFirst` |
| Categories / taxonomy | ✅ | API `category`, web `/categories` |
| Event detail pages | ✅ | web `/event/[eventId]` |
| Wishlists / favorites | ✅ | `Favorite`, web `/wishlists` |
| SEO structured data | 🚫✅ | `EventJsonLd`, `PlaceJsonLd`, `FoxerJsonLd` |
| Recommendations ("relevant recommendations" §18) | 🟡 | follow-suggestions, plus `GET /event-templates/recommendations`, which returns the newest published public templates (`orderBy createdAt desc`); no personalised recommender |

### B. Participation / Registration (📄 §9, §21 Phase 1)
| Feature | Status | Evidence |
|---|---|---|
| Public self-service event registration | ❌ | no `EventRegistration` model (§1a item 2) |
| Private curated event booking (`EventTemplate → Event → Booking`) | ✅ | `Booking`, `BookingAttendee` |
| Attendee invites | ✅ | `InviteStatus` |
| Waitlist | 🚫✅ | `Waitlist`, web `/booking/waitlist` |
| Booking edit requests | 🚫✅ | `BookingEditRequest` |
| Tickets (mobile) | ✅ | mobile `tickets` |
| QR check-in + Check-in Helpers | ✅ | web `/scanner`, `/creator-dashboard/check-in` |

### C. Organize (📄 §11.2, §21 Phase 2)
| Feature | Status | Evidence |
|---|---|---|
| Event Templates (Venue + Gear + Talent bundles) | ✅ | `EventTemplate*` models, `/foxer/create-event` |
| Admin approval of event requests | ✅ | API `event-request` |
| Host Markup | ✅ | per-template markup |
| Organizer Appointments (invite/request) | 🚫✅ | `Appointment`, `/creator-dashboard/team` |
| Organizer XP | 🚫✅ | `OrganizerEventXp` |
| Shared Inbox (event/venue owns conversations) | 🚫✅ | `messaging.prisma`, `/messages` |
| Supplier management per event | 🚫✅ | `/creator-dashboard/suppliers/[eventId]` |
| Calendar + availability + schedule conflicts | ✅ | `calendar`, `availability`, `ScheduleConflictWarning` |
| Venue ↔ EventFoxer affiliations | 🚫✅ | `VenueEventFoxerAffiliation`, `/foxer/affiliations` |

### D. Provider Marketplace (📄 §11.3–11.5, §17, §21 Phase 4)
| Feature | Status | Evidence |
|---|---|---|
| Venue listings + packages (Mayor) | ✅ | `Venue`, `VenuePackage`, `/mayor`, `/venue-foxer` |
| Gear (Assets) + standalone asset booking | ✅ | `Asset`, `AssetBooking`, `/booking/asset/[id]` |
| Talent/Services + standalone service booking | ✅ | `Service`, `ServiceBooking` |
| Performer Foxer (DJ, band, photo, video, MC) | ✅ | `PerformerFoxerApplication`, `/creator-dashboard/performers` |
| Bidding (suppliers bid on events) | 🚫✅ | `EventServiceBid`, `EventAssetBid`, `/foxer/marketplace-requests` |
| Match requests (client ↔ foxer direct) | 🚫✅ | API `match`, web `/match/[foxerId]` |
| Role applications + admin review | ✅ | 7 application models, `/foxer/apply` |
| Specializations (Claimed / Earned) | 🚫✅ | `FoxerSpecialization` |

### E. Transactions & Money (📄 §15, §21 Phase 3, §24)
| Feature | Status | Evidence |
|---|---|---|
| Stripe checkout + Stripe Connect onboarding/payouts | ✅ | `checkout`, `stripe-connect`, `payout` |
| Platform fee (configurable, admin) | ✅ | `PlatformFeeConfig` with `PLATFORM_FEE_PERCENT` fallback across all booking & template flows; Level-3 "lower_fees" 0% perk |
| Invoices | ✅ | `Invoice`, `InvoiceItem` |
| Payment protection / confirmation deadlines | ✅ | `transaction-status`, deadline sweep |
| Refunds (incl. itemized admin refunds) | ✅ | `Refund`, `/admin/refunds` |
| Cancellation policies + rules | ✅ | `CancellationPolicy`, `CancellationRule` |
| Promotions + vouchers | 🚫✅ | `Promotion`, `Voucher`, `/creator-dashboard/promotions` |
| Multi-currency display (FX rates) | 🚫✅ | API `fx`, `CurrencySwitcher` |
| Idempotent payments / webhook ledger | 🚫✅ | `RequestIdempotencyKey`, `PaymentProviderEvent` |
| Earnings dashboard | ✅ | `/creator-dashboard/earnings` |

### F. Community (📄 §19, §21 Phase 5)
| Feature | Status | Evidence |
|---|---|---|
| Republic feed (posts, polls, comments, likes, media tags) | ✅ | `feed.prisma`, `/republic` |
| Saved / hidden posts | ✅ | `SavedPost`, `HiddenPost` |
| Follow / block / connections | ✅ | `Follow`, `Block`, `/user/[id]/connections` |
| Content reporting / moderation | ✅ | `Report`, API `reports` |
| Notifications (realtime via Socket.IO) | ✅ | `Notification`, socket emit |

### G. Gamification — Passport (🚫 not in strategy doc at all)
| Feature | Status | Evidence |
|---|---|---|
| Digital Passport + Paths | 🚫✅ | `Passport`, `PassportPath` models; `UserPath` enum |
| Stamps, Badges (with rarity), leaderboard | 🚫✅ | `PassportStamp`, `Badge`, `/passport/leaderboard` |
| Progress page | 🚫✅ | web `/progress`, mobile `passport` |

### H. Trust (📄 §26)
| Feature | Status | Evidence |
|---|---|---|
| Identity verification / KYC (document upload + admin review) | ✅ | `IdentityVerification`, `/kyc` |
| Reviews + replies (require completed/attended booking) | ✅ | `Review`, `ReviewReply`; premature reviews on confirmed future bookings rejected |
| Better Auth, email OTP, Google + Facebook OAuth | ✅ | `auth`, `/auth/google/callback` |
| Rate limiting (Redis-backed) | ✅ | `rate-limit-store` |
| Audit logs | 🚫✅ | `AuditLog` |
| Dispute handling | ✅ | Asset/service booking dispute flow (`disputed` status blocks payouts; admin resolution unblocks/triggers payouts on `completed`); refund dispute queue |
| Privacy / Terms / Data deletion | ✅ | `/privacy`, `/terms`, `/data-deletion` |

### I. Investors / Partners (📄 §11.6)
| Feature | Status | Evidence |
|---|---|---|
| Investor applications, investments, partnership proposals | ✅ | `PartnerInvestment`, `PartnershipProposal`, `/republic/investments` |
| Legal review of revenue-share | ⚠️ | still open (§1a item 5) |

### J. External Connectivity (📄 §20)
| Feature | Status | Evidence |
|---|---|---|
| Facebook login | ✅ | OAuth |
| Share links | 🟡 | minimal share usage only |
| Referral tracking | ❌ | none |
| Campaign / UTM tracking | ❌ | none meaningful |
| TikTok / Instagram / YouTube distribution | ❌ | none |

### K. Business Tools (📄 §15 Stage 3, §21 Phase 7)
| Feature | Status | Evidence |
|---|---|---|
| Analytics | 🟡 | one public endpoint `/analytics/event-stats` |
| Admin console | ✅ | web `/admin` |
| Product tours | 🚫✅ | web component `ProductTour` (no API model) |

### L. Custom Experiences — "Make It Happen" (📄 §8, §23, Journey B)
| Feature | Status |
|---|---|
| Intent → requirements → provider matching | ❌ Not built, no engineering plan (§1a item 3) |

---

## 2a. Mobile app (as of 16 Oct 2026)

29 pages across 23 features in `fox-passport-republic-mobile/lib/features`, checked on `main` after the 16 Oct merges.

**Bottom navigation:** Home · Search · Bookings · Messages · Passport. Tickets moved out of the tab bar and into Bookings (mobile #16).

| Area | Status | Evidence |
|---|---|---|
| Auth (email, Google; Facebook and Apple buttons) | 🟡 | `auth` (5 pages). Apple is shown as "coming soon" because the API has no Apple support |
| Onboarding + location gate | ✅ | `onboarding`, `location` |
| Home around occasions, all-categories, occasion results | ✅ | `home`, `occasion` |
| Search with filters, sorting, city, List/Map switch, globe | ✅ | `search`, `map` |
| Event, scheduled-event and venue detail | ✅ | `event`, `venue` |
| Booking checkout (templates, gear, services) with Stripe | ✅ | `booking_flow_page`, `item_booking_page`, `shared/payments` |
| Bookings tab: calendar, "Needs you" block, tickets | ✅ | `tickets`, `calendar` |
| Messages + chat, realtime | ✅ | `messages`, `shared/realtime` (Socket.IO) |
| Republic feed: posting, likes, comments | ✅ | `republic` (no bottom tab) |
| Reviews: read venue reviews, review a past booking | ✅ | `reviews` |
| Foxer profile, Match me, My requests | ✅ | `foxer` |
| Passport: tabs, stamps, badges | ✅ | `passport` |
| Become a Foxer: roles and application status | 🟡 | `roles`; the application form opens on the web (it needs identity documents) |
| Notifications, settings, favorites | ✅ | `notifications`, `settings`, `favorites` |
| Creator dashboards | ❌ | deep-link to web `/creator-dashboard` |
| QR check-in scanner | ❌ | no scanner package; web only |
| Waitlist | ❌ | web only |

---

## 3. Gaps

### Built but missing from the strategy doc (🚫)
All of these were added to the strategy doc on 15 Oct (§1b A and §11.7). The list is kept as the record of what that reconciliation covered.

1. **Passport gamification:** stamps, badges, leaderboard, paths
2. **Bidding marketplace:** suppliers bid on events
3. **Match requests:** client ↔ foxer direct
4. **Organizer Appointments, Check-in Helpers, Shared Inbox** (in `CONTEXT.md`, not in strategy)
5. **Venue ↔ EventFoxer affiliations**
6. **Promotions and vouchers**
7. **Multi-currency (FX)**
8. **Waitlist and booking edit requests**
9. **Specializations (Claimed/Earned badges)**
10. **Audit logs, idempotent payments**

### In the strategy doc but not built
1. **Public self-service event registration** (core of Journey A / Year 1)
2. **Custom Experiences / "Make It Happen"**
3. **Referral and campaign tracking** (§20)
4. **Social platform distribution** (§20)
5. **Recommendations** (§18)
6. **Real analytics / premium business tools** (Stage 3)
7. **Dispute handling for public event attendees** (direct Asset/Service booking disputes and refund disputes are built; attendee disputes for public events await public registration)
8. **Mobile creator tools**: QR scanner and creator dashboards (see §2a)
