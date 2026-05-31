# Synca — Open Decisions Log

**Last updated:** May 2026

This document is the **single source of truth** for all open questions.
Feature docs do not contain open questions — they reference this file.
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
  status: open
  owner: product
  source: docs/features/matching-v1.md — Open Questions
  question: Minimum signals data threshold before a user enters the algorithm pool — suggested 7 days. Confirmed?
  decision:

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

- id: signals-reask-preferences
  status: open
  owner: product
  source: docs/features/signals-v1.md — Open Questions
  question: Should declared preferences be re-asked after 6 months, or remain static until manually updated by the user?
  decision:

- id: signals-partial-spark-scoring
  status: open
  owner: tech
  source: docs/features/spark-v1.md — Open Questions
  question: If a user has no signals record yet (never connected Apple Health), should Spark scoring fall back to declared preferences only, or should the Spark be blocked?
  decision:

---

## Profile

- id: profile-email-verification-mvp
  status: open
  owner: product
  source: docs/features/profile-v1.md — Step 1.0 Open Questions
  question: Is email verification mandatory before accessing the app, or optional in MVP?
  decision:

- id: profile-completeness-storage
  status: open
  owner: tech
  source: docs/features/profile-v1.md — Step 3.0 Open Questions
  question: Should `completeness_score` be stored on `profiles` or computed on every request?
  decision:

- id: profile-guest-magic-link-timing
  status: open
  owner: product
  source: docs/features/profile-v1.md — Step 0 Open Questions
  question: Should the magic link be sent immediately after guest account creation, or only after the first Spark session completes?
  decision:

---

## Spark

- id: spark-discovery-method-step1
  status: open
  owner: product
  source: docs/features/spark-v1.md — Step 1.0 Open Questions
  question: Should both Bluetooth and QR code discovery be available in Step 1.0, or ship QR only first?
  decision:

- id: spark-session-expiry-window
  status: open
  owner: product
  source: docs/features/spark-v1.md — Step 1.0 Open Questions
  question: Session expiry window is set at 10 minutes — is this too short for noisy environments (concerts, gyms)?
  decision:

- id: spark-group-max-size
  status: open
  owner: product
  source: docs/features/spark-v1.md — Step 2.0 Open Questions
  question: Maximum group size for a Group Spark? Suggested up to 22 for event Circle compatibility.
  decision:

- id: spark-group-partial-scoring
  status: open
  owner: tech
  source: docs/features/spark-v1.md — Step 2.0 Open Questions
  question: If some participants do not confirm presence before expiry, should partial scoring proceed for the pairs that did confirm?
  decision:

- id: spark-group-initiator-summary
  status: open
  owner: product
  source: docs/features/spark-v1.md — Step 2.0 Open Questions
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
  source: docs/features/circles-v1.md — Step 1.0 Open Questions
  question: Should a Duo Circle be automatically archived if the match status transitions to `ended`?
  decision:

- id: circles-moment-from-circle
  status: open
  owner: tech
  source: docs/features/circles-v1.md — Step 1.0 Open Questions / docs/features/moments-v1.md
  question: Should Moment proposals be surfaced inside the Duo Circle chat UI, or as a separate flow? No endpoint documented to propose a Moment from inside a Circle — how does Circle → Match → Moment navigation work in the API?
  decision:

---

## Moments

- id: moments-location-type
  status: open
  owner: product
  source: docs/features/moments-v1.md — Step 1.0 Open Questions
  question: Should `location` be a free-text field only, or should we integrate a maps API for structured venue selection?
  decision:

- id: moments-counter-cap-enforcement
  status: open
  owner: tech
  source: docs/features/moments-v1.md — Step 1.0 Open Questions
  question: Is the 5-round counter-proposal cap enforced server-side or client-side only?
  decision:

- id: moments-ratings-visibility
  status: open
  owner: product
  source: docs/features/moments-v1.md — Step 1.0 Open Questions
  question: Should ratings be visible to the rated user or remain fully private?
  decision:

- id: moments-noshows-suspension-threshold
  status: open
  owner: product
  source: docs/features/moments-v1.md — Step 2.0 Open Questions
  question: After how many confirmed no-shows should a profile be automatically suspended?
  decision:

- id: moments-positive-rating-reward
  status: open
  owner: product
  source: docs/features/moments-v1.md — Step 2.0 Open Questions
  question: Should positive ratings unlock any in-app reward or badge?
  decision:

---

## Trust

- id: trust-otp-provider
  status: open
  owner: tech
  source: docs/features/trust-v1.md — Step 1.0 Open Questions
  question: Which OTP provider to use (Twilio, SMS.ru for RU market)?
  decision:

- id: trust-suspended-notification
  status: open
  owner: product
  source: docs/features/trust-v1.md — Step 1.0 Open Questions
  question: Should suspended profiles receive an in-app notification or be silently excluded?
  decision:

- id: trust-report-appeal
  status: open
  owner: product
  source: docs/features/trust-v1.md — Step 1.0 Open Questions
  question: Can a user appeal a confirmed report?
  decision:

- id: trust-photo-moderation-provider
  status: open
  owner: tech
  source: docs/features/trust-v1.md — Step 2.0 Open Questions
  question: Which provider is used for photo moderation in MVP (AWS Rekognition, Google Vision, or other)?
  decision:

- id: trust-photo-pending-visibility
  status: open
  owner: product
  source: docs/features/trust-v1.md — Step 2.0 Open Questions
  question: Should photos with `pending` moderation be visible to the uploader but not to other users, or hidden entirely?
  decision:

- id: trust-liveness-provider
  status: open
  owner: tech
  source: docs/features/trust-v1.md — Step 2.0 Open Questions
  question: Which liveness provider to use (iProov, Onfido, custom)?
  decision:

- id: trust-score-history-log
  status: open
  owner: tech
  source: docs/features/trust-v1.md — Step 3.0 Open Questions
  question: Should `trust_score` history be logged for auditing and appeals?
  decision:

- id: trust-score-hard-caps
  status: open
  owner: tech
  source: docs/features/trust-v1.md — Step 3.0 Open Questions
  question: Maximum and minimum score caps — hard floor at 0, hard ceiling at 100?
  decision:

---

## Notifications

- id: notifications-circle-message-suppression
  status: open
  owner: tech
  source: docs/features/notifications-v1.md — Open Questions
  question: Should `circle_message` push be suppressed if the user has the Circle screen open (real-time via Action Cable is already active)?
  decision:

- id: notifications-signals-stale-cadence
  status: open
  owner: product
  source: docs/features/notifications-v1.md — Open Questions
  question: Should `signals_stale` fire at 7 days, 14 days, or both?
  decision:

- id: notifications-token-rotation
  status: open
  owner: tech
  source: docs/features/notifications-v1.md — Open Questions
  question: APNs/FCM token rotation — when a token is invalidated by the platform, how does the backend detect and deactivate it? Suggested: parse APNs/FCM error responses in NotificationJob and set device_tokens.active = false.
  decision:

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
  status: open
  owner: tech
  source: docs/infra/deployment.md — Phase 2
  question: CI trigger path is `backend/api/**` but repo structure may differ. Verify actual path before first deploy.
  decision:
