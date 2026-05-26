# Synca Technical Whitepaper

**Version 1.1 — May 2026**  
*Confidential — For Engineering, Security, and Technical Due Diligence Use Only*

***

## 1. Introduction

Synca is a lifestyle-based matchmaking platform that uses passively collected behavioral signals — primarily health, music, travel, and visual preference data — to estimate compatibility between people and propose pre-organized real-world dates.

This whitepaper describes the technical architecture, data model, matching algorithms, privacy and security design, and integration points with external systems (Apple HealthKit, Android Health Connect, Spotify, travel services, and Telegram). It is intended for technical stakeholders: investor CTOs, security reviewers, and potential integration partners.

***

## 2. System Architecture Overview

### 2.1 High-Level Components

1. **iOS Client** — SwiftUI app using HealthKit for health data, MusicKit for Apple Music (future), and local processing of raw samples.
2. **Android Client** — Kotlin app using Health Connect for health data, Spotify SDK for music, and on-device aggregation.
3. **Rails API Backend** — central service implementing all business logic: user management, signal ingestion, matching engine, trust scoring, date proposal generation, Spark session orchestration, and payment integration.
4. **Compatibility Engine** — stateless service or internal Rails module computing compatibility scores as a weighted combination of normalized features.
5. **Trust & Safety Engine** — pipelines computing a dynamic Trust Score based on image, behavior, and cross-signal consistency.
6. **Spark Session Manager** — real-time WebSocket orchestrator for live in-person compatibility sessions; manages session lifecycle, answer synchronization, instant score computation, and reward issuance.
7. **Telegram Bot / Mini App** — WebApp client integrated with Telegram Bot API, used for acquisition, notifications, and payment flows.

### 2.2 Logical Architecture Diagram

```
┌──────────────────────┐     ┌──────────────────────────┐
│      iOS App         │     │      Android App         │
│  (SwiftUI + HealthKit│     │   (Kotlin + HealthConnect│
│   + MusicKit)        │     │    + Spotify SDK)        │
└─────────┬────────────┘     └───────────┬──────────────┘
          │  Derived health & music data │
          ▼                              ▼
           ┌────────────────────────────┐
           │        Rails API            │
           │  (Ruby on Rails, JSON API)  │
           └───────────┬────────────────┘
                       │
       ┌─────────────┼──────────────────┐
       ▼               ▼                  ▼
┌─────────────┐  ┌─────────────┐  ┌───────────────┐
│ Matching +   │  │ Trust &     │  │ Spark Session  │
│ Compatibility│  │ Safety Eng. │  │ Manager (WS)   │
└─────┤──────┘  └─────┤─────┘  └──────┤────────┘
      │                  │               │
      ▼                  ▼               ▼
┌─────────────┐  ┌────────────┐  ┌──────────────┐
│ PostgreSQL  │  │ Object Store│  │ Payment Gateway│
│ (Core DB)   │  │ (images/logs)│  │ Stripe/YooMoney│
└─────────────┘  └────────────┘  └──────────────┘
```

Design principles:
- Raw health and music samples are never transmitted — only derived aggregates
- All client surfaces talk to the same Rails API
- Trust & Safety logic can evolve independently from client releases
- Spark Session Manager is a lightweight real-time layer; it does not persist raw answers, only the computed compatibility delta

***

## 3. Data Model and Schemas

### 3.1 Core Entities

**User**
- `id`: UUID
- `auth_identity_type`: enum (`apple`, `google`, `telegram`, `email`)
- `city_id`: foreign key to City
- `birth_date`, `gender`, `interested_in`, `has_wearable`

**HealthSummary** (per-user, per-period)
- `chronotype`: enum (`morning`, `intermediate`, `evening`)
- `avg_sleep_start_local`, `avg_sleep_end_local`: time
- `sleep_stability_index`: float (0–1)
- `activity_level`: enum (`low`, `medium`, `high`)
- `peak_activity_window_start`, `peak_activity_window_end`: time
- `personal_space_index`: float (0–1)
- `recovery_index`: float (0–1)
- `source`: enum (`healthkit`, `health_connect`, `manual`)

**MusicProfile**
- `provider`: enum (`spotify`, `apple_music`, `lastfm`)
- `energy_score`: float (0–1)
- `valence_score`: float (0–1)
- `genre_diversity_index`: float (0–1)
- `listening_variance_by_hour`: jsonb (24-bin distribution)

