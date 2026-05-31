# Phase 0 — Validation MVP
**Timeline:** Month 0–3
**Goal:** Prove the core hypothesis with real users before building full infrastructure.
**Success metric:** 50 active users, 20 completed Spark sessions, 5+ spontaneous
re-encounters tracked within 30 days of a Spark session.
**Platform:** iOS only. Android deferred to Phase 2.

---

## US-01 — First encounter without friction
As a user who just met someone in person,
I want to start a Spark session immediately without creating an account,
so that I can discover our compatibility without any barrier or commitment.

### UF-01 — First Spark (full journey, new user)
**Refs:** [profile-v1.md — Step 0](../../features/profile-v1.md#step-0--guest-onboarding-validation-mvp) · [signals-v1.md — Step 0](../../features/signals-v1.md#step-0--declared-preferences) · [spark-v1.md — Step 1.0](../../features/spark-v1.md#step-10--proximity-spark-qr)

```
User A (initiator, has app)          User B (receiver, no app)
        |                                      |
Opens "Start Spark"                            |
App displays QR code                           |
        |                           Scans QR with camera
        |                                      ↓
        |                           Redirected to App Store
        |                           Installs Synca
        |                           Deferred deep link restores qr_token
        |                                      ↓
        |                           Guest onboarding: enters email only
        |                           Answers declared preferences questionnaire
        |                           (acts as initial preferences setup)
        |                                      ↓
        |←————————— Spark session joined ——————|
        ↓                                      ↓
Both answer Spark questionnaire independently
        ↓
ScoringJob triggered (both submitted)
        ↓
score >= threshold                   score < threshold
→ Match created (origin: :spark)     → No match
→ SparkReward issued                 → Spark stored for analytics
→ Magic link sent to User B
```

#### UC-01 — Receiver already has the app
- Universal link opens Spark join flow directly, skipping App Store redirect.

#### UC-02 — Receiver closes app before completing onboarding
- qr_token remains valid within `expires_at` window (30 min default).
- User can reopen app and resume from where they left off.

#### UC-03 — qr_token expired before receiver joins
- Spark shows expired state to both users.
- Initiator must generate a new QR from "Start Spark".

#### UC-04 — qr_token used more than once
- Token is single-use: invalidated on first join.
- Second scan attempt returns an error — initiator must generate a new QR.

#### UC-05 — No health data available at scoring time
- No `signals` record exists for one or both users.
- Scoring falls back to declared preferences domain only.
- Score explanation must surface this clearly to the user.
- Ref: [decisions.md](../../product/decisions.md) — filter by `source: docs/features/spark-v1.md`.

---

## US-02 — Know what I value
As a user entering the app,
I want to answer a short questionnaire about what I look for in a partner,
so that my matches reflect what actually matters to me, not just raw data.

### UF-02 — Declared preferences setup
**Refs:** [signals-v1.md — Step 0](../../features/signals-v1.md#step-0--declared-preferences)

```
User opens app for the first time
        ↓
Presented with 5-question questionnaire
(sleep importance, temperature, movement, rhythm, chronotype)
        ↓
Answers submitted → POST /api/v1/signals/preferences
declared_preferences record created
        ↓
User proceeds to Spark or health data connection
```

#### UC-06 — Guest user joins via QR (no prior preferences)
- Spark questionnaire doubles as initial declared preferences setup.
- No prior `declared_preferences` record required to participate in Spark.
- Answers upserted to `declared_preferences` after submission.

#### UC-07 — User already has a declared_preferences record
- Spark questionnaire answers update existing weights via upsert.
- No duplicate record is created.

---

## US-03 — Understand myself before meeting anyone
As a user who connected my health data,
I want to see a human-readable summary of my lifestyle profile,
so that I can trust that Synca understands me before I receive any match.

### UF-03 — Self-discovery (user explores their own health profile)
**Refs:** [signals-v1.md — Step 1.0](../../features/signals-v1.md#step-10--apple-health--health-connect) · [signals-v1.md — User-facing layer](../../features/signals-v1.md#user-facing-layer)

```
User opens app after first Spark
        ↓
Prompted to connect Apple Health
Grants read-only permissions (sleep, steps, HR, activity)
        ↓
SignalsAggregatorService runs on-device
Aggregates last 30 days → sends derived metrics
POST /api/v1/signals
        ↓
User opens Profile → "My Health Profile"
GET /api/v1/signals/me/summary
        ↓
App displays:
  - Chronotype label ("Night owl")
  - Peak energy window ("21:00–23:00")
  - Routine stability tier
  - Activity tier
  - Sleep average + social jetlag
  - Self-report alignment note (if mismatch with declared preference)
```

#### UC-08 — Self-report mismatches computed chronotype
- User declared "morning person" but HealthKit shows avg wake time at 10:30.
- App surfaces alignment note: "Your data tells a different story."
- No blocking action — informational only.

#### UC-09 — User has no health data yet
- `signals` record does not exist.
- Profile screen shows prompt to connect Apple Health instead of summary.

---

## US-04 — Save my results after the first Spark
As a guest user who just completed my first Spark,
I want to activate my account with a single tap from my email,
so that I don't lose my compatibility results.

### UF-04 — Guest account activation
**Refs:** [profile-v1.md — Step 0](../../features/profile-v1.md#step-0--guest-onboarding-validation-mvp)

```
Spark completed
        ↓
Magic link sent to guest email:
"Activate your Synca account to save your results"
        ↓
User taps link → app opens activation screen
POST /api/v1/auth/activate
        ↓
User sets display name (only required field)
        ↓
account_type upgraded to :active
Permanent JWT issued
```

#### UC-10 — Magic link expired
- Token expiry: 72h.
- User requests resend via POST /api/v1/auth/resend_magic_link.
- Rate-limited: 1 resend per 5 minutes per email.

#### UC-11 — User never activates
- Guest record and all associated data purged after 30 days.
- No recovery possible after purge.

---

## Out of Scope in Phase 0
- Algorithm matching (nightly MatchingJob) → Phase 1
- Trust scoring beyond guest/active distinction → Phase 1
- Premium gating → Phase 2
- Android → Phase 2
- Photos and bio → Phase 1
- Circles / match chat → Phase 1
- Notifications → Phase 1 (ref: [notifications-v1.md](../../features/notifications-v1.md))
