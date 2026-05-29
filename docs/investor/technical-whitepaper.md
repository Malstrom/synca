# Synca Technical Whitepaper

**Version 1.3 — May 2026**
*Confidential — For Engineering, Security, and Technical Due Diligence Use Only*

---

## 1. Introduction

Synca is a lifestyle-based matchmaking platform that uses passively collected behavioral signals — primarily health, music, travel, and visual preference data, enriched by a short declared preferences questionnaire — to estimate compatibility between people and propose pre-organized real-world meetings.

This whitepaper describes the technical architecture, data model, matching algorithms, privacy and security design, and integration points with external systems (Apple HealthKit, Android Health Connect, Spotify, Yandex Music, travel services, and Telegram). It is intended for technical stakeholders: investor CTOs, security reviewers, and potential integration partners.

Synca enters the market as a dating app. The compatibility engine, however, is not limited to romantic matching: the same data model and scoring infrastructure supports group compatibility for small-group social and sports activities (calcetto, padel, trail running, sauna sessions) via the Circles feature. The architecture is designed with this extension in mind from day one.

---

## 2. System Architecture

### 2.1 High-Level Components

1. **iOS Client** — SwiftUI app using HealthKit for health data, Spotify SDK for music, and local on-device aggregation of all raw signals.
2. **Android Client** — Kotlin app using Health Connect for health data, Spotify or Yandex Music SDK for music, and on-device aggregation.
3. **Rails API Backend** — central service implementing all business logic: user management, signal ingestion, compatibility scoring, matching engine, trust scoring, Moment proposal management, Spark session orchestration, Circle management, and payment integration.
4. **Compatibility Engine** — internal Rails service computing pairwise compatibility scores as a weighted sum across four domains: Sleep, Activity, Lifestyle, and Preferences.
5. **Trust & Safety Engine** — pipeline computing a dynamic Trust Score based on image authenticity, behavioral patterns, cross-signal consistency, and IRL verification count.
6. **Spark Session Manager** — real-time WebSocket orchestrator for live in-person compatibility sessions; manages session lifecycle, proximity verification, async scoring via background job, reward issuance, and automatic Match creation when score meets threshold.
7. **Telegram Bot / Mini App** — WebApp client integrated with Telegram Bot API for acquisition, notifications, and payment flows (primary surface for Russian market).

### 2.2 Architecture Diagram

```
┌──────────────────────┐     ┌────────────────────────┐
│   iOS App              │     │   Android App          │
│   SwiftUI + HealthKit  │     │   Kotlin + HealthConnect│
│   Spotify SDK          │     │   Spotify / Yandex Music│
│   Local aggregation    │     │   Local aggregation    │
│   Spark QR + BLE       │     │   Spark QR + BLE       │
└───────┬────────────┘     └──────────┬───────────┘
        │  Derived signals only      │
        └────────────┬────────────┘
                         ↓
        ┌───────────────────────────┐
        │       Rails API             │
        │       PostgreSQL            │
        │       Compatibility Engine  │
        │       Trust & Safety        │
        │       Spark Session Mgr     │
        │       Moment Engine         │
        │       Circle Manager        │
        └──────┬───────────────────┘
               │
   ┌─────────┼─────────────┬───────┘
   ↓               ↓           ↓
Telegram     iOS/Android    Web Payment
Bot/TMA      Push Notify    (Stripe /
                            YooMoney / SBP)
```

Design principles:
- Raw health and music samples are never transmitted — only derived aggregates
- All client surfaces talk to the same Rails API via JWT-authenticated JSON endpoints
- Trust & Safety logic evolves independently from client releases
- Spark Session Manager does not persist raw answers — only the computed compatibility score
- When a Spark produces a score at or above the match threshold, the Match record is created automatically with `origin: :spark`

---

## 3. Data Model

### 3.1 Users and Profiles

```sql
users
  id                  bigint PK
  auth_provider       string   -- 'apple' | 'google' | 'telegram' | 'email'
  email               string
  password_digest     string   -- has_secure_password
  created_at          datetime
  updated_at          datetime

profiles
  id                  bigint PK
  user_id             bigint FK -> users NOT NULL UNIQUE
  display_name        string
  birth_date          date
  gender              string
  interested_in       string
  city_id             bigint FK -> cities
  has_wearable        boolean  DEFAULT false
  created_at          datetime
  updated_at          datetime

identity_providers
  id           bigint PK
  user_id      bigint FK -> users NOT NULL
  provider     string NOT NULL  -- 'apple' | 'google' | 'telegram' | 'spotify' | 'yandex_music'
  uid          string NOT NULL
  access_token string
  expires_at   datetime
  UNIQUE (provider, uid)
```

### 3.2 Declared Preferences

Collected during onboarding (under 2 minutes). These are multipliers applied to pairwise compatibility scoring — they do not filter candidates, they shape how signals are weighted for each specific user.

```sql
declared_preferences
  id                              bigint PK
  user_id                         bigint FK -> users NOT NULL UNIQUE
  sleep_together_importance       integer  -- 1-5 scale
  sleep_temperature_preference    string   -- 'cool' | 'warm' | 'no_preference'
  daily_movement_level            string   -- 'very_little' | 'moderate' | 'a_lot' | 'maximum'
  sport_kcal_range                string   -- 'under_300' | '300_to_600' | 'over_600'
  team_sport_frequency            string   -- 'never' | 'occasionally' | 'weekly' | 'multiple_weekly'
  rhythm_alignment_importance     integer  -- 1-5 scale
  self_reported_chronotype        string   -- 'morning' | 'night' | 'flexible'
  created_at                      datetime
  updated_at                      datetime
```

### 3.3 Signals

All raw data is aggregated on-device. Only derived metrics are transmitted and stored.
The `signals` table grows one column group per new source — one row per user at all times.

```sql
signals
  id                       bigint PK
  user_id                  bigint FK -> users NOT NULL UNIQUE

  -- Health (Phase 1)
  chronotype               string   -- 'early_bird' | 'night_owl' | 'intermediate'
  sleep_duration_avg       float    -- average nightly sleep hours (last 30 days)
  sleep_variability        float    -- standard deviation of nightly sleep duration
  social_jetlag            float    -- weekday vs weekend sleep timing delta (hours)
  activity_minutes_avg     float    -- average weekly active minutes
  step_count_avg           float    -- average daily step count
  rest_hr_avg              float    -- resting heart rate average (bpm)
  peak_activity_window     string   -- time-of-day window with highest activity density
  routine_stability_index  float    -- daily schedule consistency score (0.0–1.0)

  -- Music (Phase 2)
  music_top_genres         jsonb    -- e.g. ["hip-hop", "jazz", "electronic"]
  music_energy_avg         float    -- audio feature average (0.0–1.0)
  music_valence_avg        float    -- audio feature average (0.0–1.0)
  music_peak_listening_window string -- time-of-day window with highest listening
  music_source             string   -- 'spotify' | 'yandex_music'

  -- Travel (Phase 3)
  travel_trips_per_year    float
  travel_avg_duration_days float
  travel_style             string   -- 'city' | 'nature' | 'mixed'
  travel_regions           jsonb    -- e.g. ["Europe", "Southeast Asia"]

  computed_at              datetime -- when the on-device aggregation last ran
  updated_at               datetime -- when the backend last received a sync
```

### 3.4 Sparks

```sql
sparks
  id                   bigint PK
  initiator_id         bigint FK -> users NOT NULL
  receiver_id          bigint FK -> users          -- nullable for group sparks
  spark_type           string NOT NULL DEFAULT 'duo'  -- 'duo' | 'group'
  status               string NOT NULL DEFAULT 'pending'
                       -- 'pending' | 'completed' | 'expired' | 'cancelled'
  discovery_method     string NOT NULL  -- 'bluetooth' | 'qr_code'
  session_code         string           -- 6-digit numeric code for QR flow
  qr_token             string           -- UUID token for deep-link QR flow
  compatibility_score  float            -- nil until scoring completes
  score_breakdown      jsonb            -- domain sub-scores (never shown as raw numbers)
  match_created        boolean NOT NULL DEFAULT false
  expires_at           datetime NOT NULL
  completed_at         datetime
  created_at           datetime
  updated_at           datetime

spark_participants           -- used for group sparks (spark_type: 'group')
  id           bigint PK
  spark_id     bigint FK -> sparks NOT NULL
  user_id      bigint FK -> users NOT NULL
  confirmed_at datetime
  created_at   datetime
  UNIQUE (spark_id, user_id)

spark_rewards
  id           bigint PK
  user_id      bigint FK -> users NOT NULL
  spark_id     bigint FK -> sparks NOT NULL
  reward_type  string NOT NULL  -- 'premium_week' | 'match_credit'
  status       string NOT NULL DEFAULT 'pending'  -- 'pending' | 'redeemed' | 'expired'
  valid_until  datetime
  created_at   datetime
```

> Scoring is fully passive — no questionnaire or manual input during the Spark session itself. The compatibility score is computed from existing `signals` records. The raw score is never exposed to users; the result screen shows only plain-language explanations (e.g. "Your sleep schedules are well aligned").

### 3.5 Matches

```sql
matches
  id                     bigint PK
  user_a_id              bigint FK -> users NOT NULL
  user_b_id              bigint FK -> users NOT NULL
  spark_id               bigint FK -> sparks       -- nil for algorithm-origin
  origin                 integer NOT NULL DEFAULT 0  -- 0: spark | 1: algorithm
  algorithm_confidence   float                       -- nil for spark-origin
  compatibility_score    float NOT NULL
  score_breakdown        jsonb  -- domain sub-scores; never exposed raw to users
  status                 string NOT NULL DEFAULT 'active'
                         -- 'active' | 'drifted' | 'reconnected' | 'ended'
  created_at             datetime
  updated_at             datetime
  UNIQUE (user_a_id, user_b_id)
```

`drifted` indicates a match where engagement has dropped below activity thresholds; `reconnected` indicates a match re-activated after drifting. These states feed into the Trust Score and outcome analytics.

### 3.6 Moments

A Moment is the real-world meeting lifecycle: proposal, counter-proposal, confirmation, completion, and post-meeting rating.

```sql
moments
  id               bigint PK
  proposer_id      bigint FK -> profiles NOT NULL
  receiver_id      bigint FK -> profiles NOT NULL
  match_id         bigint FK -> matches NOT NULL
  parent_id        bigint FK -> moments           -- set on counter-proposals
  location         string NOT NULL
  scheduled_at     datetime NOT NULL
  status           string NOT NULL DEFAULT 'pending'
                   -- 'pending' | 'confirmed' | 'declined' | 'superseded'
                   -- 'completed' | 'no_show'
  proposer_rating  integer          -- 1-5, set on completion
  receiver_rating  integer          -- 1-5, set on completion
  completed_at     datetime
  created_at       datetime
  updated_at       datetime
```

No-show events reduce the offending profile's Trust Score by −15 points. Positive ratings feed into behavioral Trust Score signals. Counter-proposal chains are capped at 5 rounds server-side.

### 3.7 Circles

Circles are conversational and coordination spaces that exist only when a verified physical compatibility graph exists between all members. The term "Sync Rooms" is deprecated and does not appear in the codebase.

```sql
circles
  id           bigint PK
  circle_type  string NOT NULL   -- 'duo' | 'small_group' | 'event'
  created_by   bigint FK -> profiles NOT NULL
  name         string            -- required for small_group and event; null for duo
  scheduled_at datetime          -- optional, relevant for event type
  created_at   datetime
  updated_at   datetime

circle_memberships
  id         bigint PK
  circle_id  bigint FK -> circles NOT NULL
  profile_id bigint FK -> profiles NOT NULL
  spark_id   bigint FK -> sparks  -- proof of physical encounter; null for duo on algorithm matches
  joined_at  datetime
  UNIQUE (circle_id, profile_id)

circle_messages
  id         bigint PK
  circle_id  bigint FK -> circles NOT NULL
  sender_id  bigint FK -> profiles NOT NULL
  body       text NOT NULL
  read_at    datetime
  created_at datetime
```

**Admission rules:**
- `duo`: created automatically on match confirmation. 1 confirmed Spark required (nil for algorithm-origin matches on creation, expected to be completed).
- `small_group` (3–8): every pair of members must have ≥1 confirmed Spark.
- `event` (9–22): every member must have ≥1 confirmed Spark with the circle creator. The creator acts as social guarantor.

### 3.8 Trust Score

```sql
trust_scores
  id                       bigint PK
  user_id                  bigint FK -> users NOT NULL UNIQUE
  score                    float      -- 0.0 to 1.0
  image_liveness_score     float
  image_forensics_score    float
  behavioral_score         float
  health_consistency_score float
  music_consistency_score  float
  irl_verification_count   integer    -- incremented by each completed Spark
  moment_noshow_count      integer    -- incremented by confirmed no-shows
  updated_at               datetime
```

---

## 4. Client Applications

### 4.1 iOS App (SwiftUI)

**HealthKit Integration:**
- Permissions: `HKCategoryTypeIdentifierSleepAnalysis`, `HKQuantityTypeIdentifierStepCount`, `HKQuantityTypeIdentifierActiveEnergyBurned`, optionally `HKQuantityTypeIdentifierHeartRate`, `HKQuantityTypeIdentifierHeartRateVariabilitySDNN`
- Aggregation runs in background using `HKObserverQuery` and `HKAnchoredObjectQuery`
- Local aggregator computes rolling 14–30-day metrics; uploads a new `signals` record when significant change occurs or at minimum once per day

**On-Device Aggregation:**
- Chronotype: clustering sleep midpoint over the last 30 nights
- Sleep variability: standard deviation of nightly sleep duration
- Peak activity window: derived from step count histogram across hours of day
- Routine stability index: `1 - normalized_std(sleep_start)` across 30 days

**Spark Engine:**
- Generates QR code from session token returned by backend
- Broadcasts BLE signal for proximity detection (Step 1.0: QR primary; BLE optional)
- Establishes WebSocket connection to Spark Session Manager on session join
- Polls `GET /api/v1/sparks/:id/result` or listens for `spark:scored` Action Cable event

### 4.2 Android App (Kotlin + Health Connect)

Health Connect provides a unified interface for health data across Android OEMs, standardizing API access from 2026 onward.

- `HealthConnectClient` reads `SleepSessionRecord`, `StepsRecord`, `HeartRateRecord`
- Periodic background jobs via WorkManager recompute aggregates
- Supports third-party devices (Garmin, Xiaomi, Samsung Health) that sync into Health Connect
- Full Spark QR + BLE functionality mirroring iOS

### 4.3 Telegram Bot and Mini App

**Bot functions:** registration, lightweight onboarding, deep-linking to app stores or direct APK/RuStore download, match notifications, Moment proposals, and payment flows via Telegram Stars, YooMoney, or external payment URLs.

**Mini App (WebApp):** richer embedded UI communicating with Rails API using JWT tokens derived from Telegram authorization. Primary product surface for Russian market.

---

## 5. Compatibility Engine

### 5.1 Design Principles

