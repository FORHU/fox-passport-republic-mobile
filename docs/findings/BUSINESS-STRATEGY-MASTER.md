# FoxPassport Republic — Business Plan & Strategy Master Document

**Version:** 3.1
**Status:** Active
**Date:** 14 September 2026 (reconciliation update 15 October 2026)
**Strategic Owner:** Product / Project Management
**Business Approval:** Founding Team
**Reconciled against current implementation:** 14 September 2026 (see §1a); 15 October 2026 (see §1b and [`foxpassport-feature-audit.md`](./foxpassport-feature-audit.md))

---

# 1. Purpose

This document defines the business direction I recommend for FoxPassport Republic based on our current product discussions, marketplace model, community strategy, existing platform capabilities, and long-term business objectives.

The purpose of this document is to establish a clear strategic direction for the business before we continue expanding the product.

It defines:

* what business we are building;
* who we are building it for;
* what problem we are solving;
* how experiences and events fit into the business;
* how the FoxPassport ecosystem creates value;
* how we can generate revenue;
* how we should approach marketplace growth;
* how communities and external platforms can support growth;
* which areas should be prioritized;
* which areas should be deferred;
* how we should evaluate major business decisions; and
* how business strategy should guide product and project decisions.

This document is intentionally business-focused.

It does not define detailed UI requirements, API contracts, database architecture, implementation tasks, sprint plans, or development procedures.

Those responsibilities belong to the Product Management, Project Management, and Technical Architecture documents.

---

# 1a. Reconciliation Against Current Implementation

Checked 14 Sep 2026 against `fox-passport-republic-api/prisma/schema/*.prisma`, `CONTEXT.md` (both repos), `DYNAMIC-EVENTS-PRODUCT-MASTER.md`, `docs/adr/0001-dynamic-events-architecture.md`, and `roles-and-spaces.md`. This section records where this document was adjusted to match what's actually built, or flagged where downstream repo docs now need to change to match *this* document — same pattern as ADR 0001's "Decided 13 Sep" addendum. v2.1 reconciled the prior draft; this supersedes it against the v3.0 rewrite.

Confirmed aligned, no changes needed: the strategic-hierarchy framing (§3), the "Community Experience Marketplace" positioning (§2/§13), and the capability-driven Dynamic Experiences approach (§22/§24), which matches the settled ADR 0001 decision to keep `EventTemplate` as the taxonomy/capability owner and reuse existing booking/escrow/payment infrastructure rather than duplicate it.

Seven items:

1. **§11.5 (Talent Foxer naming) — adopted, downstream collision resolved.** This version's rename of ServiceFoxer's public name to "Talent Foxer" is **decided, not reverted** — confirmed with the founding team 14 Sep. This matches the live UI label (`roles.ts`: `serviceFoxer: { label: "Talent Foxer" }`) so no app change was needed there. It did collide with a separate, already-planned role: `roles-and-spaces.md` §1 had planned a *distinct* new sixth `RoleType`, also keyed `talentFoxer`, splitting "entertainment" out of `ServiceCategory` into its own resource type for performers/entertainers specifically — the same doc explicitly warns that "Talent Foxer" naming both an umbrella and a leaf is how permission drift starts. **Resolved 14 Sep**: that planned role is re-keyed to `performerFoxer` (permission `performer:manage`, application model `PerformerFoxerApplication`) throughout `roles-and-spaces.md` §1, §2, and §7 — its underlying `resourceType: "talent"` data category is unaffected, matching the existing precedent that a role's key needn't match its resourceType (`gearFoxer` already supplies `resourceType: "asset"`).
2. **§9 / §12 (Two Core Customer Journeys / Ecosystem) — Journey A still gated on unshipped work.** Journey A's discover → register → pay → participate path assumes public self-service registration. Today, the only live participation path is the private, EventFoxer-curated flow (`EventTemplate → Client → Event → Booking`) — there is no public self-service registration yet. That capability is `EventRegistration`, tracked as Phase 1 of the Dynamic Events roadmap in `DYNAMIC-EVENTS-PRODUCT-MASTER.md` §20.
3. **§8 / §9 / §23 (Journey B, "Make It Happen," Custom Experience Strategy) — fully aspirational, no engineering plan exists yet.** This is new in v3.0 and it's a bigger gap than item 2: there is no intent-to-requirements matching concept anywhere in the current schema or roadmap (nothing like translating "romantic beach date" into a provider bundle). Unlike Dynamic Events, which has ADRs and phased tracking, this has none yet. Not a blocker for keeping it in the strategy — Stage 5 / Year 3 already place it appropriately far out — but it shouldn't be read as more built-out than it is.
4. **§15 (Revenue Strategy) — Stage 1/2 wording doesn't match live fee behavior.** The platform fee (`EventTemplate.platformFeePct`, default 5%) and Host Markup are already computed on every live transaction; there is no current fee-free mode to be "in" during Stage 1. Read Stage 1 as proving liquidity at current default rates, and Stage 2 as adjusting/segmenting take rate rather than introducing fees from zero.
5. **§11.6 (Investors) — still needs a legal read.** `PartnerInvestment`/`PartnershipProposal` already model revenue-share percentages, monetary valuation, and inventory investment tied to specific events/venues — further built out than this section's "expand only when legal/regulatory requirements justify it" framing implies is already true. Unresolved as of this writing; needs the founding team's legal/compliance owner, not a doc edit.
6. **§21 (Product Expansion Strategy) — its Phase 1–7 numbering collides with `DYNAMIC-EVENTS-PRODUCT-MASTER.md`'s own Phase 0–7.** This document's phases (Discover/Participate → Organize → Transactions → Provider Marketplace → Community → Custom Experiences → Business Tools) are business-level and unrelated to that document's Dynamic-Events-specific phases (Architecture Decision → Public Event MVP → Taxonomy → Event Configuration → Public Participation → Ticketing → Sessions/Speakers → Advanced). Same label, two different meanings, in companion documents that cross-reference each other — read "Phase" here as this document's own scheme, not `DYNAMIC-EVENTS-PRODUCT-MASTER.md`'s.
7. **§7 (Any Event, Any Experience) doesn't close an already-open taxonomy gap.** `DYNAMIC-EVENTS-PRODUCT-MASTER.md` §11 already flags that its example taxonomy never shows where the current five `EventCategory` enum values (`corporate`, `birthday`, `wedding`, `social`, `other`) land as subcategories — still unresolved. §7's richer example list (Sports, Outdoor, Romantic, Custom Experiences, etc.) doesn't resolve it either; both documents' taxonomy examples need the same explicit mapping before any migration runs, tracked as one open item, not two.

---

# 1b. Feature Reconciliation (15 October 2026)

Checked 15 Oct 2026 against the full feature inventory in [`foxpassport-feature-audit.md`](./foxpassport-feature-audit.md) (API Prisma schema and modules, web app routes, mobile app pages). The strategic direction in this document is unchanged. This section records two kinds of drift so business, product, and project work from the same picture.

### A. Built capabilities this document did not previously reflect

These already exist in the product and support the strategy. They are now referenced in the relevant sections below.

| Capability | Supports | Section |
|---|---|---|
| **Passport gamification:** digital passport, paths, stamps, badges (with rarity), leaderboard, progress | Repeat participation, community | §19, §29 |
| **Bidding:** Gear/Talent Foxers bid on event supply requests | Provider marketplace, transparent pricing | §17, §24 |
| **Match requests:** citizen ↔ foxer direct requests with accept/decline | Early form of Journey B | §9, §23 |
| **Organizer Appointments, Check-in Helpers, Shared Inbox** | Organizer tools, operations | §11.7, §21 Phase 2 |
| **Venue ↔ EventFoxer affiliations** | Supply-side relationships | §17 |
| **Promotions and vouchers** | Stage 3 promotion tools (already partly live) | §15 |
| **Multi-currency display (FX rates)** | Geographic expansion readiness | §34 Stage 6 |
| **Waitlist and booking edit requests** | Reliable availability, demand capture | §18 |
| **Specializations (Claimed tags / Earned badges)** | Reputation, trust | §26 |
| **Performer Foxer role** (DJ, band, photo, video, MC) | Talent supply | §11.5 |
| **Identity verification (KYC), audit logs, idempotent payments** | Trust, transaction integrity | §26 |
| **QR check-in** (web only) | Participation, operations | §24 |

### B. Strategy items not yet built

These remain target state. Listed here so they aren't read as shipped.

1. **Public self-service event registration**: still not built (no `EventRegistration`). This is the core of Journey A and Year 1, so it is the most important gap (repeats §1a item 2).
2. **Custom Experiences / "Make It Happen"**: not built and no engineering plan (repeats §1a item 3). Match requests are the closest existing building block.
3. **Referral and campaign tracking** (§20): not built.
4. **Social platform distribution** (§20): only Facebook and Google login exist. No TikTok, Instagram, or YouTube distribution, and sharing is minimal.
5. **Recommendations** (§18): only follow suggestions exist. There is no experience recommender.
6. **Analytics and premium business tools** (§15 Stage 3, §21 Phase 7): only one public event-stats endpoint exists.
7. **Formal dispute handling** (§26): refunds and content reports exist, but there is no dispute workflow.
8. **Mobile parity**: the mobile app covers auth, onboarding, home, search, tickets, passport, profile, and notifications only. Booking checkout, creator dashboards, messaging, and QR check-in are web-only.

---

# 2. My Strategic Recommendation

Based on our current discussions, I do not recommend positioning FoxPassport as simply an event-booking application.

My recommendation is to build FoxPassport as a:

> **Community Experience Marketplace**

However, the business should remain broader than a traditional event marketplace.

FoxPassport should eventually support two fundamental customer behaviors:

### A. Discover Something

A person wants to find an experience that already exists.

Examples:

* a fun run;
* a basketball tournament;
* a community meetup;
* an outdoor activity;
* a festival;
* a concert;
* a workshop.

### B. Create Something

A person has an idea for an experience but needs help making it happen.

Examples:

* a wedding;
* a birthday;
* an anniversary;
* a proposal;
* a private party;
* a family reunion;
* a corporate event;
* a romantic date;
* an outdoor adventure;
* a private beach dinner.

Therefore, the larger opportunity is:

> **People can discover experiences, participate in existing experiences, or create experiences they want to happen.**

FoxPassport connects those people with the organizers, communities, venues, businesses, and specialized providers capable of making those experiences happen.

The long-term business model is therefore:

> **Discover → Create → Organize → Book → Transact → Experience → Return**

---

# 3. Strategic Hierarchy

I recommend maintaining a clear separation between business decisions, product decisions, project execution, and technical implementation.

**Business Strategy**

↓

**Product Management**

↓

**Project Management**

↓

**Technical Architecture**

↓

**Development**

↓

**QA**

↓

**Release & Operations**

