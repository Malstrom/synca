# Feature: Profile
**Version:** 1.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1

---

## Overview

Profile covers the full user identity lifecycle: registration, authentication,
onboarding, and ongoing profile management. It is the prerequisite for every
other feature — no feature is accessible without a verified account and a
completed profile.

Authentication uses `has_secure_password` (bcrypt) + JWT. No dependency on
Devise or Warden. The JWT is stored in the iOS Keychain and Android
EncryptedSharedPreferences — never in unencrypted storage.

This file owns the `users`, `profiles`, and `preference_profiles` tables.
Every other feature that depends on users or profiles references this file.

---

## Step 1.0 — Registration + Onboarding

**Phase:** 1
**Status:** Draft

### User Flow

**Registration:**
1. User opens the app for the first time and selects "Sign up".
2. Enters email + password (minimum 8 characters).
3. Backend creates `User` + `Profile`, returns a JWT.
4. JWT saved to Keychain (iOS) / EncryptedSharedPreferences (Android).
5. User is redirected to the onboarding wizard.

**Subsequent login:**
1. User enters email + password.
2. Backend validates credentials, returns a new JWT.
3. App updates the token in Keychain.

Token expiry: 30 days. No refresh token in Step 1.0.

**Onboarding wizard (4 steps, none skippable):**
The app stores progress locally and resumes from the last completed step
if the user quits mid-flow.

- **Step 1 — Basic info:** display name (2–40 chars), date of birth (age ≥ 18),
  gender (`man` | `woman` | `non_binary`), city.
- **Step 2 — Photos:** 1–6 photos, at least 1 required. Each photo is queued
  for moderation before being shown to other users.
- **Step 3 — Bio:** free text, optional, max 300 chars.
- **Step 4 — Preferences:** looking for (`man` | `woman` | `both`),
  age range (default ±5 years), max distance in km (default 25).

On completion `profiles.onboarding_completed` is set to `true`.

### DB Schema

```sql
users
  id              bigint PK
  email           string NOT NULL UNIQUE
  password_digest string NOT NULL        -- bcrypt via has_secure_password
  created_at      datetime
  updated_at      datetime

profiles
  id                     bigint PK
  user_id                bigint FK -> users NOT NULL
  display_name           string
  bio                    text
  date_of_birth          date NOT NULL
  gender                 string NOT NULL   -- 'man' | 'woman' | 'non_binary'
  city                   string NOT NULL
  photos                 jsonb NOT NULL DEFAULT '[]'
  onboarding_completed   boolean NOT NULL DEFAULT false
  trust_score            float NOT NULL DEFAULT 50.0
  spark_verified         boolean NOT NULL DEFAULT false
  irl_verification_count integer NOT NULL DEFAULT 0
  premium                boolean NOT NULL DEFAULT false
  created_at             datetime
  updated_at             datetime

preference_profiles
  id              bigint PK
  profile_id      bigint FK -> profiles NOT NULL UNIQUE
  looking_for     string NOT NULL   -- 'man' | 'woman' | 'both'
  age_min         integer NOT NULL DEFAULT 18
  age_max         integer NOT NULL DEFAULT 99
  max_distance_km integer NOT NULL DEFAULT 25
  created_at      datetime
  updated_at      datetime
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/auth/register` | No | Creates `User` + `Profile`, returns JWT |
| POST | `/api/v1/auth/login` | No | Validates credentials, returns JWT |
| GET | `/api/v1/auth/me` | Yes | Returns the current user from JWT |
| DELETE | `/api/v1/auth/logout` | Yes | Invalidates the session on the client |
| GET | `/api/v1/profile` | Yes | Returns own profile |
| PATCH | `/api/v1/profile` | Yes | Updates display_name, bio, city, gender, date_of_birth |
| POST | `/api/v1/profile/photos` | Yes | Uploads a photo, returns updated photos array |
| DELETE | `/api/v1/profile/photos/:index` | Yes | Removes photo at position index |
| GET | `/api/v1/profile/preferences` | Yes | Returns own preference_profile |
| PATCH | `/api/v1/profile/preferences` | Yes | Updates looking_for, age_min, age_max, max_distance_km |

JWT payload: `{ user_id: integer, exp: unix_timestamp }`
All protected endpoints require: `Authorization: Bearer <token>`

Ref: `docs/api/openapi.yaml`

### Premium Gating

None — registration, login, and profile management are available on all tiers.

### Open Questions

- Add refresh token in Step 1.0 or defer to Step 2.0?
- Is email verification mandatory before accessing the app, or optional in MVP?
- Should `city` be a FK to a future `city_configs` table or a free string in MVP?
- Photo ordering: drag-and-drop on client only, or persisted server-side?
- Is the minimum of 1 photo enforced at the API level or client-side only?

---

## Step 2.0 — Social Login

**Phase:** 2
**Status:** Planned

### User Flow

1. User selects "Continue with Apple" / "Continue with Google" / "Continue with VK".
2. Provider returns an OAuth token to the client.
3. Client sends the token to `POST /api/v1/auth/social`.
4. Backend verifies the token, finds or creates `User` + `Profile`.
5. Returns a Synca JWT. Flow is identical to Step 1.0 from this point on.

If the provider email matches an existing account, the two are linked
automatically via `identity_providers`.

### DB Schema

```sql
-- users: email and password_digest become nullable for social-only accounts
-- email: was NOT NULL; now UNIQUE but nullable
-- password_digest: was NOT NULL; now nullable

identity_providers
  id          bigint PK
  user_id     bigint FK -> users NOT NULL
  provider    string NOT NULL   -- 'apple' | 'google' | 'vk'
  uid         string NOT NULL   -- unique ID issued by the provider
  created_at  datetime
  UNIQUE (provider, uid)
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/auth/social` | No | Verifies OAuth token, returns Synca JWT |

### Premium Gating

None — social login is available on all tiers.

### Open Questions

- Is VK a priority for the Russian market in Step 2.0, or deferred to Step 2.1?
- Orphan account: user registers with Apple and later wants to add a password — what is the flow?
- Token revocation: if a user revokes access from Apple/Google, how is the active Synca session handled?

---

## Step 3.0 — Profile Completeness Score

**Phase:** 2
**Status:** Planned

A `completeness_score` (0–100) is computed server-side and returned by
`GET /api/v1/profile`. It feeds into `trust_score` as one of its inputs.

-- ref: docs/features/trust-v1.md

| Input | Weight |
|-------|--------|
| At least 1 photo | 20 |
| Bio present | 15 |
| Signals connected (≥1) | 25 |
| Phone verified | 20 |
| Age + gender + city set | 20 |

No new tables introduced in this step. `GET /api/v1/profile` returns the
existing response extended with `{ "completeness_score": 85 }`.

### Open Questions

- Should `completeness_score` be stored on `profiles` or computed on every request?
