# Synca Litepaper

**Version 1.4 — May 2026**
*Confidential — For Investor and Partner Use Only*

---

## 1. Vision

The way people meet has not fundamentally changed in ten years. The swipe interface, introduced by Tinder in 2012, became the default interaction model for an entire generation. It optimized for one thing: volume. More swipes, more matches, more engagement time. What it did not optimize for — and structurally cannot — is compatibility.

Synca is built on a different premise: **the data to determine compatibility between two people already exists on their phones, recorded passively every single day**. Sleep times, activity rhythms, energy peaks, music taste, travel patterns — these are not opinions or self-presentations. They are behavioral fingerprints. Synca reads them, compares them, and surfaces one person at a time when a genuine lifestyle match is identified. It then proposes the date itself.

The goal is not to help people swipe more. The goal is to help people meet fewer, better people — and actually show up.

---

## 2. The Problem in Depth

### 2.1 Swipe Fatigue Is Structural, Not Cyclical

Dating app burnout is not a passing trend. It is the inevitable output of a system designed to maximize session length rather than successful outcomes. Nearly 79% of Gen Z users report emotional exhaustion from dating apps. Bumble lost 19% of its downloads in 2024 alone. Social sentiment around dating apps is net negative: 27% of mentions are negative versus 16% positive.

The apps know this. Hinge's entire brand proposition — "designed to be deleted" — is an implicit admission that the swipe model fails users. Yet even Hinge's core mechanic is still profile browsing. The format has been reframed but not replaced.

### 2.2 Self-Reported Data Is Broken by Design

Every current matching system is ultimately trained on what users say about themselves, not on how they behave. This creates three compounding problems:

- **Presentation bias**: people optimize their profiles for attractiveness, not accuracy.
- **Static snapshots**: a profile captures one moment. It does not update as the person's life changes.
- **Absence of behavioral data**: nobody describes their actual sleep schedule, energy patterns, or how often they actually leave the house.

### 2.3 The Fake and Escort Problem

On platforms operating in Bangkok, Dubai, Moscow, and similar urban markets, a significant portion of female profiles are not genuine users seeking relationships. They are either professional escorts, accounts managed by third-party agencies, or outright fakes. The result is a broken trust environment that degrades the experience for all authentic users.

### 2.4 The Post-Match Failure

Even when a genuine match occurs, the majority fail to convert into a real meeting. Neither person knows how to break the conversational ice, no one wants to be the first to propose something specific, and the logistics of finding a mutually convenient time and place become an obstacle. Most matches end in silence within 48 hours.

---

## 3. The Synca Approach

Synca replaces the swipe model with a **lifestyle compatibility engine** that works passively in the background, proposes a match only when conditions are genuinely aligned, and immediately bridges that match to a real-world meeting.

### 3.1 The Core Shift: From Profiles to Behavioral Signals

Synca does not ask users to describe themselves. It reads what they actually do:

- When they sleep and wake up (sleep onset, offset, duration)
- How stable their daily routine is (variance across days)
- When their energy peaks during the day (peak activity window)
- How active they are overall (steps, active energy, workout sessions)
- How they recover (resting heart rate trends, HRV if available)
- What music they listen to, when, and what it reveals about their emotional profile
- How they travel — how often, how far, and whether they seek novelty or familiarity

### 3.2 The Five Signal Layers

**Layer 1 — Health Biometrics (HealthKit / Health Connect)**
The foundation. Sleep alignment, peak activity window overlap, routine stability matching, activity level similarity, personal space index, and recovery pattern compatibility combine into a lifestyle rhythm score. Raw health data never leaves the user's device.

**Layer 2 — Visual Preference Inference**
During onboarding, users play a short game. Synca shows pairs of AI-generated person archetypes. The user taps intuitively — no categories, no filters, no declarations. Over 10–15 rounds, these choices build a personal preference embedding.

**Layer 3 — Photo Context Analysis**
When users upload profile photos, Synca's AI analyzes contextual signals: setting, objects and props, activity type, style consistency across photos.

**Layer 4 — Travel Behavior (Post-MVP v1)**
Integration with travel services reveals how often someone travels, how far from home, and whether they seek new experiences or prefer familiar places.

**Layer 5 — Music Listening Profile (Post-MVP v1)**
Spotify OAuth integration exposes audio features across each user's listening history: energy level, emotional valence, tempo, diversity of genres, and listening time patterns.

