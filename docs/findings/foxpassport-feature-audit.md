# FoxPassport Republic — Full Feature Audit vs. BUSINESS-STRATEGY-MASTER.md

Checked 15 Oct 2026 against [BUSINESS-STRATEGY-MASTER.md](./BUSINESS-STRATEGY-MASTER.md) (v3.0, all 44 sections), the API Prisma schema + 49 `src/modules`, the 87 web routes in `src/app`, and the 13 mobile pages.

**Legend:** ✅ Built · 🟡 Partial · ❌ Not built · 📄 = mentioned in the strategy doc · 🚫 = built but **not mentioned** in the strategy doc

---

## 1. Corrections to my earlier summary

| My earlier claim | Actual state |
|---|---|
| Citizens "register for full curated events with instant ticketing" | ❌ Public self-service registration (`EventRegistration`) **does not exist** in code. Only the private EventFoxer-curated flow is live (strategy §1a item 2 confirms). |
| Mobile app does "QR ticket verification" | ❌ Mobile has no scanner. QR check-in is **web only** (`/scanner`, `/creator-dashboard/check-in`). |
| Mobile is a full client | 🟡 Mobile has 13 pages: auth (5), welcome, onboarding, home, search, tickets, passport, profile, notifications. No booking checkout, dashboards, or messaging. |
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
| Recommendations ("relevant recommendations" §18) | 🟡 | only follow-suggestions; no event recommender |

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
| Platform fee (configurable, admin) | ✅ | `PlatformFeeConfig` |
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
| Digital Passport + Paths | 🚫✅ | `Passport`, `PassportPath`, `UserPath` |
| Stamps, Badges (with rarity), leaderboard | 🚫✅ | `PassportStamp`, `Badge`, `/passport/leaderboard` |
| Progress page | 🚫✅ | web `/progress`, mobile `passport` |

### H. Trust (📄 §26)
| Feature | Status | Evidence |
|---|---|---|
| Identity verification / KYC (document upload + admin review) | ✅ | `IdentityVerification`, `/kyc` |
| Reviews + replies (require completed booking) | ✅ | `Review`, `ReviewReply` |
| Better Auth, email OTP, Google + Facebook OAuth | ✅ | `auth`, `/auth/google/callback` |
| Rate limiting (Redis-backed) | ✅ | `rate-limit-store` |
| Audit logs | 🚫✅ | `AuditLog` |
| Dispute handling | 🟡 | refunds + reports exist; no dedicated dispute workflow |
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
| Product tours | 🚫✅ | `ProductTour` |

### L. Custom Experiences — "Make It Happen" (📄 §8, §23, Journey B)
| Feature | Status |
|---|---|
| Intent → requirements → provider matching | ❌ Not built, no engineering plan (§1a item 3) |

---

## 3. Gaps

### Built but missing from the strategy doc (🚫)
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
7. **Formal dispute handling** (§26)