1. **Multi-signal fusion** — combine independent behavioral domains: health, music, travel, declared preferences
2. **Explainability** — compatibility scores decomposed into plain-language dimensions, never exposed as raw numbers to users
3. **Calibratability** — domain weights adjustable globally and per user as outcome data accumulates
4. **Dual origin** — matches from live Spark sessions (`origin: :spark`) and nightly `MatchingJob` algorithm runs (`origin: :algorithm`) produce the same `Match` record structure with distinct metadata
5. **Group-ready** — the pairwise scoring model extends naturally to multi-user group cohesion scoring (Circles)

### 5.2 Four Compatibility Domains

| Domain | Weight (MVP) | Signals used |
|--------|-------------|---|
| Sleep | 35% | `chronotype`, `sleep_duration_avg`, `sleep_variability`, `social_jetlag` |
| Activity | 30% | `activity_minutes_avg`, `step_count_avg`, `peak_activity_window`, `rest_hr_avg` |
| Lifestyle | 20% | `routine_stability_index`; music and travel sub-signals added in phases 2–3 |
| Preferences | 15% | Age range, distance, stated dealbreakers, `declared_preferences` multipliers |

Weights are indicative for MVP and recalibrated per city as outcome data (Moment completion, ratings) accumulates.

### 5.3 Declared Preferences as Multipliers

The `declared_preferences` record modifies effective domain weights for each user pair. Example: if both users mark `sleep_together_importance = 5`, the Sleep domain weight is amplified for that pair. If both mark it `1`, the weight is reduced in favor of Activity and Lifestyle.

This ensures the engine produces matches that are not just objectively compatible, but compatible along the dimensions each user actually values.

### 5.4 Compatibility Score Formula

For any pair of users (A, B), the final compatibility score is:

$$C(A,B) = \sum_{d} w_d^{eff}(A,B) \cdot s_d(A,B)$$

where:
- $w_d^{eff}$ is the effective weight for domain $d$, derived from global weights modified by both users' declared preferences
- $s_d(A,B)$ is the normalized similarity score (0–1) for domain $d$

For Spark-origin scoring, the same formula is applied synchronously at session completion using both users' existing `signals` records.

### 5.5 Score Thresholds

| Threshold | Spark origin | Algorithm origin |
|-----------|-------------|------------------|
| Minimum score to create a Match | 50 / 100 | 65 / 100 |

Algorithm origin has a higher bar because no physical presence confirms mutual intent. Thresholds are configurable per city.

### 5.6 Lifestyle Domain Composition by Phase

| Phase | Sub-signal | Weight within Lifestyle |
|-------|------------|------------------------|
| 1 (health only) | `routine_stability_index` | 100% |
| 2 (+ music) | `routine_stability_index` | 40%; Music taste 60% |
| 3 (+ travel) | `routine_stability_index` | 20%; Music taste 40%; Travel 40% |

### 5.7 Match Origins

| Origin | Trigger | UX label |
|--------|---------|----------|
| `:spark` | Two users complete a Spark in person | "Synca Confermata" ✅ |
| `:algorithm` | Nightly `MatchingJob` on signals | "Synca Suggerita" 💡 |

Algorithm-originated matches also carry `algorithm_confidence` (0.0–1.0), normalizing the pairwise score relative to the candidate pool for that user.

---

## 6. Spark Session Technical Flow

```
User A taps Spark
  → Backend creates sparks record (session_code, qr_token, expires_at: +10min, status: pending)
  → App displays QR + 6-digit session_code

User B scans QR or enters code
  → PATCH /api/v1/sparks/:id/join
  → Both devices linked via Action Cable (spark:joined event)
  → Spark status: active

Both users confirm physical presence
  → POST /api/v1/sparks/:id/submit_answers (no questionnaire — presence confirmation only)
  → ScoringJob enqueued (spark queue, Solid Queue)

ScoringJob runs
  → Reads signals for both users
  → Computes CompatibilityScoreService.call(user_a, user_b)
  → Writes compatibility_score + score_breakdown to sparks record
  → spark:scored Action Cable event dispatched to both clients
  → TrustScore.irl_verification_count incremented for both users
  → SparkReward records created per user tier
  → Spark status: completed

If compatibility_score >= spark threshold:
  → Match.create!(origin: :spark, spark_id: spark.id, ...)
  → Circle.create!(circle_type: :duo, ...) for match chat
  → Both users notified of confirmed match
```