---

## 4. Product Experience

### 4.1 Onboarding

1. **Sign in with Apple / Google** — identity and basic profile
2. **Health data authorization** — HealthKit (iOS) or Health Connect (Android), with granular consent controls
3. **Preference game** — 10–15 rounds of visual archetype choices
4. **Optional enrichments** — connect Spotify, enable location zones, indicate travel style via mini-game
5. **Dashboard unlock** — the user immediately sees their own lifestyle profile: chronotype, peak energy window, routine stability, activity level, music personality

### 4.2 The Match Experience

Synca produces matches through two distinct origins, each with its own UX label so users always understand the source of the connection.

#### 4.2.1 Match from Spark (Origin: IRL — available to all tiers)

When two users complete a Spark session and their compatibility score meets or exceeds the match threshold, a Match is created automatically. Both users are notified immediately. The match card displays:
- A **"Synca Confirmed"** badge — signalling a verified in-person origin
- The compatibility snapshot computed during the live session
- 1–3 concrete date proposals anchored to the activity context of their meeting location

This is the primary match flow for MVP. It rewards genuine IRL interaction and produces the highest-quality matches in the system, because both users have already met and chosen to Spark.

#### 4.2.2 Match from Algorithm (Origin: Curated — Premium feature)

When the nightly `MatchingJob` identifies a sufficiently strong bilateral compatibility between two users who have not yet met, a match proposal is surfaced. The match card displays:
- A **"Synca Suggests"** badge — distinguishing it clearly from IRL-verified matches
- A plain-language explanation of the compatibility across key dimensions
- A compatibility score broken into readable dimensions
- 1–3 concrete date proposals: type of activity, suggested time window, approximate area of the city

Both users see the proposal independently. If both accept, a chat opens — already anchored to the selected date context.

Algorithm-originated matches are a **Premium-only feature**. Free-tier users can receive and complete Spark sessions and view their resulting IRL matches, but curated algorithmic suggestions require an active Premium subscription.

### 4.3 Synca Spark — Live In-Person Compatibility Game

Synca Spark is the bridge between the physical and digital world. When two people meet in real life — at a gym, a sauna, a run club event, a coworking space, or any social gathering — either person can initiate a Spark session directly from the app.

**How it works:**

1. User A opens Synca and taps **"Spark"**. A session QR code and 6-digit code appear on screen.
2. User B scans the QR code or enters the code. Both phones are now linked in a live session.
3. Over approximately **3 minutes**, both users independently answer a short synchronized compatibility micro-test on their own device — quick visual and behavioral questions that enrich the matching profile in real time.
4. The result screen appears simultaneously on both phones:
   - **Instant compatibility snapshot** across the core dimensions (sleep rhythm alignment, energy profile, lifestyle score)
   - A **suggested first date proposal** based on their combined signals and current location context
   - A **reward for both**: one free week of Premium (for free-tier users) or one free curated match credit (for Premium users)
5. If the compatibility score meets or exceeds the match threshold, a **Match record is created automatically** (`origin: :spark`) and both users are notified that they have a confirmed Synca connection.

**Why Synca Spark matters strategically:**

- **Acquisition**: every Spark session onboards two fully profiled users simultaneously at zero marginal cost
- **Viral loop**: it turns every gym, sauna, or run club event into a natural Synca distribution point
- **Trust Score boost**: both participants receive a verified IRL interaction badge, raising their Trust Score — making them more visible in the matching queue
- **Retention hook**: the reward incentivizes existing users to keep attending community events and to re-engage with the app each time they meet someone interesting in person
- **Anti-fake signal**: a Spark session between two real people in the same physical location is nearly impossible to fake — it functions as the strongest liveness verification in the system
- **Group compatibility foundation**: each completed Spark session enriches the individual compatibility profile and contributes IRL-verified data points that will power the Sync Room group layer in v2+

**Reward mechanics by user type:**

| User type at time of Spark | Reward received |
|---|---|
| Free tier | 7 days of Premium, unlocked immediately |
| Premium (active subscription) | 1 free curated match credit, valid 30 days |
| Premium+ (active subscription) | 1 free curated match credit + profile boost for 24h |
| Lapsed Premium (churned) | 7 days of Premium re-activation — re-engagement hook |

> The Spark reward system is designed to be self-funding: each 7-day trial converts at an estimated 20–35% to paid Premium (consistent with RevenueCat 2025 data on re-engagement trial conversion). The cost of one free week is approximately €3.50 at blended ARPU — justified by the dual acquisition value of the session.

### 4.4 Selective Ghosting and Trust Architecture

Every profile carries a dynamic Trust Score composed of:

- **Liveness check**: photo anti-spoofing at upload
- **Image forensics**: detection of AI-generated images, heavy editing, metadata inconsistencies
- **Reverse image lookup**: near-duplicate search to identify photos used across multiple platforms
- **Behavioral signals**: message patterns, external link sharing, emoji patterns correlated with transactional accounts
- **Health data quality**: variance analysis — impossibly uniform data signals fabrication
- **Cross-signal consistency**: music listening patterns that contradict stated chronotype lower the score
- **Synca Spark IRL verification**: confirmed in-person sessions raise the Trust Score significantly; `irl_verification_count` is tracked per user and factored directly into the score

Profiles below Trust Score thresholds receive progressively reduced visibility. They are not banned, not notified, and can raise their score by completing genuine onboarding steps including a Spark session.

---

## 5. Technical Architecture

### 5.1 System Overview

```
┌─────────────────────┐    ┌──────────────────────┐
│   iOS App           │    │   Android App        │
│   SwiftUI + MVVM    │    │   Kotlin             │
│   HealthKit         │    │   Health Connect     │
│   Local aggregation │    │   Local aggregation  │
│   Spark QR engine   │    │   Spark QR engine    │
└────────┬────────────┘    └──────────┬───────────┘
         │  Anonymized health summary │
         └──────────────┬─────────────┘
                        ▼
         ┌──────────────────────────────┐
         │     Rails API Backend       │
         │     PostgreSQL              │
         │     Matching Engine         │
         │     Trust Scoring           │
         │     Spark Session Manager   │
         │     Date Proposal Generator │
         │     Signal Integration      │
         │     Reward Engine           │
         └──────┬──────────────────────┘
                │
     ┌──────────┼──────────────┐
     ▼          ▼              ▼
Telegram   iOS/Android    Web Payment
Bot/TMA    Push Notify    Page (Stripe /
                         YooMoney / SBP)
```

### 5.2 Health Data Privacy Model

- Raw health samples are processed exclusively on the user's device and are never transmitted
- Only derived, aggregated metrics are sent to the backend: chronotype label, peak activity window, routine stability index, average activity level, recovery quality tier
- Spark session micro-test answers are discarded immediately after the compatibility delta is computed — no behavioral survey responses are persisted long-term
- Full GDPR Article 9 compliance for European markets
- Russia data residency compliance (242-FZ): Russian user data stored on Yandex Cloud or VK Cloud

### 5.3 Spark Session Technical Flow

```
User A taps Spark
    → Backend creates SparkSession record (UUID token, TTL 10 min, status: pending)
    → App displays QR + 6-digit session_code

User B scans QR
    → Backend links both device tokens to SparkSession (status: active)
    → Both apps enter synchronized micro-test flow (WebSocket)

Micro-test completes
    → Both devices submit answers simultaneously
    → Backend computes instant compatibility delta from existing profiles
    → Answers discarded; compatibility_score written to SparkSession record
    → Reward engine checks user tier → SparkReward records created
    → Both apps display result screen with score + date proposal
    → TrustScore.irl_verification_count incremented for both users
    → SparkSession status → completed
    → If compatibility_score ≥ threshold → Match record created (origin: :spark, status: :proposed)
    → Both users receive match notification
```

### 5.4 Matching Engine Weights

| Dimension | Signal Source | MVP Weight |
|---|---|---|
| Sleep alignment | HealthKit / Health Connect | 22% |
| Peak activity overlap | HealthKit / Health Connect | 18% |
| Routine stability match | HealthKit / Health Connect | 13% |
| Activity level similarity | HealthKit / Health Connect | 12% |
| Personal space respect | HealthKit (weekend variance) | 10% |
| Recovery pattern match | HealthKit (HRV / RHR) | 8% |
| Travel style compatibility | Polarsteps / game / Maps | 10% |
| Music profile compatibility | Spotify API | 7% |

---

## 6. Go-To-Market

### 6.1 The Community-First Principle