| Layer                      | Responsibility                                          |
| -------------------------- | ------------------------------------------------------- |
| **Business Strategy**      | Why we are building the business and where it should go |
| **Product Management**     | What the product should provide                         |
| **Project Management**     | How, when, and by whom priorities are delivered         |
| **Technical Architecture** | How the system should be structured                     |
| **Development**            | How the solution is implemented                         |
| **QA**                     | Whether the solution works correctly and safely         |
| **Operations**             | Whether the platform and business operate effectively   |

This separation is important because business strategy should not become mixed with implementation details.

---

# 4. Business Vision

My recommended long-term vision is:

> **Build a platform where people can discover, create, organize, participate in, and transact around real-world experiences while giving the people and businesses behind those experiences a sustainable way to reach customers and earn.**

I see FoxPassport eventually connecting:

* people;
* communities;
* experiences;
* events;
* organizers;
* venues;
* equipment;
* talent;
* services;
* businesses;
* transactions; and
* partnerships.

The goal is to build an ecosystem rather than a collection of disconnected features.

---

# 5. Business Mission

Our mission should be:

> **Make it easier for people to discover experiences or create the experiences they want, while making it easier for the people and businesses behind those experiences to reach customers and earn.**

The problem we are trying to solve is fragmentation.

Today, a person may need to use multiple platforms and individual providers to organize or participate in one experience.

They may need separate services for:

* discovery;
* community;
* registration;
* payment;
* venue;
* equipment;
* food;
* entertainment;
* photography;
* transportation;
* coordination; and
* follow-up.

At the same time, organizers and providers need to independently find customers and coordinate with other businesses.

FoxPassport should progressively connect these activities into one ecosystem.

---

# 6. The Business Problem We Are Solving

The experience marketplace is fragmented.

A participant may need to figure out:

* what is happening;
* where it is happening;
* who is organizing it;
* what it costs;
* what is included;
* what they need;
* whether slots are available; and
* how to register or book.

Someone who wants to organize their own experience faces an even larger problem.

They may know:

> **"I want something special."**

but not know:

* where to do it;
* who to hire;
* what equipment is required;
* what services are needed;
* how much it should cost;
* how to coordinate everything.

This creates a larger opportunity for FoxPassport.

FoxPassport should become the connection layer between:

**Demand**

People who want to experience or create something.

and

**Supply**

People and businesses capable of providing the locations, products, skills, services, and coordination required.

---

# 7. Any Event, Any Experience

FoxPassport should not be limited to a specific definition of an event.

An experience can be:

* public;
* private;
* personal;
* community-based;
* recreational;
* commercial;
* corporate;
* romantic;
* family-oriented;
* organized;
* spontaneous;
* small; or
* large.

Examples include:

### Community

* community meetup;
* community festival;
* charity activity;
* neighborhood gathering.

### Sports

* fun run;
* basketball tournament;
* football tournament;
* cycling event;
* fitness activity.

### Outdoor

* hiking;
* camping;
* beach activity;
* island trip;
* outdoor adventure.

### Celebrations

* birthday;
* graduation;
* anniversary;
* family reunion;
* private party.

### Weddings

* wedding ceremony;
* wedding reception;
* pre-wedding event;
* wedding-related activities.

### Corporate

* company outing;
* team-building activity;
* conference;
* corporate celebration.

### Romantic

* date;
* anniversary date;
* proposal;
* surprise experience;
* private dinner.

### Custom Experiences

* private beach experience;
* surprise celebration;
* custom activity;
* private gathering;
* personalized experience.

The business should therefore follow the principle:

> **Any Event. Any Experience. Any Community.**

---

# 8. The "Make It Happen" Opportunity

One of the most important long-term opportunities for FoxPassport is to support people who know what they want but do not know how to organize it.

For example:

> **"I want to organize a romantic date for my girlfriend by the seashore."**

The customer may want:

* a beautiful location;
* a private setup;
* flowers;
* food;
* drinks;
* decorations;
* music;
* photography;
* an activity;
* transportation;
* a specific schedule;
* a surprise arrangement.

The customer does not necessarily want to become an event planner.

They simply want:

> **"Make this experience happen."**

This is a powerful extension of the marketplace concept.

FoxPassport can eventually help translate the customer's idea into the services and providers required to execute it.

---

# 9. Two Core Customer Journeys

The long-term product should support two primary journeys.

## Journey A — Discover

The customer asks:

> **"What's happening?"**

Example:

**Discover a fun run**

↓

**View experience**

↓

**Register**

↓

**Pay**

↓

**Participate**

↓

**Return for another experience**

---

## Journey B — Create

The customer asks:

> **"What can I create?"**

or:

> **"I want this experience. Can FoxPassport help me make it happen?"**

Example:

**"I want a romantic beach date."**

↓

**Describe the experience**

↓

**Identify requirements**

↓

**Find suitable providers**

↓

**Select options**

↓

**Book**

↓

**Pay**

↓

**Experience**

↓

**Return**

This second journey represents a major long-term opportunity for FoxPassport.

---

# 10. Our Target Market Strategy

I recommend that we do not attempt to launch everywhere at once.

The marketplace needs density.

Our initial market should therefore have:

* active local communities;
* recurring events;
* tourism or recreational activity;
* independent organizers;
* available venues;
* specialized providers;
* equipment providers;
* service providers; and
* sufficient digital adoption.

The first objective should be to prove that we can create a functioning marketplace in a focused area.

Only after we demonstrate liquidity should we aggressively expand geographically.

However, geographic focus should not limit the **types of experiences** FoxPassport can eventually support.

---

# 11. Customer Segments

I recommend maintaining the following ecosystem structure.

## 11.1 Citizens / Participants

People looking for:

* events;
* activities;
* experiences;
* communities;
* venues;
* services;
* things to do.

