# Synca — Open Decisions Log

**Last updated:** May 2026

This document is the **single source of truth** for all open questions.
Feature docs do not contain open questions — they link to this file.
Once resolved, the decision is recorded here and the answer is integrated
directly into the relevant feature doc text.

---

## Format

```
- id:       short-kebab-id
  status:   open | decided | dropped
  owner:    product | tech | both
  source:   docs/features/<file> — <section>
  question: the open question as originally written
  decision: (filled once status = decided)
```

---

## Matching

- id: matching-min-days-signals
  status: decided
  owner: product
  source: docs/features/matching-v1.md — Open Questions
  question: Minimum signals data threshold before a user enters the algorithm pool — suggested 7 days. Confirmed?
  decision: Minimum 7 days of signals, configurable (default 7).

- id: matching-max-algo-matches-per-day
  status: open
  owner: product
  source: docs/features/matching-v1.md — Open Questions
  question: Maximum algorithm-origin matches surfaced per nightly run — suggested 1–3. Confirmed?
  decision:

- id: matching-reconnected-trigger
  status: open
  owner: tech
  source: docs/features/matching-v1.md — Match Lifecycle
  question: What triggers a match to move from `drifted` back to `reconnected`? New Spark between the same users, OR signals refresh, OR both?
  decision:

---

## Signals

- id: signals-steps-resting-hr-in-summary
  status: open
  owner: tech
  source: chats (Igor, design review round 2) · apps/ios/Synca/Features/Profile/ProfileView.swift
  question: >
    Igor asked to show daily step count on the Profile "My Health" screen, and
    a later comment asked for resting heart rate too. Neither is stored today —
    `health_summaries` has `activity_level` (a low/medium/high enum) and
    `recovery_score` (also an enum) but no raw step count or bpm column, and
    `SignalsSummaryService`/`SignalsSummarySerializer` don't expose either.
    The iOS app (`SignalAggregatorService`) already computes both locally —
    `avg_daily_steps` from the same step samples used for `activity_level`,
    and `avg_resting_heart_rate_bpm` from `HKQuantityType(.restingHeartRate)`
    (already a requested read permission, just never queried before). Add
    `avg_daily_steps integer` and `avg_resting_heart_rate_bpm integer` to
    `health_summaries`, accept them in `HealthSummaryContract`, and expose both
    on `GET /signals/me/summary`? Proposed shapes are in docs/api/openapi.yaml.
  decision:

- id: signals-reask-preferences
  status: open
  owner: product
  source: docs/features/signals-v1.md — Open Questions
  question: Should declared preferences be re-asked after 6 months, or remain static until manually updated by the user?
  decision:

- id: signals-partial-spark-scoring
  status: decided
  owner: tech
  source: docs/features/spark-v1.md — Open Questions
  question: If a user has no signals record yet (never connected Apple Health), should Spark scoring fall back to declared preferences only, or should the Spark be blocked?
  decision: In MVP (iOS only), Spark is blocked if Apple Health is not connected. Users see a nudge to connect it. Fallback scoring without health data is deferred to a future version when additional connectors are available.

---

## Profile

- id: profile-email-verification-mvp
  status: decided
  owner: product
  source: docs/features/profile-v1.md — Open Questions
  question: Is email verification mandatory before accessing the app, or optional in MVP?
  decision: Email is not required at first Spark (guest mode). After the first completed Spark session, email registration with magic link verification is mandatory before further app use.

- id: profile-completeness-storage
  status: decided
  owner: tech
  source: docs/features/profile-v1.md — Open Questions
  question: Should `completeness_score` be stored on `profiles` or computed on every request?
  decision: completeness_score is persisted on profiles and updated explicitly via Profile::CompletenessCalculator after each profile change. A nightly reconciliation job ensures consistency. Health signals data is synced separately and does not affect completeness_score directly.

- id: profile-guest-magic-link-timing
  status: open
  owner: product
  source: docs/features/profile-v1.md — Open Questions
  question: Should the magic link be sent immediately after guest account creation, or only after the first Spark session completes?
  decision:

---

## Spark

