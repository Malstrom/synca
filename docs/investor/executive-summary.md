# Synca — Executive Summary

**Confidential — For Investor Use Only**
*May 2026*

---

## The Problem

Dating apps are broken — not because there are too few people on them, but because they surface the wrong ones. The dominant swipe model generates volume, not quality. Nearly 79% of Gen Z users report burnout from endless swiping, 27% of social mentions about dating apps are negative, and the post-match experience fails almost as often as the match itself.

Beneath the UX problem lies a deeper structural flaw. Current matching relies entirely on self-reported data: photos, bios, stated preferences. These capture how people want to be seen, not how they actually live. Two people can share interests on paper but run on completely different biological clocks, travel with opposite philosophies, and listen to music that signals entirely different emotional profiles — incompatibilities discovered only after meeting. Compounding this, fake profiles, escort accounts, and inauthentic users pollute every major platform with no effective systemic solution.

---

## The Solution

Synca is a precision matchmaking platform that builds a **multi-signal lifestyle compatibility profile** for each user from passive, continuous, objective data sources — and proposes **one highly curated match at a time**, already paired with a pre-organized date.

### The Signal Stack

Synca progressively combines five categories of lifestyle signals:

**1. Health biometrics** *(core, MVP)*
Sleep patterns, activity rhythms, peak energy windows, routine consistency, and recovery behavior — read from Apple Health (iOS) and Health Connect (Android). Passive, continuous, and structurally difficult to fake.

**2. Visual preference inference** *(core, MVP)*
An onboarding game powered by AI-generated archetypes builds a personal preference embedding from each user's spontaneous visual choices.

**3. Photo context analysis** *(core, MVP)*
AI analysis of uploaded photos evaluates contextual signals — setting, style, activity type, lifestyle cues — rather than physical attributes.

**4. Travel behavior** *(post-MVP v1)*
Integration with travel services reveals how often someone travels, how far, and whether they seek new experiences or return to familiar places.

**5. Music listening profile** *(post-MVP v1)*
Spotify API integration exposes audio features and listening time patterns. Music correlates deeply with personality and emotional profile.

---

## Key Product Features

**Two Match Origins — One Quality Bar**
Synca generates matches through two complementary paths:
- **Spark-origin** (`origin: spark`): created when two users complete a verified in-person Spark session. The highest-trust match type. Available on the free tier. Labeled *“Synca confermata”* in the UI.
- **Algorithm-origin** (`origin: algorithm`): generated nightly by a background job that analyses health summaries across the user base. Increases match volume from day one for users who haven’t yet met in person. **Premium-only feature.** Labeled *“Synca suggerita”* in the UI.

Both origins produce the same `Match` object and the same compatibility breakdown. The `origin` field allows the UI to communicate trust level transparently to the user.

**Pre-Organized Date Proposals**
After a match, Synca generates 1–3 concrete date proposals based on both users’ energy peaks, sleep schedules, geographic proximity, and activity preferences.

**Selective Ghosting System**
Profiles showing patterns consistent with inauthenticity receive progressively reduced visibility without notification. A multi-layer Trust Score maintains community quality automatically.

**Onboarding Preference Game**
A short visual game using AI-generated person archetypes builds each user’s preference embedding implicitly.

**Synca Spark — Live In-Person Compatibility Game**
When two people meet physically — at a gym, a sauna, a run club, or any social event — either person can open Synca and start a **Spark session**. The other user joins by scanning a QR code or entering a short session code. Over approximately 3 minutes, both complete a synchronized live compatibility mini-test directly on their devices. At the end, they receive:
- An instant compatibility snapshot across the core dimensions (sleep rhythm, energy, lifestyle)
- A suggested first date proposal if both find the result interesting
- A **reward for both users**: one free week of Premium (for existing free users) or one free curated match credit (for existing Premium users)

Synca Spark serves three strategic goals simultaneously: it onboards two fully profiled users in one session, it creates a natural viral loop at physical community events, and it provides a powerful retention hook by rewarding real-world social behavior. Every Spark session is also a Trust Score booster — two users who met in person and both completed the session receive a verified IRL interaction badge.

**Sync Rooms — Verified Group Spaces (v2)**
A Sync Room is a group conversation space that can only exist when all members have a verified Spark with the creator — anti-fake by design. Three room types:

| Type | Members | Use case | Spark rule |
|---|---|---|---|
| `duo` | 2 | 1-to-1 match chat | 1 Spark between the 2 users |
| `small_group` | 3–8 | Friends, aperitivo, weekend plans | Full Spark graph: every pair |
| `event` | 9–22 | Calcetto, escape room, padel | Each member ≥1 Spark with creator |

`small_group` and `event` rooms are premium-only. The `event` type unlocks large organized activities — calcetto, escape rooms, padel tournaments — creating a powerful retention surface and a natural B2B partnership anchor with venue operators.

---

## Architecture

```
iOS App (HealthKit)           ─┬
Android App (Health Connect)  ─┤──→  Rails API Backend  ←──→  Telegram Bot / Mini App
Spotify / Travel APIs         ─┘          ↕
                                     Web Payment Page
```

- **Native apps** aggregate health data on-device. Raw samples never reach the server — only anonymized summaries.
- **Rails API** runs all matching logic (Spark-origin + algorithm-origin), trust scoring, date proposal generation, signal enrichment, Spark session management, Sync Room validation, and premium access management. Background jobs run via **Solid Queue** (no Redis dependency).
- **Action Cable** (WebSocket, built into Rails) powers real-time Spark sessions and Sync Room messaging. Scales to tens of thousands of concurrent connections without additional infrastructure.
- **Telegram Bot / Mini App** serves as the primary acquisition funnel and payment interface — critical for Russia where Telegram penetration reaches 64.4%.
- **External payment page** processes all transactions outside App Store / Google Play, eliminating the 30% platform commission.

---

## Market Opportunity

The global dating app market is valued at **$11.61 billion in 2025**, projected to reach **$24.85 billion by 2035** (CAGR 7.91%). The AI-curated matchmaking segment is the fastest-growing subsector, with $30M+ invested in 18 months across comparable startups — all without health data, all US-only.

| Competitor | Model | Funding | Gap vs Synca |
|---|---|---|---|
| Keeper | AI + human matchmaker | $4M | No health/travel/music data, US only |
| Known | AI + in-person dates | $9.7M | No health/travel/music data, US only |
| Sitch | Pay-per-match | $6.7M | No health/travel/music data, US only |
| Ditto | AI, no swipe | $9.2M | No health/travel/music data |
| Hinge | Curated mainstream | $550M+ revenue | No objective data, swipe model |

**No existing competitor combines objective health biometrics, travel behavior, music profile, visual preference inference, live IRL Spark sessions, verified group spaces, and pre-organized dates in a single platform — across international markets.**

### Seven-City Launch Map

| City | Key Driver | Wave |
|---|---|---|
| **Moscow** 🇷🇺 | Post-Tinder vacuum, +25.3% dating audience 2024, Telegram 64.4% | 1 |
| **Bangkok** 🇹🇭 | Extreme fake/escort problem, expat community, 20%+ daily users 25–34 | 1 |
| **Dubai** 🇦🇪 | Smartwatch penetration 35.1% globally highest, premium fitness culture | 1 |
| **Seoul** 🇰🇷 | Premium niche app culture, demographic crisis driving demand | 2 |
| **Milan** 🇮🇹 | iOS-dominant premium users, fitness culture, GDPR-native | 2 |
| **São Paulo** 🇧🇷 | Largest Latin America dating market $420M | 3 |
| **Mexico City** 🇲🇽 | #1 city globally for Tinder Passport usage | 3 |

---

## Business Model

**Premium Subscription** — €12–15/month (market-adjusted).
- Free tier: health dashboard, onboarding games, Spark-origin matches only (up to 3 active), basic match visibility.
- Premium tier: algorithm-origin matches (*“Synca suggerita”*), unlimited active matches, complete compatibility breakdown, date proposals, Sync Rooms (`small_group` + `event`), signal enrichment.

All payments via Telegram or external web page — zero App Store commission.

**Pay-per-Match / Date Pack** — Curated match or ready-made date experience purchased individually.

**Synca Spark Reward Loop** — Each Spark session awards both participants one free Premium week or one free match credit, depending on their current plan. This creates a direct, measurable incentive to use Synca at every IRL social event and drives both acquisition and re-engagement.

**B2B Venue Partnerships** — Gyms, saunas, padel courts, and cafés integrated into the date proposal and Sync Room event system. Synca drives structured traffic; venues offer preferential rates packaged as “date packs”. Event Rooms (9–22 members) are a natural anchor for venue co-branding.