**TravelProfile**
- `trip_frequency_per_year`: float
- `avg_trip_distance_km`: float
- `novelty_preference_index`: float (0–1)
- `home_stability_index`: float (0–1)
- `source`: enum (`preference_game`, `maps`, `travel_api`)

**PreferenceEmbedding**
- `vector`: float[] (128-dim embedding)
- `version`: integer (model version)

**TrustScore**
- `score`: float (0–1)
- `image_liveness_score`: float
- `image_forensics_score`: float
- `behavioral_score`: float
- `health_consistency_score`: float
- `music_consistency_score`: float
- `irl_verification_count`: integer (incremented by completed Spark sessions)

**Match**
- `user_a_id`, `user_b_id`: fk
- `compatibility_score`: float (0–1)
- `dimensions_breakdown`: jsonb (`{"sleep":0.82, "activity":0.76, ...}`)
- `status`: enum (`proposed`, `accepted`, `declined`, `expired`)

**SparkSession**
- `initiator_id`, `partner_id`: fk to User
- `session_code`: string (6-digit, TTL 10 min)
- `qr_token`: string (UUID)
- `status`: enum (`pending`, `active`, `completed`, `expired`)
- `location_lat`, `location_lng`: float (approximate, for proximity check)
- `initiator_answers`, `partner_answers`: jsonb (micro-test responses; discarded after score computation)
- `compatibility_score`: float (instant delta computed at session end)
- `reward_issued_initiator`, `reward_issued_partner`: boolean
- `started_at`, `completed_at`: timestamp

> Raw micro-test answers are retained only for the duration of the session and discarded immediately after the compatibility delta is computed. No behavioral survey data is persisted long-term.

**SparkReward**
- `user_id`: fk
- `spark_session_id`: fk
- `reward_type`: enum (`premium_trial_7d`, `match_credit`, `profile_boost_24h`)
- `status`: enum (`pending`, `issued`, `redeemed`, `expired`)
- `valid_until`: timestamp

**DateProposal**
- `match_id`: fk
- `venue_id`: fk (nullable)
- `suggested_time_window`: tsrange
- `activity_type`: enum (`walk`, `coffee`, `padel`, `sauna`, etc.)
- `status`: enum (`pending`, `confirmed`, `rejected`)

***

## 4. Client Applications

### 4.1 iOS App (SwiftUI)

**HealthKit Integration:**
- Permissions requested for: `HKCategoryTypeIdentifierSleepAnalysis`, `HKQuantityTypeIdentifierStepCount`, `HKQuantityTypeIdentifierActiveEnergyBurned`, optionally `HKQuantityTypeIdentifierHeartRate`, `HKQuantityTypeIdentifierHeartRateVariabilitySDNN`
- Aggregation jobs run in background using `HKObserverQuery` and `HKAnchoredObjectQuery`
- A local aggregator computes rolling 14–30-day metrics and uploads a new `HealthSummary` when significant change occurs or at minimum once per day

**On-Device Aggregation:**
- Chronotype computed by clustering sleep midpoint over the last 30 nights
- Sleep stability index: `1 - normalized_std(sleep_start)`
- Peak activity window derived from step count histogram across hours

**Spark QR Engine:**
- Generates a QR code from the session token returned by the backend
- Establishes WebSocket connection to Spark Session Manager on session join
- Submits micro-test answers and renders the result screen upon WebSocket event

### 4.2 Android App (Kotlin + Health Connect)

Health Connect provides a unified interface for health data across Android OEMs, replacing Google Fit and standardizing API access from 2026 onward.

- Use `HealthConnectClient` to read `SleepSessionRecord`, `StepsRecord`, `HeartRateRecord`
- Schedule periodic background jobs using WorkManager to recompute aggregates
- Support devices where tracking is via third-party apps (Garmin, Xiaomi) that sync into Health Connect
- Full Spark QR functionality mirroring iOS implementation

### 4.3 Telegram Bot and Mini App

**Bot functions:**
- Registration and basic profile creation
- Lightweight onboarding
- Deep-linking to app store or direct APK/RuStore download
- Match notifications and date proposals
- Payments via Telegram Stars, YooMoney, or external payment URLs

**Mini App (WebApp) functions:**
- Richer UI embedded as web frontend
- Communicates with Rails API using JWT tokens from Telegram authorization

***

## 5. Matching Engine

### 5.1 Design Principles