- id: spark-heart-rate-during-session
  status: open
  owner: product
  source: chats (Igor, design review round 2, on the Spark result screen) · apps/ios/Synca/Features/Spark/SparkResultView.swift
  question: >
    Igor asked to show both participants' heart rate during the Spark itself
    on the result screen — not the 30-day resting HR average
    (`signals-steps-resting-hr-in-summary`), a live/session-scoped reading
    tied to that specific encounter. Nothing stores this today: `sparks` has
    no heart-rate columns, and there's no submission path — `submit_answers`
    only carries questionnaire answers. Needs: (1) `sparks` columns for each
    participant's avg bpm during the session window (`started_at` →
    `completed_at`), (2) a submission mechanism — most naturally, extend
    `submit_answers`'s payload to optionally carry an avg-HR-during-session
    value alongside the questionnaire answers, since that's already the point
    where each participant reports in independently, and (3) `SparkResultService`
    resolving both values to the requester's own perspective
    (`your_avg_heart_rate`/`partner_avg_heart_rate`) on `GET /sparks/:id/result`,
    the same way `compatibility_score` already is — `SparkSerializer` exposes
    neither `initiator_id` nor `partner_id`, so the client has no way to
    resolve "which side am I" itself. iOS would also need to actually sample
    `HKQuantityType(.heartRate)` bracketed to the Spark's live window, which
    `SignalAggregatorService` doesn't do today (it only aggregates a rolling
    30-day history, not a specific live session).
  decision:

- id: spark-guest-anonymous-identity
  status: open
  owner: tech
  source: docs/features/spark-v1.md · apps/ios/Synca (design review, Igor, 2026-07)
  question: >
    Design review moved email collection from *before* the first Spark to
    *after* the result ("Connect Apple Health → scan QR → questionnaire →
    result → email capture", see chats/chat1.md). But `/sparks/:id/join`,
    `/sparks/:id/submit_answers`, and `/sparks/:id/result` all require a
    valid JWT (`ApplicationController#authenticate_user!`), and
    `GuestRegistrationContract` currently rejects `POST /auth/guest` unless
    at least one of `email`/`phone` is present. There is no way today to get
    an authenticated session before the result is shown. What should the
    guest identity look like pre-email — a fully anonymous guest user
    (relax the contract to allow an empty `auth: {}` body, see
    `docs/api/openapi.yaml` § `/auth/guest`), or a device-bound identifier
    (e.g. `identifierForVendor`) sent as a pseudo-phone? If anonymous,
    what happens to an anonymous guest who never returns to claim an email —
    same 30-day guest purge as `profile-guest-magic-link-timing`, or shorter?
  decision:

- id: spark-join-by-code-without-id
  status: open
  owner: tech
  source: docs/api/openapi.yaml § /sparks/join · apps/ios/Synca/Features/Spark
  question: >
    `POST /sparks/:id/join` needs the numeric Spark id in the URL, but a user
    scanning a QR only has `qr_token`, and a user typing a 6-digit
    `session_code` manually never sees an id either. Add a collection-level
    `POST /sparks/join` that looks the Spark up by `session_code`/`qr_token`
    (both already unique)? Proposed shape is in docs/api/openapi.yaml. The iOS
    client (`SparkProximityService`, `SparkViewModel`) already calls this
    endpoint — it 404s against the real server until it exists.
  decision:

- id: spark-result-recap-data-source
  status: open
  owner: product
  source: chats/chat1.md (Igor, on [data-dc-tpl="239"]) · apps/ios/Synca/Features/Spark/SparkResultView.swift
  question: >
    Igor's richer-result request asked for a recap with "attività media, quando
    le due persone vanno a dormire, quanto dormono di media" (avg activity,
    bedtimes, sleep avg) shown as raw You/Them values — that's what the
    prototype pixels show. But `GET /sparks/:id/result` only returns
    `dimensions: {sleep_rhythm, energy_overlap, lifestyle}` percentages, not
    either participant's raw health summary — and there's no endpoint that
    would return a stranger's exact bedtime/step count even if we wanted one.
    The iOS implementation shows the three dimension percentages instead (also
    used by the Match Detail concept screen) — safer privacy-wise (no raw
    metric of someone you just met is exposed) and it's what the backend
    actually returns today. Confirm this is the intended tradeoff, or scope a
    "comparison summary" endpoint that returns rounded/bucketed (not raw)
    values for both participants if the literal You/Them table is wanted.
  decision:

- id: spark-discovery-method-step1
  status: open
  owner: product
  source: docs/features/spark-v1.md — Open Questions
  question: Should both Bluetooth and QR code discovery be available in Step 1.0, or ship QR only first?
  decision:

- id: spark-session-expiry-window
  status: open
  owner: product
  source: docs/features/spark-v1.md — Open Questions
  question: Session expiry window is set at 10 minutes — is this too short for noisy environments (concerts, gyms)?
  decision:

- id: spark-group-max-size
  status: open
  owner: product
  source: docs/features/spark-v1.md — Open Questions
  question: Maximum group size for a Group Spark? Suggested up to 22 for event Circle compatibility.
  decision:

- id: spark-group-partial-scoring
  status: open
  owner: tech
  source: docs/features/spark-v1.md — Open Questions
  question: If some participants do not confirm presence before expiry, should partial scoring proceed for the pairs that did confirm?
  decision:

- id: spark-group-initiator-summary
  status: open
  owner: product
  source: docs/features/spark-v1.md — Open Questions
  question: Should the group initiator see a summary of all pairwise scores after completion, or only their own pairs?
  decision:

- id: spark-icebreaker-framing
  status: open
  owner: product
  source: docs/features/spark-v1.md — Overview
  question: >
    Spark functions as a social icebreaker — a neutral pretext to approach
    someone IRL without the social pressure of a direct romantic approach.
    Should this framing be made explicit in the Overview of spark-v1.md
    and in positioning.md? If yes, define guardrails to prevent misuse
    (e.g. daily Spark limit, TrustScore penalty for unanswered cold Sparks).
  decision:

- id: spark-low-score-bonus
  status: open
  owner: product
  source: docs/features/spark-v1.md — Step 1.0, Premium Gating
  question: >
    When a Spark produces a low compatibility score (below the match creation
    threshold), the user receives a bonus to encourage re-engagement.
    Bonus type is TBD (free Spark credits, temporary premium access, or
    other in-app reward). Should this be gated behind a minimum number of
    completed Sparks to prevent farming? Define: score threshold that triggers
    the bonus, bonus type, cooldown period, and whether it applies to both
    participants or only the initiator.
  decision:

---

## Circles

- id: circles-archive-on-match-end
  status: open
  owner: product
  source: docs/features/circles-v1.md — Open Questions
  question: Should a Duo Circle be automatically archived if the match status transitions to `ended`?
  decision:

- id: circles-moment-from-circle
  status: open
  owner: tech
  source: docs/features/circles-v1.md — Open Questions
  question: Should Moment proposals be surfaced inside the Duo Circle chat UI, or as a separate flow? No endpoint documented to propose a Moment from inside a Circle — how does Circle → Match → Moment navigation work in the API?
  decision:

---

## Moments

- id: moments-location-type
  status: open
  owner: product
  source: docs/features/moments-v1.md — Open Questions
  question: Should `location` be a free-text field only, or should we integrate a maps API for structured venue selection?
  decision:

- id: moments-counter-cap-enforcement
  status: decided
  owner: tech
  source: docs/features/moments-v1.md — Open Questions
  question: Is the 5-round counter-proposal cap enforced server-side or client-side only?
  decision: The 5-round counter-proposal cap is enforced server-side by counting negotiation rounds in the database. The client reflects this limit in the UI but is not the authoritative source. Counter data is retained for ML metrics.

- id: moments-ratings-visibility
  status: open
  owner: product
  source: docs/features/moments-v1.md — Open Questions
  question: Should ratings be visible to the rated user or remain fully private?
  decision:

- id: moments-noshows-suspension-threshold
  status: open
  owner: product
  source: docs/features/moments-v1.md — Open Questions
  question: After how many confirmed no-shows should a profile be automatically suspended?
  decision:

- id: moments-positive-rating-reward
  status: open
  owner: product
  source: docs/features/moments-v1.md — Open Questions
  question: Should positive ratings unlock any in-app reward or badge?
  decision:

---

## Trust