---

## 7. Trust & Safety

### 7.1 Multi-Layer Trust Score

Five independent layers contribute to the composite Trust Score:

1. **Image liveness and authenticity** — liveness detection models prevent static-photo spoofing at upload
2. **Image forensics and metadata** — AI-generated image detection, EXIF analysis, compression pattern analysis, reverse image lookup across platforms
3. **Behavioral patterns** — repetitive messages, external link sharing, patterns associated with transactional or escort accounts
4. **Cross-signal consistency** — music listening patterns vs. claimed chronotype; health data variance analysis (impossibly uniform data signals fabrication); photo context vs. lifestyle claims
5. **IRL verification and Moment history** — completed Sparks at the same physical location are the strongest liveness signal; each increments `irl_verification_count`. Confirmed no-shows decrement Trust Score by −15 points.

### 7.2 Enforcement Model

- **High score** → full visibility in matching pool
- **Medium score** → slightly reduced visibility
- **Low score** → significantly reduced visibility; user prompted to complete additional verification

This selective ghosting approach minimizes confrontational moderation while pushing the ecosystem toward authenticity. Profiles are not banned and not notified of their score.

---

## 8. Privacy and Security

### 8.1 Data Minimization

- Raw health samples, per-second sensor readings, and precise travel trajectories are never transmitted or stored
- Only derived aggregate metrics are sent: chronotype, sleep variability, activity averages, music profile vectors
- Music data reduced to aggregated audio features, not listening history
- Spark session produces a compatibility score from existing signals; no new raw data is collected or persisted during the session

### 8.2 Consent and Control

- Fine-grained consent: users independently choose which domains to share (health, music, travel) and can revoke at any time
- On-demand deletion: single action triggers full backend data erasure (GDPR “right to be forgotten”)
- `declared_preferences` are updatable at any time from the profile screen

### 8.3 GDPR and Special Category Data

Health data is treated as special category personal data under GDPR Article 9:
- Processing limited to derived statistics; no medical inference
- Explicit, informed opt-in consent as lawful basis
- Data Protection Officer (DPO) appointed prior to European launch

### 8.4 Data Residency

- EU user data stored in EU-based infrastructure
- Russian user data stored in Russian-located infrastructure (Yandex Cloud or VK Cloud) per 242-FZ
- Segregated logical partitions prevent cross-jurisdiction data movement

### 8.5 Transport and Storage Security

- All API communication over TLS 1.2+
- JWT tokens for API authentication; OAuth2 / OpenID Connect for external integrations
- AES-256 encryption at rest for health, music, and signals tables
- Role-based access control; no internal tooling accesses raw user signals without audit log

---

## 9. External Integrations

### 9.1 Apple HealthKit

- Native iOS only; data not sent to any third party besides Synca's own backend
- Respects Apple guidelines prohibiting use of health data for advertising
- Background delivery via `HKObserverQuery`; silent daily sync

### 9.2 Android Health Connect

- Standardized schema for sleep, activity, and biometrics across Android OEMs
- Supports Garmin, Xiaomi, Samsung Health via Health Connect bridge
- Replaces Google Fit as platform standard from 2026

### 9.3 Spotify API

- OAuth2 with `user-top-read` and `user-read-recently-played` scopes
- Top tracks and audio features fetched and aggregated on-device
- Only pre-computed aggregates stored in `signals` (music columns)

### 9.4 Yandex Music

- Russian-market alternative to Spotify
- OAuth integration for listening history and genre data
- Energy/valence computation via internal genre taxonomy (no public audio features API equivalent to Spotify)

### 9.5 Travel Services