1. **Multi-signal fusion** — combine independent behavioral signals: health, music, travel, visual preference
2. **Explainability** — compatibility scores decomposed into human-readable dimensions
3. **Calibratability** — weights adjustable globally and per-user as data accrues

### 5.2 Feature Vectors

**Health features (H):**
- `H_chronotype`, `H_sleep_midpoint`, `H_sleep_stability`
- `H_peak_activity_start`, `H_peak_activity_end`
- `H_activity_level`, `H_personal_space_index`, `H_recovery_index`

**Music features (M):**
- `M_energy`, `M_valence`, `M_genre_diversity`
- `M_evening_listening_intensity` (correlates with chronotype)

**Travel features (T):**
- `T_trip_frequency`, `T_avg_trip_distance`
- `T_novelty_index`, `T_home_stability`

**Preference features (P):**
- `P_vector` (128-dim embedding; cosine similarity)

### 5.3 Compatibility Calculation

For any pair of users (A, B), the final compatibility score is:

$$C(A,B) = \sum_i w_i \cdot s_i(A,B)$$

where $w_i$ are configurable weights per dimension and $s_i$ are normalized similarity scores (0–1) for each dimension.

**Default MVP weight distribution:**

| Dimension | Weight |
|---|---|
| Sleep alignment | 22% |
| Peak activity overlap | 18% |
| Routine stability match | 13% |
| Activity level similarity | 12% |
| Personal space respect | 10% |
| Travel style compatibility | 10% |
| Recovery pattern match | 8% |
| Music profile compatibility | 7% |

### 5.4 Per-User Weight Customization

Users can indicate which dimensions matter more. The effective weights for a pair:

$$w_i^{eff}(A,B) = f(w_i^{global}, w_i^{userA}, w_i^{userB})$$

where $f$ can be a simple average or a function giving extra weight to dimensions both users prioritize.

### 5.5 Learning from Outcomes

As users interact, the engine collects outcome data (match acceptance, date confirmation, self-reported outcomes) to:
- Recalibrate global weights via gradient-free optimization
- Train learning-to-rank models on top of hand-crafted scores

In early stages, deterministic weighted sum is preferred for transparency.

***

## 6. Trust & Safety Infrastructure

### 6.1 Multi-Layer Trust Score

The Trust Score combines four independent layers:

1. **Image liveness and authenticity** — liveness detection models prevent static-photo spoofing
2. **Image forensics and metadata** — AI-generated image detection, EXIF analysis, compression pattern analysis
3. **Behavioral patterns** — repetitive messages, external link sharing, scam-associated patterns
4. **Cross-signal consistency** — listening patterns vs. claimed chronotype; health data variance analysis; photo context vs. lifestyle claims
5. **IRL verification** — completed Spark sessions between users at the same physical location provide the strongest available liveness signal; each session increments `irl_verification_count` on the `TrustScore` record

### 6.2 Enforcement

Trust Score influences visibility but does not result in hard bans by default:
- **High score** → full visibility in matching pool
- **Medium score** → slightly reduced visibility
- **Low score** → significantly reduced visibility; user prompted to complete additional verification steps

This "selective ghosting" approach minimizes confrontational moderation while pushing the ecosystem toward authenticity.

***

## 7. Privacy and Security by Design

### 7.1 Data Minimization

- Only derived, aggregate metrics from health, music, and travel data are transmitted
- No raw health samples, per-second sensor readings, or precise travel trajectories are stored
- Music data reduced to aggregated audio features, not detailed listening history
- Spark session micro-test answers discarded immediately after score computation; only the resulting compatibility delta is persisted

### 7.2 Consent and Control

- Fine-grained consent: users choose which domains to share (health, music, travel) and can revoke at any time
- On-demand deletion: single action triggers full backend data erasure (GDPR “right to be forgotten”)

### 7.3 GDPR and Special Category Data

Health data is treated as special category personal data under GDPR Article 9:
- Limit processing to derived statistics; no medical inference
- Explicit, informed opt-in consent as lawful basis
- Data Protection Officer (DPO) appointed prior to European launch

### 7.4 Data Residency

- EU user data stored in EU-based infrastructure
- Russian user data stored in Russian-located infrastructure (Yandex Cloud or VK Cloud) per 242-FZ
- Segregated logical partitions to avoid cross-jurisdiction data movement

### 7.5 Transport and Storage Security

- All API communication over TLS 1.2+
- OAuth2 / OpenID Connect for external integrations
- AES-256 encryption at rest for health and music profile tables
- Role-based access control