**Commission-Free Payment Infrastructure** — Telegram Stars, YooMoney, SBP (Russia), Stripe via external link.

---

## Go-To-Market

Community-first, city-by-city:

1. Identify 2–3 micro-communities (run clubs, gyms, saunas) with high wearable penetration
2. Partner with community organizers as local ambassadors
3. Host invite-only seeding events — entry requires completing onboarding. One event = 50–150 fully profiled users
4. Physical manifests in gyms, saunas, and fitness spaces with city-specific QR codes linking to Telegram Bot
5. Activate Synca Spark at every event: organizers demo the feature live, generating Spark sessions on-site
6. Activate match engine only after reaching minimum density (~300–500 active users per city)
7. Launch B2B venue partnerships within 8 weeks of city activation

---

## Why Now

- **Swipe fatigue is peaking**: 79% of Gen Z reports dating app burnout; Bumble lost 19% of downloads in 2024
- **Health and lifestyle data infrastructure is mature**: Apple HealthKit has 89M active users; Health Connect replaces Google Fit as Android standard in 2026
- **AI-curated matchmaking is being funded internationally**: $30M+ in the segment in 18 months — all US-only, all without health or lifestyle data signals
- **IRL social events are resurging**: post-pandemic return to physical community spaces creates the perfect distribution channel for Synca Spark

---

## Signal Expansion Roadmap

```
MVP                    Post-MVP v1              Post-MVP v2             v3
─────────────────────  ──────────────────────   ─────────────────────   ──────────────────
✓ Sleep & activity     + Spotify integration    + Google Maps Timeline  + Cross-signal
  health data          + Travel preference        (travel behavior)       validation
✓ Visual preference      game                  + Deep audio features   + Predictive
  game (AI archetypes) + Basic travel signals    (Spotify)               compatibility
✓ Photo context AI     + Apple Music support   + Multi-source trust      modeling
✓ Synca Spark (IRL)                              scoring upgrade
✓ Algorithm matching  + Sync Rooms v2          + Group compatibility
  (premium, nightly)    (duo/group/event)         engine v1
✓ Telegram Bot +
  payment infra
```

---

## Beyond 1-to-1: Sync Rooms & Group Compatibility

Synca's matching architecture is intentionally designed to support **group compatibility** from day one. The data model uses a participant join table rather than a fixed two-user structure.

**Sync Rooms (v2)** are the first expression of this: verified group spaces where every member has a real-world Spark connection to the creator. This is not a generic group chat — it is a social graph built from physical encounters, anti-fake by structural design.

Three room types address progressively larger social contexts:
- `duo` (2): the standard 1-to-1 match chat, already in MVP
- `small_group` (3–8): friends, weekend plans, shared activities
- `event` (9–22): calcetto, escape rooms, padel — the natural bridge to B2B venue partnerships

**Group compatibility engine (v3+)** extends pairwise scores to model multi-user group cohesion — suggesting curated small groups for shared experiences (morning runs, sauna sessions, travel groups). This positions Synca as a **social compatibility platform** rather than a pure dating app, a TAM expansion that no current competitor is pursuing with objective behavioral data.

---

## Traction & Status

- Product architecture fully defined across all layers (iOS, Android, Rails backend, Telegram Bot, payment infrastructure)
- Repository initialized as monorepo (iOS app, backend API, documentation)
- iOS MVP in active development
- Matching model defined: weighted scoring across 8 dimensions, dual origin (Spark + algorithm)
- Synca Spark session flow designed and scoped
- Sync Rooms architecture designed: `duo`, `small_group`, `event` room types
- Market analysis completed across 7 cities
- Telegram architecture and payment infrastructure scoped for Russian market launch

---

## The Ask

*[To be completed: funding amount, use of funds, valuation, and terms.]*

Priority use of seed capital: engineering team (Android developer + backend engineer), Moscow community seeding events and venue partnerships, Yandex AI and Spotify API integrations, Synca Spark MVP implementation, and 6-month runway to first-city product-market fit validation.

---

*Full documentation package: [`docs/investor/litepaper.md`](litepaper.md) · [`docs/investor/market-analysis.md`](market-analysis.md) · [`docs/investor/technical-whitepaper.md`](technical-whitepaper.md) · [`docs/investor/financial-model.md`](financial-model.md)*