- id: trust-otp-provider
  status: open
  owner: tech
  source: docs/features/trust-v1.md — Open Questions
  question: Which OTP provider to use (Twilio, SMS.ru for RU market)?
  decision:

- id: trust-suspended-notification
  status: open
  owner: product
  source: docs/features/trust-v1.md — Open Questions
  question: Should suspended profiles receive an in-app notification or be silently excluded?
  decision:

- id: trust-report-appeal
  status: open
  owner: product
  source: docs/features/trust-v1.md — Open Questions
  question: Can a user appeal a confirmed report?
  decision:

- id: trust-photo-moderation-provider
  status: open
  owner: tech
  source: docs/features/trust-v1.md — Open Questions
  question: Which provider is used for photo moderation in MVP (AWS Rekognition, Google Vision, or other)?
  decision:

- id: trust-photo-pending-visibility
  status: open
  owner: product
  source: docs/features/trust-v1.md — Open Questions
  question: Should photos with `pending` moderation be visible to the uploader but not to other users, or hidden entirely?
  decision:

- id: trust-liveness-provider
  status: open
  owner: tech
  source: docs/features/trust-v1.md — Open Questions
  question: Which liveness provider to use (iProov, Onfido, custom)?
  decision:

- id: trust-score-history-log
  status: open
  owner: tech
  source: docs/features/trust-v1.md — Open Questions
  question: Should `trust_score` history be logged for auditing and appeals?
  decision:

- id: trust-score-hard-caps
  status: decided
  owner: tech
  source: docs/features/trust-v1.md — Open Questions
  question: Maximum and minimum score caps — hard floor at 0, hard ceiling at 100?
  decision: Trust score is clamped between 0 and 100 inclusive.

---

## Notifications

- id: notifications-circle-message-suppression
  status: decided
  owner: tech
  source: docs/features/notifications-v1.md — Open Questions
  question: Should `circle_message` push be suppressed if the user has the Circle screen open (real-time via Action Cable is already active)?
  decision: Suppress circle_message push when a live real-time subscription for that Circle is active; otherwise send as normal.

- id: notifications-signals-stale-cadence
  status: open
  owner: product
  source: docs/features/notifications-v1.md — Open Questions
  question: Should `signals_stale` fire at 7 days, 14 days, or both?
  decision:

- id: notifications-token-rotation
  status: decided
  owner: tech
  source: docs/features/notifications-v1.md — Open Questions
  question: APNs/FCM token rotation — when a token is invalidated by the platform, how does the backend detect and deactivate it? Suggested: parse APNs/FCM error responses in NotificationJob and set device_tokens.active = false.
  decision: Parse APNs/FCM error responses in NotificationJob and set device_tokens.active = false when a token is invalid.

- id: notifications-email-per-type-overrides
  status: open
  owner: product
  source: docs/features/notifications-v1.md — Open Questions
  question: Should `notification_preferences` support per-type email overrides, or is a single `email_enabled` toggle sufficient for MVP?
  decision:

- id: notifications-telegram-bot-separation
  status: open
  owner: product
  source: docs/features/notifications-v1.md — Open Questions
  question: Telegram bot — dedicated @SyncaBot (user-facing) or shared with the field research bot? Suggested: separate — the research bot is internal tooling, the notification bot is user-facing.
  decision:

- id: notifications-deep-link-scheme
  status: open
  owner: tech
  source: docs/features/notifications-v1.md — Open Questions
  question: Deep link scheme for each `screen` value needs alignment with iOS/Android navigation (ref: docs/architecture/ios-structure.md, docs/architecture/android-structure.md).
  decision:

---

## Infrastructure

- id: infra-ru-region-timing
  status: open
  owner: both
  source: docs/infra/deployment.md — Phase 4
  question: When does the RU-region instance (Yandex Cloud / VK Cloud) need to be provisioned relative to Moscow launch?
  decision:

- id: infra-ci-path-trigger
  status: decided
  owner: tech
  source: docs/infra/deployment.md — Phase 2
  question: CI trigger path is `backend/api/**` but repo structure may differ. Verify actual path before first deploy.
  decision: Update CI config to match actual backend path (e.g. api/**) and ensure any backend change triggers CI.
