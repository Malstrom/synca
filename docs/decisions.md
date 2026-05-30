# Synca — Open Decisions Log

**Last updated:** May 2026

This document tracks open questions collected from feature specs and product docs.
Each entry links back to the originating source. Once resolved, the decision is
recorded here and the source doc updated.

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

---

## Circles

- id: circles-circle-moment-flow
  status: open
  owner: tech
  source: docs/features/circles-v1.md / docs/features/moments-v1.md
  question: No endpoint documented to propose a Moment from inside a Circle. How does the Circle → Match → Moment navigation work in the API?
  decision:

---

## Trust

- id: trust-photo-moderation-provider
  status: open
  owner: tech
  source: docs/features/trust-v1.md — Open Questions
  question: Which provider is used for photo moderation in MVP (AWS Rekognition, Google Vision, or other)?
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