They may also want to create a custom experience.

Their value propositions are:

> **Discover and participate.**

and eventually:

> **Create something you want to experience.**

---

## 11.2 Event Foxers

People or organizations that create and organize experiences.

Examples:

* event organizers;
* community leaders;
* activity organizers;
* clubs;
* creators;
* organizations;
* businesses.

Their value proposition is:

> **Create, manage, promote, and monetize experiences.**

---

## 11.3 Venue Foxers

Businesses or individuals providing spaces.

Examples:

* event venues;
* restaurants;
* resorts;
* beaches;
* outdoor locations;
* private spaces;
* recreational facilities.

Their value proposition is:

> **Expose suitable spaces to people and organizers and generate booking opportunities.**

---

## 11.4 Gear Foxers

Providers of equipment required by experiences.

Examples include:

* sports equipment;
* outdoor equipment;
* production equipment;
* recreational equipment;
* specialized equipment.

Their value proposition is:

> **Reach customers who need their equipment.**

---

## 11.5 Talent Foxers

Talent Foxer is the product-facing name for the former Service Foxer category.

This can include:

* photographers;
* instructors;
* guides;
* performers;
* DJs;
* dancers;
* caterers;
* makeup artists;
* decorators;
* technical crews;
* event support;
* specialized professionals.

Their value proposition is:

> **Reach customers who need their skills and services.**

**Decided 14 Sep (§1a item 1):** this rename is adopted, not just proposed — it matches the live UI label already in `roles.ts`. `roles-and-spaces.md`'s separately-planned, distinct sixth RoleType (for entertainment specifically, splitting off `ServiceCategory`) collided with this name and has been re-keyed to `performerFoxer`. `CONTEXT.md`'s domain glossary (both repos) has been updated to match this decision.

---

## 11.6 Investors / Partners

Investment-related functionality should remain a separate business domain.

Investors should not simply be treated as another marketplace provider.

Investment functionality should only be expanded when the underlying business model, legal structure, and regulatory requirements justify it.

**Note (§1a item 5):** this is already further built out than this framing assumes — `PartnerInvestment`/`PartnershipProposal` already support revenue-share percentages, monetary valuation, and inventory investment tied to specific events/venues. Get a legal/compliance read on the existing revenue-share and investment-return fields before treating this section as settled.

---

## 11.7 Organizers and Check-in Helpers

**Added 15 Oct (§1b).** These segments already exist in the product but weren't previously described here.

* **Organizers**: citizens approved for the Organizer role who can be **appointed** by a Mayor (Venue Foxer) or Event Owner to help run a specific venue or event. They share the event's or venue's **Shared Inbox** with guests and suppliers.
* **Check-in Helpers**: lightweight helpers added only to check guests in. They need no role or admin approval.

Their value proposition is:

> **Help run experiences without owning them.**

This supports §19 (community-led growth): a successful organizer can bring other organizers and helpers into the ecosystem.

---

# 12. FoxPassport Ecosystem

The ecosystem I recommend is:

**People**

↓

**Discover or Create an Experience**

↓

**Events / Activities / Custom Experiences**

↓

**Communities + Organizers**

↓

**Venues + Gear + Talent + Services**

↓

**Registration / Booking / Transaction**

↓

**Experience Happens**

↓

**Providers Earn**

↓

**Customer Returns**

↓

**FoxPassport Facilitates the Ecosystem**

The strategic objective is to create value on both sides.

More useful experiences make FoxPassport more valuable to participants.

More participants make FoxPassport more valuable to organizers.

More organizers create more demand for venues and providers.

More providers make it possible to create more types of experiences.

This creates the foundation for marketplace network effects.

**Current State (§1a items 2–3):** the "Registration" step of this flow, and the entire "Create an Experience" / custom-experience branch, are target state. Today only the private, EventFoxer-curated `EventTemplate → Client → Event → Booking` flow is live; public self-service registration (`EventRegistration`) is Phase 1 of Dynamic Events and hasn't shipped, and custom-experience matching (§8/§9 Journey B/§23) has no engineering plan yet at all. **Update 15 Oct (§1b):** still accurate. Direct citizen ↔ foxer **match requests** and supplier **bidding** are live and are the nearest existing building blocks for the Create branch.

---

# 13. Strategic Positioning

I recommend that we stop thinking of FoxPassport primarily as:

> **"An event booking application."**

Instead, we should position it as:

> **"A community experience marketplace."**

Events are an important initial entry point.

However, events are not a permanent limitation.

FoxPassport should eventually support:

* discovering existing experiences;
* joining existing events;
* creating new events;
* organizing private experiences;
* finding providers;
* coordinating services;
* booking;
* paying; and
* participating.

The broader customer proposition is:

> **Discover something you want to experience — or create something you want to happen.**

---

# 14. Business Model

The business model I recommend is:

> **Discovery / Creation → Organization → Booking → Transaction → Experience → Revenue**

FoxPassport creates value by facilitating relationships between:

* participants;
* organizers;
* communities;
* venues;
* gear providers;
* talent providers;
* service providers; and
* businesses.

Our strongest long-term revenue opportunity should come from transactions that directly create value for the marketplace.

Advertising may become a supporting revenue stream, but I do not recommend building the business around advertising.

---

# 15. Revenue Strategy

I recommend a staged monetization approach.

### Stage 1 — Prove Value

Focus on:

* users;
* organizers;
* providers;
* experiences;
* communities;
* participation;
* successful experiences.