***

## 8. External Integrations

### 8.1 Apple HealthKit

- Used only from native iOS app
- Health data not sent to any third party besides Synca’s own backend
- Respects Apple’s guidelines prohibiting use of health data for advertising

### 8.2 Android Health Connect

- Standardized schema for sleep, activity, and biometrics
- Supports OEM fitness apps (Garmin, Xiaomi, Samsung Health) via Health Connect bridge

### 8.3 Spotify API

- OAuth2 with `user-top-read` and `user-read-recently-played` scopes
- Fetch and aggregate top tracks and audio features periodically
- Store only pre-computed aggregated features in `MusicProfile`

### 8.4 Travel Services

- Initial focus on onboarding travel preference game
- Optional: Polarsteps API, Google Maps Timeline (opt-in, where API access permits)

### 8.5 Telegram

- Standard Bot API for message handling
- Mini App (WebApp) framework for embedded web-based UI
- Payments via Telegram Payments API and/or external payment links
- Core data flows through Rails API; Telegram is a client and payment facilitator, not a data processor

***

## 9. Scaling and Reliability

### 9.1 Architecture Choices for Scale

- **Stateless backend**: horizontal scaling behind a load balancer; session state via JWT
- **PostgreSQL**: primary data store with read replicas for analytical workloads; city/region partitioning as user base grows
- **Async processing**: Sidekiq for background jobs — recomputing compatibility and trust scores, generating date proposals
- **WebSocket layer**: Action Cable (Rails) handles Spark session real-time synchronization; horizontally scalable via Redis pub/sub adapter

### 9.2 Resilience

- Graceful degradation: if travel or music signals unavailable, engine falls back to health + preference embedding
- Circuit breakers for external integrations (Spotify, Yandex AI) to prevent cascading failures
- Spark sessions self-expire after TTL; no orphaned sessions accumulate in the database

***

## 10. Roadmap

### 10.1 Short-Term (0–12 Months)

- Finalize iOS MVP with HealthKit integration, preference game, basic matching engine
- Implement Spark Session Manager with WebSocket sync, QR engine, and reward issuance
- Implement Telegram Bot and Mini App for Moscow launch
- Integrate Yandex AI for photo context analysis in the Russian market
- Roll out basic Spotify integration for music profile enrichment

### 10.2 Medium-Term (12–24 Months)

- Launch Android app with Health Connect integration and full Spark support
- Add travel preference game and optional travel service integrations
- Introduce basic learning-to-rank layer over hand-crafted compatibility scores
- Harden Trust Score with additional image forensics and behavioral heuristics
- **Group compatibility engine (v2 research phase)**: extend the pairwise compatibility model to compute a multi-user group cohesion score across 4–8 participants; validate algorithm design with anonymized data from seeding events

### 10.3 Long-Term (24+ Months)

- **Group compatibility — production (v2+)**: surface curated small-group activity proposals (morning runs, sauna sessions, padel games) based on multi-user lifestyle alignment; introduce group date packs as a new monetization surface co-branded with venue partners. The underlying data infrastructure (individual compatibility profiles, SparkSession IRL data, venue integrations) is fully in place from earlier phases — the group layer is an additive feature, not a re-architecture.
- Cross-signal predictive modeling
- Publish anonymized aggregate findings on lifestyle compatibility and relationship success
- API for third-party apps (gyms, wellness platforms) to integrate Synca compatibility signals

***

## 11. Conclusion

Synca’s technical design centers on a single idea: compatibility is best inferred from how people actually live, not how they describe themselves. The combination of HealthKit/Health Connect data, music listening behavior, travel patterns, visual preference embeddings, and live IRL sessions (Spark) creates a rich, multi-dimensional profile for each user — while respecting strict privacy constraints through on-device processing and data minimization.

The architecture enables Synca to:
- Launch in complex regulatory and distribution environments (Russia via Telegram Mini Apps)
- Maintain a strong privacy and security posture suitable for GDPR and other modern data protection regimes
- Scale to multiple cities and countries without re-architecting the core
- Extend naturally from one-to-one matching into group compatibility experiences, leveraging the same data model built from day one

Synca’s differentiation is not a marketing veneer; it is embedded in the data model, the matching engine, and the privacy-first architecture.

*For implementation details at code level (schemas, API contracts, client pseudocode), see the internal developer documentation repository.*
