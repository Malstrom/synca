# Gems Reference

This document maps every gem in `backend/api/Gemfile` to the feature
and phase that requires it. Use it to decide when to add or remove a gem,
and to understand why each dependency exists.

All gems not listed here are standard Rails infrastructure with no
specific phase dependency (e.g. `puma`, `bootsnap`, `tzinfo-data`).

---

## Already in Gemfile — Phase mapping

| Gem | Phase introduced | Feature / reason |
|---|---|---|
| `rails` | 0 | Core framework |
| `pg` | 0 | PostgreSQL adapter |
| `rack-cors` | 0 | CORS for iOS/Android clients |
| `pagy` | 0 | Pagination on all list endpoints |
| `bcrypt` | 0 | `has_secure_password` — auth |
| `jwt` | 0 | Access + refresh tokens — auth |
| `solid_cache` | 0 | DB-backed cache, no Redis |
| `solid_queue` | 0 | DB-backed background jobs (ScoringJob, MatchingJob, NotificationJob) |
| `solid_cable` | 1 | DB-backed Action Cable — Duo Circle real-time chat |
| `image_processing` | 1 | Profile photo variants (Active Storage) |
| `aws-sdk-s3` | 1 | S3-compatible storage (Yandex Object Storage RU / AWS S3) |
| `pundit` | 0 | Per-resource authorization |
| `interactor` | 0 | Service objects: CompatibilityScoreService, TrustScoreService |
| `sentry-ruby` + `sentry-rails` | 1 | Error tracking — no-op without `SENTRY_DSN` |

### Development

| Gem | Phase introduced | Reason |
|---|---|---|
| `annotate_models` ⚠️ | 0 | Schema comments on models — replaces deprecated `annotate` |
| `debug` | 0 | Ruby debugger |
| `brakeman` | 0 | Static security analysis — required on every CI push |
| `bundler-audit` | 0 | CVE audit on gem dependencies |
| `scalar_ruby` | 0 | Interactive API docs (Scalar UI) |

### Development + Test

| Gem | Phase introduced | Reason |
|---|---|---|
| `rubocop-rails-omakase` | 0 | Code style enforcement |
| `factory_bot_rails` | 0 | Test factories (Minitest) |
| `faker` | 0 | Fake data for seeds and tests |

### Test

| Gem | Phase introduced | Reason |
|---|---|---|
| `simplecov` | 0 | Coverage reporting — threshold ≥ 90% |
| `database_cleaner-active_record` | 0 | DB cleanup between test runs |
| `webmock` | 0 | HTTP mocking for external API calls |

---

## To add — per phase

### Phase 0 — Validation MVP

| Gem | Group | Reason |
|---|---|---|
| `strong_migrations` | default | Prevents dangerous PostgreSQL migrations (lock-free enforcement) |
| `rack-attack` | default | Rate limiting: magic link resend (1/5min), OTP, login brute-force |
| `bullet` | development | N+1 query detector — active from day one |

### Phase 1 — iOS MVP

| Gem | Group | Reason |
|---|---|---|
| `phonelib` | default | Phone number validation and normalization — Trust phone verify (+20 trust score) |
| `apnotic` | default | APNs HTTP/2 push notifications for iOS — NotificationJob delivery |
| `discard` | default | Soft delete for users (suspended), matches (drifted), reports |
| `geocoder` | default | Geo queries for Circles and Moments (location-based features) |

> FCM (Android push) does not require a gem — handled via direct HTTP call to
> the FCM v1 API using `net/http` + a service account token.

### Phase 2 — Android + Payments

| Gem | Group | Reason |
|---|---|---|
| `omniauth-apple` | default | Social login — Sign in with Apple |
| `omniauth-google-oauth2` | default | Social login — Sign in with Google |
| `omniauth-rails_csrf_protection` | default | Required CSRF companion for OmniAuth in API-only Rails |
| _(VK provider TBD)_ | default | Social login — VK (Russian market) — provider gem to be chosen |
| _(payments gem TBD)_ | default | Premium subscription — provider not yet decided (see decisions.md) |

### Phase 3+ — Future

| Gem | Phase | Reason |
|---|---|---|
| _(image moderation SDK TBD)_ | 3 | Automated nudity/escort detection — PhotoModerationJob |
| _(music API client TBD)_ | 5 | Spotify / Yandex Music signal ingestion |

---

## Gems explicitly excluded

| Gem | Reason for exclusion |
|---|---|
| `devise` | API-only app — Devise adds views, route macros, session logic. Auth handled with `has_secure_password` + JWT |
| `sidekiq` / `redis` | Replaced by Solid Queue + Solid Cache (zero external dependencies) |
| `kredis` | No use case not already covered by solid_cache |
| `stripe` / `revenue_cat` | Payment provider not yet decided — see decisions.md |

---

## Inconsistency

⚠️ `annotate` (currently in Gemfile) is deprecated in favor of `annotate_models`.
Must be replaced before Phase 0 development begins.
Fix: `gem "annotate_models", require: false` in the `:development` group.