At this stage, liquidity is more important than maximizing fees. **Note (§1a item 4):** the platform fee (default 5%, `EventTemplate.platformFeePct`) and Host Markup are already computed on every live transaction — there is no current fee-free mode. Read this stage as proving liquidity at current default rates, not as operating fee-free.

### Stage 2 — Monetize Transactions

Introduce:

* transaction fees;
* booking fees;
* marketplace commissions.

**Note:** given fees are already live (see Stage 1 note), this stage is about adjusting or segmenting take rate — raising rates, adding booking fees on top of the existing platform fee, category-specific commissions — not introducing a fee from zero.

### Stage 3 — Monetize Businesses

Introduce:

* premium organizer tools;
* provider tools;
* analytics;
* promotion;
* business management capabilities.

**Current State (§1b):** promotion tooling is already partly live (Event Foxer **promotions and vouchers**). Analytics is minimal (one public event-stats endpoint). Premium tiers don't exist yet.

### Stage 4 — Monetize Custom Experiences

As custom experiences become viable, FoxPassport can facilitate higher-value bundled transactions.

Examples:

* weddings;
* corporate events;
* private celebrations;
* custom outdoor experiences;
* romantic experiences.

### Stage 5 — Ecosystem Monetization

Explore:

* enterprise partnerships;
* integrations;
* APIs;
* advanced marketplace services.

The recommendation is to avoid prematurely introducing complex monetization before proving that users and providers are willing to transact through the platform.

---

# 16. Marketplace Strategy

The biggest business risk is not whether we can technically build features.

The bigger question is:

> **Can we create enough useful supply and demand in the same place at the same time?**

This is the marketplace cold-start problem.

Therefore, I recommend:

1. Focus on a specific market.
2. Recruit quality organizers and providers.
3. Create useful experiences.
4. Connect with existing communities.
5. Attract participants.
6. Measure actual participation and transactions.
7. Improve the marketplace using real usage data.
8. Expand provider categories based on actual demand.
9. Expand custom experiences progressively.
10. Expand geographically only after liquidity is demonstrated.

A smaller marketplace with active experiences is more valuable than a large marketplace filled with inactive listings.

---

# 17. Supply-Side Strategy

Our initial supply strategy should prioritize quality and activity.

We should actively recruit:

* Event Foxers;
* Venue Foxers;
* Gear Foxers;
* Talent Foxers;
* communities;
* local businesses;
* specialized experience providers.

The objective is not to collect thousands of inactive listings.

The objective is:

> **Create enough active supply to make FoxPassport useful.**

For custom experiences, supply becomes even more important.

A customer requesting a wedding, romantic date, birthday, or private event should eventually be able to find the providers necessary to make that experience happen.

---

# 18. Demand-Side Strategy

For participants, the core value proposition should be:

> **"I can open FoxPassport and find something worth experiencing."**

For customers who want something custom:

> **"I can tell FoxPassport what I want, and find the people who can make it happen."**

Demand strategy should therefore prioritize:

* useful discovery;
* relevant recommendations;
* active local experiences;
* clear information;
* reliable availability;
* simple registration;
* simple booking;
* trustworthy providers;
* good participation experiences;
* custom experience creation;
* repeat participation.

**Current State (§1b):** discovery (search, map with nearby-first, categories), wishlists, waitlists, and booking edit requests are live. Simple public registration and recommendations are not built yet.

Downloads alone should not be treated as success.

---

# 19. Community-Led Growth

Community can become one of FoxPassport's strongest acquisition channels.

A successful organizer can bring:

* participants;
* other organizers;
* venues;
* providers;
* repeat events;
* new communities.

Therefore:

> **Acquiring the right organizers may have a multiplier effect.**

Instead of relying entirely on paid advertising, I recommend building relationships with communities and organizers that can bring recurring activity to the platform.

**Current State (§1b):** community infrastructure is already live: the Republic feed (posts, polls, comments, media tags), follow/block/connections, content reporting, realtime notifications, and **Passport gamification** (stamps, badges, leaderboard), which directly supports repeat participation.

---

# 20. Social Platform & External Platform Connectivity Strategy

I recommend that FoxPassport connect with external platforms whenever those platforms provide a practical, permitted, and commercially useful way to reach users, distribute experiences, or support marketplace growth.

This includes, but is not limited to:

* Facebook;
* Facebook Groups;
* Instagram;
* TikTok;
* YouTube;
* messaging and community platforms;
* creator platforms;
* local community platforms;
* partner platforms;
* business platforms; and
* future platforms with suitable integration capabilities.

The initial external acquisition priority should be **existing communities**, particularly communities already organizing activities through social platforms.

The strategy should not depend on any single external platform.

Instead:

> **External Platforms → Reach & Discovery → FoxPassport → Registration / Creation / Booking → Transaction → Experience**

Potential capabilities may include:

* sharing FoxPassport experiences externally;
* generating shareable experience links;
* publishing or distributing event information;
* allowing organizers to promote experiences;
* allowing participants to share experiences;
* directing external audiences back to FoxPassport;
* supporting referral tracking;
* supporting campaign tracking;
* connecting with partner platforms;
* integrating with future platforms where appropriate.

The purpose of external connectivity is not to make FoxPassport dependent on other platforms.

The purpose is to allow FoxPassport to meet users where they already are.

The long-term objective is:

> **Reach users everywhere we can connect, but build the actual marketplace relationship inside FoxPassport.**

**Current State (§1b):** only Facebook and Google sign-in exist today. Shareable links are minimal, and referral tracking, campaign tracking, and social distribution (TikTok, Instagram, YouTube) are not built.

---

# 21. Product Expansion Strategy

Product expansion should follow marketplace demand rather than technical possibility.