- Phase 1: onboarding travel preference questionnaire (declared)
- Phase 2: optional Polarsteps import (GPX/JSON), Google Maps Timeline (opt-in where API permits)
- All travel computation on-device; only aggregated `travel_*` columns transmitted

### 9.6 Telegram

- Standard Bot API for message handling
- Mini App (WebApp) framework for embedded web-based UI
- Payments via Telegram Payments API and/or external payment links
- Core data flows through Rails API; Telegram is a client and payment facilitator, not a data processor

---

## 10. Scaling and Reliability

### 10.1 Architecture Choices

- **Stateless backend**: horizontal scaling behind a load balancer; session state via JWT
- **PostgreSQL**: primary data store with read replicas for analytical workloads; city/region partitioning as user base grows
- **Solid Queue**: background jobs for ScoringJob (spark queue), nightly MatchingJob (algorithm queue), Trust Score recomputation, Moment reminders. No Redis or external queue broker required.
- **Action Cable**: WebSocket layer for real-time Spark session synchronization and Circle messaging; horizontally scalable via Solid Cable adapter

### 10.2 Resilience

- Graceful degradation: if music or travel signals unavailable, engine falls back to health + preferences domains with proportionally adjusted weights
- Circuit breakers for external integrations (Spotify, Yandex Music, Yandex AI) to prevent cascading failures
- Spark sessions self-expire after TTL; no orphaned records accumulate
- MatchingJob operates on a separate queue to avoid blocking Spark scoring during nightly runs

---

## 11. Roadmap

### 11.1 Phase 1 — MVP (0–6 Months)

- iOS app: HealthKit, declared preferences, visual preference game, Spark (QR primary), algorithm matching (Premium), Moments, Circles Duo
- Telegram Bot + Mini App for Russian market
- Nightly MatchingJob (Solid Queue) for algorithm-origin matches
- Basic Trust Score pipeline (image liveness + forensics)
- Yandex AI for photo context analysis (Russian market)

### 11.2 Phase 2 — Signal Expansion (6–18 Months)

- Android app with Health Connect + full Spark support
- Spotify + Yandex Music signal integration (music columns in `signals`)
- Travel behavior: onboarding questionnaire + optional Polarsteps import
- Group Spark (BLE multi-participant, `spark_participants` table)
- Circle Small Group (3–8) with full-graph Spark admission
- Learning-to-rank layer over hand-crafted compatibility scores using Moment outcome feedback

### 11.3 Phase 3 — Group Scale (18–30 Months)

- Circle Event (9–22): hub-and-spoke admission, Group Activity Packs
- B2B venue co-branding for group experiences (calcetto, padel, sauna, trail running)
- Cross-signal predictive modeling
- Third-party API for gyms and wellness platforms to integrate Synca compatibility signals
- Publish anonymized aggregate findings on lifestyle compatibility and social group cohesion

---

## 12. Conclusion

Synca's technical architecture is built around a single organizing principle: **compatibility is best inferred from how people actually live, not from how they describe themselves**.

The combination of HealthKit/Health Connect passive data, declared preferences as interpretation multipliers, music listening behavior, travel patterns, and live IRL Spark sessions creates a rich, multi-dimensional profile for each user — while respecting strict privacy constraints through on-device processing and data minimization.

The architecture enables Synca to:
- Launch in complex regulatory and distribution environments (Russia via Telegram Mini Apps, EU via GDPR-compliant infrastructure)
- Maintain a strong privacy posture as a structural property, not a compliance checkbox
- Scale to multiple cities and countries without re-architecting the core
- Produce matches from two distinct origins (Spark and algorithm), each traceable in the data model
- Extend naturally from one-to-one romantic matching into group activity coordination via Circles — using the same data model, scoring engine, and Spark verification mechanism built from day one

Synca's differentiation is embedded in the data model, the compatibility engine, and the privacy-first architecture. It is not a feature that can be bolted on — it is the foundation.