Synca does not launch to a city. It launches to a community within a city. The minimum viable density is approximately 300–500 active users per city.

The playbook for every city:

1. Identify 2–3 anchor communities: run clubs, boutique gyms, saunas, coworking spaces, expat networks
2. Recruit local ambassadors: 1–3 community organizers
3. Host seeding events: invite-only gatherings where entry requires completing Synca onboarding
4. Physical manifests: posters and cards in gyms, saunas, and fitness spaces linking to the Telegram Bot via QR code
5. **Synca Spark activation at every event**: organizers demo the feature live on stage or at check-in, generating 20–50 Spark sessions per event and onboarding user pairs simultaneously
6. Activate matching once density threshold is reached
7. Launch B2B partnerships within 8 weeks of city activation

### 6.2 Seven-City Roadmap

**Wave 1 — Months 1–6:** Moscow (primary), Bangkok, Dubai
**Wave 2 — Months 6–18:** Seoul, Milan
**Wave 3 — Months 18–30:** São Paulo, Mexico City

---

## 7. Business Model

### 7.1 Revenue Streams

**Premium Subscription**
Market-adjusted pricing (€7.99 Moscow, $8.99 Bangkok, €14.99 Milan, €16.99 Berlin/Dubai). All subscription payments processed outside App Store and Google Play — eliminating the standard 30% platform commission.

Premium unlocks:
- Algorithm-originated match suggestions ("Synca Suggests") — curated matches proposed proactively by the nightly matching engine, without requiring an in-person Spark
- Unlimited active Sync Rooms (free tier: 1 active Duo room)
- Event Room creation (groups of 9–22, e.g. football, padel tournaments)
- Spark invite relay — share a Spark invite link with a third party to facilitate their in-person meeting
- Detailed compatibility analytics per match

**Pay-per-Match / Date Pack**
Users purchase a single curated match or a ready-made date experience.

**Synca Spark Reward Loop**
Each Spark session awards both participants one free Premium week (free users) or one free match credit (Premium users). The 7-day trial re-engagement conversion (est. 20–35%) makes this self-funding. Cost per Spark reward: ~€3.50. Expected LTV uplift per converted re-activation: ~€54 (3 months average retention at €18 ARPU).

**B2B Venue Partnerships**
Gyms, saunas, padel courts, and cafés become active partners. Revenue share: 15–20% of each booked date experience. Spark sessions at partner venues carry a co-branded experience, reinforcing venue loyalty programs.

**Group Date Packs (v2+)**
Curated small-group activity experiences (morning runs, sauna sessions, padel) sold as premium packs, co-branded with venue partners. This monetization surface becomes available once the Sync Room group layer is released and requires no additional data infrastructure beyond what is built in MVP and v1.

### 7.2 Feature Access by Tier

| Feature | Free | Premium |
|---|---|---|
| Spark sessions | ✅ unlimited | ✅ unlimited |
| Match from Spark (IRL origin) | ✅ | ✅ |
| Match from Algorithm (curated) | ❌ | ✅ |
| Sync Room Duo (1:1 chat) | ✅ 1 active | ✅ unlimited |
| Sync Room Small Group (3–8) | ❌ | ✅ unlimited |
| Event Room (9–22, e.g. football) | ❌ | ✅ |
| Spark invite relay | ❌ | ✅ |
| Detailed compatibility analytics | ❌ | ✅ |
| Profile boost | ❌ | ✅ (via Spark reward) |

### 7.3 Unit Economics (Indicative)

| Metric | Estimate | Basis |
|---|---|---|
| Target blended ARPU (net) | €12.60/month | €18 gross × 70% after store fees |
| Spark reward cost | ~€3.50 per session | 7-day trial at blended daily ARPU |
| Spark → paid conversion (re-engagement) | 20–35% | RevenueCat 2025 re-engagement trial data |
| Spark net LTV contribution | ~€7–15 per session | After reward cost, net of churn |
| B2B venue fee per booking | 15–20% | Standard affiliate/referral model |
| Platform commission saved | 30% | Via Telegram/web payment routing |

---

## 8. Competitive Positioning

