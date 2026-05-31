# Feature: Profile
**Version:** 2.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 0

---

## Overview

Profile covers the full user identity lifecycle: registration, authentication,
onboarding, and ongoing profile management. It is the prerequisite for every
other feature — no feature is accessible without at least a guest account.

Two tiers of account exist:
- **Guest account** (Phase 0): created from email only. Enables Spark sessions immediately.
  Activated to a full account via magic link after the first completed Spark.
- **Full account** (Phase 1+): email + password or social login. Full onboarding wizard completed.

Authentication uses `has_secure_password` (bcrypt) + JWT. The JWT is stored in
the iOS Keychain and Android EncryptedSharedPreferences — never in unencrypted storage.

---

## Steps

| Step | Phase | Status | Description |
|---|---|---|---|
| 0 — Guest Onboarding | 0 | Draft | Email-only account creation, magic link activation |
| 1.0 — Full Registration + Onboarding | 1 | Draft | Email + password, onboarding wizard, profile setup |
| 1.1 — Password Recovery | 1 | Draft | Forgot password, reset via email, change password |
| 2.0 — Social Login | 2 | Planned | Apple, Google, VK |
| 3.0 — Profile Completeness Score | 2 | Planned | Computed score (0–100) persisted on profiles |

UX flows:
- Phase 0 → [phase-0.md — UF-04](../product/phases/phase-0.md#uf-04--guest-account-activation)
- Phase 1 → [phase-1.md — UF-05](../product/phases/phase-1.md#uf-05--full-registration--onboarding-wizard)
- Phase 1 → [phase-1.md — UF-06](../product/phases/phase-1.md#uf-06--password-recovery)
- Phase 2 → [phase-2.md — UF-11](../product/phases/phase-2.md#uf-11--social-login)

---

## Business Rules

### Guest account
- Email is always collected at entry, even in guest mode.
- Email verification is not required before the first Spark, but becomes
  mandatory immediately after the first completed Spark session.
- A guest account cannot upload photos, send Circle messages, or receive
  algorithm-origin matches.
- `display_name` and profile photo may remain empty until activation.

### Magic link
- Token: JWT signed with app secret, payload `{ user_id, purpose: 'activation', exp: 72h }`.
- Single-use: backend rejects reuse.
- On activation: `users.account_type` upgrades from `'guest'` to `'active'`.
- Setting `display_name` is the only required step at activation.

### Token rules

| Purpose | Expiry | Revocation on use |
|---|---|---|
| `activation` (magic link) | 72h | Yes — single-use |
| `password_reset` | 1h | Yes — single-use |
| Access token (JWT) | 30 days | No (stateless) |
| Refresh token | 90 days | Yes — rotated on use |

### Profile completeness score
- Computed by `Profile::CompletenessCalculator` on every relevant profile change.
- Nightly reconciliation job re-computes all scores for consistency.
- Health signals data does not directly affect this score — it feeds Matching and Spark.

| Input | Weight |
|---|---|
| At least 1 photo | 20 |
| Bio present | 15 |
| Signals connected (≥1) | 20 |
| Declared preferences completed | 5 |
| Phone verified | 20 |
| Age + gender + city set | 20 |

---

## References

- DB Schema → [docs/architecture/db-schema.md § Profile](../architecture/db-schema.md#profile)
- API → `docs/api/openapi.yaml`
- Rails Model → [docs/conventions/backend.md § Domain Model](../conventions/backend.md#domain-model-rails-associations)
- Monetization → [docs/product/monetization.md](../product/monetization.md)

---

## Open Questions

See [docs/product/decisions.md](../product/decisions.md) — filter by `source: docs/features/profile-v1.md`.