## Phase 1 — Discover and Participate

Focus on:

* discovery;
* experiences;
* events;
* participants;
* registration;
* participation.

## Phase 2 — Organize

Focus on:

* event creation;
* organizer tools;
* scheduling;
* participant management;
* experience management.

## Phase 3 — Transactions

Focus on:

* booking;
* payments;
* transaction infrastructure;
* transaction trust.

## Phase 4 — Provider Marketplace

Expand into:

* venues;
* gear;
* talent;
* services.

## Phase 5 — Community

Expand recurring participation through:

* communities;
* creators;
* social discovery;
* repeat experiences;
* community-led events.

## Phase 6 — Custom Experiences

Progressively support customers who want to create something personalized.

Examples:

* wedding;
* birthday;
* proposal;
* romantic date;
* private beach experience;
* corporate event;
* family gathering.

## Phase 7 — Business Tools

Introduce:

* analytics;
* premium tools;
* promotion;
* operational tools;
* integrations;
* advanced marketplace services.

This allows us to validate the business before increasing complexity.

---

# 22. Dynamic Experiences Strategy

One of my key recommendations is that FoxPassport should avoid building a rigid model where every new experience category requires a separate product structure.

Instead, I recommend a capability-driven approach:

> **Experience Type + Format + Capabilities + Participation Model**

This gives us room to support:

* a wedding;
* a fun run;
* a tournament;
* a community meetup;
* a romantic date;
* a corporate event;
* an outdoor experience;
* a festival.

without creating a completely separate business system for each category.

Dynamic Experiences therefore represent more than a technical architecture decision.

They are a **business scalability strategy**.

---

# 23. Custom Experience Strategy

Custom experiences represent an important long-term business opportunity.

A customer should eventually be able to express an intent such as:

> **"I want to organize a romantic sunset date by the seashore."**

or:

> **"I want to organize my wedding."**

or:

> **"I want to organize a birthday party for 30 people."**

FoxPassport can eventually transform that intent into requirements.

For example:

**Customer Intent**

↓

**Experience Requirements**

↓

**Location**

*

**Food**

*

**Decoration**

*

**Photography**

*

**Entertainment**

*

**Equipment**

*

**Transportation**

↓

**Provider Matching**

↓

**Package / Selection**

↓

**Booking**

↓

**Payment**

↓

**Experience**

The customer does not necessarily need to know which providers are required.

FoxPassport's marketplace can progressively help identify them.

---

# 24. Reuse Existing Infrastructure

I recommend maximizing the reuse of existing FoxPassport infrastructure.

Where we already have capabilities such as:

* bookings;
* payments;
* vendors;
* escrow;
* payouts;
* notifications;
* check-in;
* event management;
* transaction records;

we should treat these as reusable business infrastructure.

**Current State (§1b):** the reusable infrastructure also includes supplier bidding, direct match requests, waitlists, cancellation policies, promotions/vouchers, multi-currency display, organizer appointments, shared inboxes, QR check-in, and identity verification. New categories should reuse these before building new ones.

We should avoid creating separate implementations for every new marketplace category unless there is a strong business reason.

This reduces:

* development cost;
* maintenance cost;
* operational complexity;
* duplicated systems;
* product fragmentation.

---

# 25. Competitive Strategy

I do not recommend trying to beat one specific competitor by copying its feature set.

Our differentiation should come from the combination of:

1. experience discovery;
2. custom experience creation;
3. community;
4. event participation;
5. organizers;
6. venues;
7. gear;
8. talent/services;
9. transactions.

The competitive advantage should ultimately become:

> **The ecosystem itself.**

A competitor may replicate one feature.

It becomes harder to replicate a connected ecosystem where participants, communities, organizers, venues, providers, and businesses continuously interact.

---

# 26. Trust Strategy

Trust must be treated as a business requirement, not merely a feature.

As the marketplace grows, we should progressively establish:

* verified identities;
* reliable provider information;
* transaction records;
* transparent pricing;
* cancellation policies;
* secure payments;
* reviews and reputation;
* dispute handling;
* platform rules.

Custom experiences require an even stronger trust model because customers may depend on multiple providers for a single experience.

The level of trust infrastructure should therefore grow with marketplace activity.

**Current State (§1b):** live today: identity verification (document upload with admin review), reviews and replies that require a completed booking, Claimed/Earned specializations, cancellation policies, payment protection with confirmation deadlines, refunds, content reporting, audit logs, and rate-limited authentication. There is no formal dispute workflow yet.

---

# 27. Financial Strategy

I recommend sustainable growth over premature scale.

Our financial priorities should be:

* minimize unnecessary fixed costs;
* prioritize high-value product development;
* monitor infrastructure costs;
* understand transaction economics;
* validate revenue before scaling expenses;
* avoid premature geographic expansion;
* maintain sufficient operating runway.

Growth should be supported by evidence rather than assumptions.

---

# 28. Unit Economics

For each major transaction type, I recommend monitoring:

* Gross Transaction Value;
* FoxPassport fee;
* payment processing costs;
* refunds;
* cancellations;
* support costs;
* acquisition costs;
* operational costs;
* contribution margin.

The business should eventually understand profitability at the transaction level rather than relying only on total revenue.

Custom experiences should also be evaluated based on:

* average order value;
* provider count per experience;
* transaction margin;
* coordination cost;
* support cost;
* repeat purchase potential.

---

# 29. Business KPIs

The primary business metrics I recommend are:

* Gross Transaction Value;
* FoxPassport Revenue;
* completed transactions;
* active participants;
* active organizers;
* active providers;
* active experiences;
* event registrations;
* completed experiences;
* repeat participants;
* repeat organizers;
* repeat experiences;
* custom experience requests;
* custom experience conversion;
* marketplace liquidity;
* contribution margin.

Downloads alone should not be treated as the primary indicator of business health.

---

# 30. North Star Metric

I recommend that our long-term North Star be:

> **Successful real-world experiences facilitated through FoxPassport.**

This is more meaningful than downloads alone.

A user downloading FoxPassport does not necessarily create business value.

A user discovering an experience, creating an experience, registering, booking, paying, and successfully participating does.

Revenue remains critical, but revenue should follow successful customer outcomes.

---

# 31. Strategic Prioritization

I recommend evaluating major initiatives using:

1. **Customer Value**
2. **Marketplace Impact**
3. **Revenue Potential**
4. **Strategic Advantage**
5. **Growth Potential**
6. **Community Impact**
7. **Operational Complexity**
8. **Technical Risk**
9. **Implementation Cost**

When possible, we should prioritize initiatives that improve multiple dimensions at the same time.

---

# 32. Business Decision Framework

Before we enter a new category, market, or business model, I recommend asking:

### Customer

* Who needs this?
* What problem are we solving?
* Is the problem significant?
* Is this an existing experience or a custom experience?

### Community

* Can communities use this?
* Can organizers bring participants?
* Does this create repeat participation?

### Marketplace

* Does this create supply?
* Does this create demand?
* Does this improve liquidity?
* Are the required providers available?

### Business

* Can we monetize it?
* Is the revenue model sustainable?
* What will it cost to operate?
* Does the transaction create sufficient value?

### Strategic

* Does it strengthen the ecosystem?
* Does it create a meaningful advantage?
* Does it support our long-term direction?

### Execution

* Can the current team support it?
* What additional operational complexity will it create?
* What must be built before it becomes viable?

---

# 33. Business Guardrails

I recommend that we avoid:

* expanding too many categories simultaneously;
* building features without validated demand;
* relying entirely on advertising;
* expanding geographically before achieving liquidity;
* creating a separate system for every experience type;
* creating unnecessary operational complexity;
* sacrificing trust for short-term revenue;
* optimizing revenue before achieving useful marketplace activity;
* becoming dependent on a single social platform;
* treating event listings as success without actual participation;
* attempting to automate complex custom experiences before the marketplace has sufficient provider supply.

The principle is:

> **Validate → Prove → Improve → Scale**

---

# 34. Strategic Roadmap

## Stage 1 — Foundation

**Objective: Establish a functioning experience and event marketplace.**

Focus on:

* discovery;
* experiences;
* organizers;
* participants;
* registration;
* participation;
* foundational marketplace infrastructure.

Initial experience examples may include:

* community fun run;
* sports tournament;
* outdoor experience;
* community meetup.

---

## Stage 2 — Marketplace

**Objective: Connect experiences with supporting providers.**

Focus on:

* venues;
* gear;
* talent/services;
* provider discovery;
* bookings;
* transactions.

---

## Stage 3 — Community

**Objective: Build recurring participation.**

Focus on:

* communities;
* creators;
* repeat experiences;
* discovery;
* social/community features;
* external community acquisition.

---

## Stage 4 — Monetization

**Objective: Establish sustainable revenue.**

Focus on:

* transaction fees;
* booking fees;
* marketplace commissions;
* premium tools;
* promotion;
* business services.

---

## Stage 5 — Custom Experiences

**Objective: Allow people to create experiences rather than only discover existing ones.**

Examples:

* weddings;
* birthdays;
* anniversaries;
* proposals;
* romantic dates;
* private parties;
* corporate events;
* family gatherings;
* private outdoor experiences.

---

## Stage 6 — Ecosystem

**Objective: Become a broader experience platform.**

Focus on:

* integrations;
* enterprise partnerships;
* APIs;
* advanced business tools;
* geographic expansion;
* broader experience categories.

---

# 35. Three-Year Strategic Direction

## Year 1 — Prove

Our objective is to prove that FoxPassport can:

* attract participants;
* attract organizers;
* create useful experiences;
* build community activity;
* facilitate participation;
* facilitate transactions;
* generate repeat participation.

The initial experience strategy may progress through:

**Community Fun Run**

↓

**Sports Tournament**

↓

**Outdoor Experience**

↓

**Community Meetup**

↓

**Experience Fair**

↓

**Community Festival**

These are examples for proving the marketplace, not limitations on what FoxPassport can eventually support.

---

## Year 2 — Scale

Once the model is proven, scale:

* marketplace supply;
* participant demand;
* provider categories;
* community relationships;
* monetization;
* custom experiences;
* geographic coverage.

---

## Year 3 — Expand

Expand into:

* broader experience categories;
* larger markets;
* business tools;
* custom experience services;
* strategic partnerships;
* ecosystem integrations.

These timelines should remain flexible.

Actual performance should determine when we move from one stage to another.

---

# 36. Major Business Risks

### Marketplace Risk

Insufficient supply or demand.

### Event Risk

Events are created but fail to attract meaningful participation.

### Custom Experience Risk

Customers request experiences that the marketplace does not yet have enough providers to fulfill.

### Monetization Risk

Users or providers are unwilling to pay platform fees.

### Trust Risk

Fraud, disputes, unreliable providers, or poor experiences.

### Operational Risk

Marketplace and custom-event operations become too complex.

### Financial Risk

High acquisition costs or low transaction margins.

### Competition Risk

Established platforms introduce similar capabilities.

### Technology Risk

Technical complexity slows business iteration.

### Platform Dependency Risk