| | Tinder/Bumble | Hinge | Keeper/Known/Sitch | **Synca** |
|---|---|---|---|---|
| Matching signal | Self-reported | Self-reported + behavior | AI on profiles | **Passive multi-signal (health + music + travel)** |
| Volume | Infinite swipe | Curated browse | Curated | **1 match at a time** |
| Post-match | Up to users | Some prompts | Some guidance | **Pre-organized date proposal** |
| Fake filter | Weak | Moderate | Moderate | **Multi-layer Trust Score + ghosting** |
| Live IRL feature | None | None | None | **Synca Spark — synchronized live game + reward** |
| Group / social layer | None | None | None | **Sync Rooms — IRL-verified group spaces (v2+)** |
| Distribution Russia | Blocked | Blocked | Not present | **Telegram Mini App + RuStore** |
| Health data | None | None | None | **Core signal** |
| Music data | None | None | None | **Spotify integration (v1)** |
| Travel data | None | None | None | **Travel behavior integration (v1)** |

---

## 9. Why This Team, Why Now

**Why now**: Three infrastructure conditions converge today. Apple HealthKit has reached 89 million active users. Android Health Connect is replacing Google Fit as the platform-level health data standard in 2026. Spotify's developer API gives programmatic access to music behavioral data for 675 million users. IRL social events and fitness communities are resurging post-pandemic, creating the perfect distribution channel for Synca Spark.

*[Team section to be completed with founding team profiles, relevant experience, and advisors.]*

---

## 10. Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Cold start / low density | Dual-value dashboard; community seeding events; Synca Spark onboards two users per session |
| HealthKit onboarding friction | Standalone health dashboard as immediate value; granular consent |
| Privacy concerns (health data) | On-device aggregation; only derived metrics transmitted; Spark answers discarded post-computation; GDPR-compliant architecture |
| Russia distribution friction | Telegram Mini App as primary product; RuStore for Android; Russian cloud data residency |
| Spark abuse (fake IRL claims) | Session requires simultaneous active devices in same location; WebSocket sync; GPS proximity check |
| Algorithm validation | Rapid feedback loop with first users; explicit outcome tracking; iterative weight calibration |

---

## 11. Signal Expansion and Product Roadmap

### 11.1 Signal Expansion

| Phase | New Signals |
|---|---|
| MVP | Sleep, activity, routine stability, visual preference game, photo context AI |
| Post-MVP v1 | Spotify music profile, travel behavior (Polarsteps / Maps), deep audio features |
| Post-MVP v2 | Cross-signal health–music validation, predictive compatibility modeling, geolocation upgrade |

### 11.2 Sync Rooms — Group Compatibility Layer (v2+)

Beyond one-to-one matching, the compatibility engine has a natural extension into **group social contexts** through Sync Rooms — conversational spaces that exist only when a verified IRL compatibility graph exists between all members.

**Sync Room taxonomy:**

| Type | Members | Spark rule | Use case |
|---|---|---|---|
| **Duo** | 2 | 1 verified Spark between the two members | 1:1 match chat (default post-match) |
| **Small Group** | 3–8 | Every pair must have at least 1 verified Spark | Friend groups, recurring activity circles |
| **Event Room** | 9–22 | Every member must have at least 1 verified Spark with the room creator | Football, padel tournaments, group outings |

The Event Room relaxes the full-graph requirement intentionally: it is not realistic that all 10 players in a football game have met each other pairwise. The room creator acts as a social guarantor — each member has verified compatibility with them, establishing a trusted hub.

The Sync Room layer is not part of the MVP or v1 roadmap. It is identified as a medium-term product direction (v2+) for the following reasons:

- The data infrastructure required — individual compatibility profiles and IRL-verified `SparkSession` records — is fully built during MVP and v1 phases; the Sync Room extension is additive, not a re-architecture
- Community events are already the primary acquisition channel; Sync Rooms formalize this into a product feature rather than a pure marketing activity
- It creates a new monetization surface: Event Rooms and unlimited Small Groups are Premium-only features
- It differentiates Synca from all one-to-one focused competitors and opens adjacency to the social wellness category
- Spark session data (IRL interaction counts, location-proximate pairings, compatibility deltas across multiple users) provides the training signal needed to validate group cohesion scoring before full rollout

The Sync Room feature will be scoped and validated with community feedback during Wave 2 city launches (Seoul, Milan), where dense, event-oriented user bases make small-group testing most viable.

---

## 12. The Ask

*[To be completed: funding amount, use of funds breakdown, pre-money valuation, equity offered, and investor terms.]*