External social platforms change APIs, policies, reach, or commercial conditions.

### Expansion Risk

FoxPassport expands geographically or categorically before the core marketplace is repeatable.

---

# 37. Business Change Management

This strategy should not be treated as permanently fixed.

If evidence changes, our strategy should change.

Major strategic changes should be based on:

* customer feedback;
* event performance;
* marketplace data;
* custom experience demand;
* financial results;
* transaction performance;
* competitive conditions;
* operational constraints;
* product performance.

When we change direction, the decision should be documented so the product and project teams are working from the same strategic source of truth.

---

# 38. Relationship With Product Management

The separation should remain clear.

### Business Strategy

**WHY**

> **We want FoxPassport to become a community experience marketplace where people can discover existing experiences or create the experiences they want.**

### Product Management

**WHAT**

> **We build the product capabilities required to support discovery, creation, organization, participation, transactions, communities, and marketplace growth.**

### Project Management

**HOW / WHEN**

> **We organize and execute the work required to deliver those capabilities.**

### Technical Architecture

**HOW TECHNICALLY**

> **We determine how those capabilities should be implemented within the system.**

This prevents implementation details from driving business direction.

---

# 39. Relationship With Project Management

Project Management should execute against business and product priorities.

A project should exist because it supports:

* a business objective;
* a product objective;
* a necessary operational objective; or
* a necessary technical objective.

I do not recommend prioritizing projects simply because they are technically interesting or easy to implement.

The project roadmap should therefore trace back to the business strategy.

---

# 40. My Strategic Principles

I recommend that FoxPassport operate according to the following principles:

### 1. Customer Value Before Monetization

Create meaningful value before aggressively extracting revenue.

### 2. Events and Experiences Before Marketplace Expansion

Use real experiences to establish the first meaningful customer behavior.

### 3. Community Is an Asset

Organizers, providers, and participants should strengthen the network.

### 4. Liquidity Before Expansion

Prove a functioning marketplace before expanding everywhere.

### 5. Any Experience, But Focused Execution

The business vision should be broad, but execution should remain focused.

### 6. Ecosystem Over Isolated Features

Prefer capabilities that strengthen multiple parts of the platform.

### 7. Reuse Over Duplication

Build reusable business infrastructure.

### 8. Trust Is Part of the Product

Reliable transactions and experiences are fundamental.

### 9. Platform Independence

Use external platforms for reach without becoming dependent on them.

### 10. Evidence Over Assumptions

Use real customer and marketplace data to guide decisions.

### 11. Sustainable Growth Over Vanity Growth

Active participants and successful experiences matter more than download numbers.

### 12. Validate Before Scaling

Do not scale a business model before proving that it works.

---

# 41. Final Business Direction

My recommendation is for FoxPassport to become a:

> **Community Experience Marketplace**

The business should not be limited to event discovery or event booking.

The long-term model is:

> **Discover Something → Participate**

or:

> **Imagine Something → Create It**

Both paths eventually connect to the same marketplace.

The broader model is:

**People**

→

**Discover or Create Experiences**

→

**Communities / Organizers**

→

**Venues + Gear + Talent + Services**

→

**Registration / Booking / Transaction**

→

**Real-World Experience**

→

**Providers Earn**

→

**Customer Returns**

→

**FoxPassport Facilitates the Ecosystem**

---

# 42. Examples of the FoxPassport Vision

FoxPassport could eventually support:

### Existing Experience

> **"I want to join a fun run this weekend."**

FoxPassport helps the customer discover and register.

### Wedding

> **"I want to organize my wedding."**

FoxPassport can eventually connect the customer with venues, catering, photography, decoration, entertainment, makeup, transportation, and other providers.

### Birthday

> **"I want to organize a birthday party for my family."**

FoxPassport can help connect the customer with the required services.

### Outdoor Experience

> **"I want to organize a hiking trip for my friends."**

FoxPassport can connect the experience with guides, transportation, equipment, and other requirements.

### Romantic Experience

> **"I want to surprise my girlfriend with a romantic date by the seashore."**

FoxPassport can eventually help the customer arrange:

* the location;
* setup;
* flowers;
* food;
* decoration;
* photography;
* activities;
* transportation; and
* other requirements.

The customer does not need to know how to organize everything.

The customer simply needs to know:

> **"This is what I want."**

That is the long-term opportunity.

---

# 43. Business North Star

My recommended long-term direction is:

> **Make FoxPassport the platform where people discover, create, and participate in real-world experiences, while giving the people and businesses behind those experiences a sustainable way to reach customers and earn.**

---

# 44. Final Strategic Principle

> **Build the business around the ecosystem, but keep the customer experience simple.**

FoxPassport should remain flexible enough to support:

* new experiences;
* new event types;
* new communities;
* new providers;
* new business models;
* new transaction types.

But we should not attempt to build everything at once.

We should:

> **Create useful experiences → connect communities → prove participation → enable transactions → connect providers → support custom experiences → measure results → scale what works.**

The customer proposition should remain simple:

> **Discover it. Create it. Book it. Experience it.**

---

*Companion to `DYNAMIC-EVENTS-PRODUCT-MASTER.md` (product direction), `DYNAMIC-EVENTS-PROJECT-MASTER.md` (execution/delivery process), and `DYNAMIC-EVENTS-PLAN.md` (technical plan) — this document sits one layer above them in the Strategic Hierarchy (§3) and should be reconciled with them, not the other way around, per §37 Business Change Management. Feature-level reconciliation lives in [`foxpassport-feature-audit.md`](./foxpassport-feature-audit.md) (see §1b).*
