# Feature: Profile
**Version:** 1.2
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1
**User flows:** `docs/product/phases/phase-0.md` — UF-01, UF-04

---

## Overview

Profile covers the full user identity lifecycle: registration, authentication,
onboarding, and ongoing profile management. It is the prerequisite for every
other feature — no feature is accessible without at least a guest account.

Authentication uses `has_secure_password` (bcrypt) + JWT. No dependency on
Devise or Warden. The JWT is stored in the iOS Keychain and Android
EncryptedSharedPreferences — never in unencrypted storage.

This file owns the `users`, `profiles`, `preference_profiles`, and
`identity_providers` tables. Every other feature that depends on users or
profiles references this file.

Two tiers of account exist:
- **Guest account** (Phase 0): created from email only, no password. Enables
  Spark sessions immediately. Activated to a full account via magic link.
- **Full account** (Phase 1+): email + password or social login. Full onboarding
  wizard completed.

---

## Step 0 — Guest Onboarding (Validation MVP)

**Phase:** 0
**Status:** Draft

### Rationale

The highest-curiosity moment in Synca is when two people are physically together
and want to try a Spark session immediately. Any authentication wall at this moment
causes drop-off. Guest onboarding removes that wall entirely.

This step must also support QR-driven acquisition: a user may first encounter Synca
by scanning another user's Spark QR code, downloading the app, and joining as a guest
with email only.

Even in guest mode, email is always collected at the entry point. The email is not
verified before the first Spark, but becomes mandatory to verify right after the
first completed Spark session. This ensures a contactable, growing user base from
day one without blocking the initial IRL interaction.

### User Flow

1. User opens the app for the first time, or arrives from a Spark QR code via deferred deep link.
2. Enters email only — no password, no name, no photo.
3. Backend creates a `User` record with `account_type: :guest` and issues a
   short-lived guest JWT (24-hour expiry).
4. If the user arrived from a Spark QR flow, the app resumes the pending Spark join automatically.
5. User proceeds directly to the Declared Preferences questionnaire
   (ref: `signals-v1.md — Step 0`) and then to the Spark screen.
6. After completing their first Spark session, a magic link is sent to their email:
   *"Activate your Synca account to save your compatibility results."*
7. User clicks the magic link → sets a display name → account upgraded to
   `account_type: :active`. A permanent JWT is issued. From this point on,
   an email-verified account is required to continue using the app.
8. If the user never clicks the magic link: guest record and all associated data
   are purged after 30 days.

### Guest account constraints

- Can complete Spark sessions
- Can answer the Declared Preferences questionnaire
- Can connect Apple Health / Health Connect
- Cannot send messages in a Circle (requires active account)
- Cannot receive algorithm-origin matches (requires active account + Premium)
- Cannot upload photos (requires active account)
- May keep `display_name` and profile photo empty until activation

### Magic link technical flow

```
Guest completes first Spark session
  → Backend sends email: "Activate your account" with signed token
     (token = JWT signed with app secret, payload: { user_id, purpose: 'activation', exp: 72h })
  → User clicks link → client sends token to POST /api/v1/auth/activate
  → Backend verifies token, upgrades user.account_type to :active
  → Returns permanent access token + refresh token
  → User sets display name (only required field at activation)
```

### DB Schema

Modification to `users` table (new column added in Phase 0):

```sql
users
  id              bigint PK
  email           string UNIQUE NOT NULL   -- required even for guests
  password_digest string                   -- null for guest accounts
  account_type    string NOT NULL DEFAULT 'guest'  -- 'guest' | 'active'
  created_at      datetime
  updated_at      datetime
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/auth/guest` | No | Creates guest user from email, returns short-lived JWT |
| POST | `/api/v1/auth/activate` | No | Validates magic link token, upgrades account to active, returns permanent tokens |
| POST | `/api/v1/auth/resend_magic_link` | No | Resends activation magic link for a guest account; rate-limited to 1 request per 5 minutes |

### Premium Gating

None — guest onboarding is available to all users by definition.

### Open Questions

See `docs/decisions.md` — filter by `source: docs/features/profile-v1.md`.

---

## Step 1.0 — Full Registration + Onboarding

**Phase:** 1
**Status:** Draft

### User Flow

**Registration (new user, no prior guest account):**
1. User opens the app and selects "Create account".
2. Enters email + password (minimum 8 characters).
3. Backend creates `User` (`account_type: :active`) + `Profile`, returns a JWT
   access token and a refresh token.
4. Tokens saved to Keychain (iOS) / EncryptedSharedPreferences (Android).
5. User is redirected to the onboarding wizard.

**Upgrade from guest account:**
1. User arrives via magic link (Step 0 flow).
2. Account is already `account_type: :active` after activation.
3. User is prompted to complete the remaining onboarding steps (photos, bio,
   extended preferences) at their own pace — these are not gated.

**Subsequent login:**
1. User enters email + password.
2. Backend validates credentials, returns a new access token and refresh token.
3. App updates the tokens in Keychain.

**Token refresh:**
- Access token expiry: 30 days.
- Refresh token expiry: 90 days.
- Client sends `POST /api/v1/auth/refresh` with the refresh token to obtain a
  new access token.
- Refresh tokens are single-use and rotated on each use.

**Onboarding wizard (4 steps, none skippable for new registrations):**
The app stores progress locally and resumes from the last completed step
if the user quits mid-flow.

- **Step 1 — Basic info:** display name (2–40 chars), date of birth (age ≥ 18),
  gender (`man` | `woman` | `non_binary`), city.
- **Step 2 — Photos:** 1–6 photos, at least 1 required. Each photo is queued
  for moderation before being shown to other users.
- **Step 3 — Bio:** free text, optional, max 300 chars.
- **Step 4 — Preferences:** looking for (`man` | `woman` | `non_binary` | `any`),
  age range (default ±5 years), max distance in km (default 25),
  dealbreakers (optional), city (auto-filled from Step 1).

On completion `profiles.onboarding_completed` is set to `true`.

### DB Schema

```sql
profiles
  id                     bigint PK
  user_id                bigint FK -> users NOT NULL UNIQUE
  display_name           string
  bio                    text
  date_of_birth          date NOT NULL
  gender                 string NOT NULL   -- 'man' | 'woman' | 'non_binary'
  city                   string NOT NULL
  photos                 jsonb NOT NULL DEFAULT '[]'
  onboarding_completed   boolean NOT NULL DEFAULT false
  trust_score            float NOT NULL DEFAULT 50.0
  completeness_score     integer NOT NULL DEFAULT 0
  spark_verified         boolean NOT NULL DEFAULT false
  irl_verification_count integer NOT NULL DEFAULT 0
  premium                boolean NOT NULL DEFAULT false
  created_at             datetime
  updated_at             datetime

-- Canonical definition of preference_profiles.
-- All other features must reference this file instead of re-defining this table.
preference_profiles
  id              bigint PK
  profile_id      bigint FK -> profiles NOT NULL UNIQUE
  looking_for     string NOT NULL   -- 'man' | 'woman' | 'non_binary' | 'any'
  age_min         integer NOT NULL DEFAULT 18
  age_max         integer NOT NULL DEFAULT 99
  max_distance_km integer NOT NULL DEFAULT 25
  gender_targets  jsonb   NOT NULL DEFAULT '[]'
  dealbreakers    jsonb   NOT NULL DEFAULT '[]'
  city            string  NOT NULL
  created_at      datetime
  updated_at      datetime

refresh_tokens
  id         bigint PK
  user_id    bigint FK -> users NOT NULL
  token      string NOT NULL UNIQUE
  expires_at datetime NOT NULL
  revoked_at datetime
  created_at datetime
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/auth/register` | No | Creates `User` + `Profile`, returns access + refresh tokens |
| POST | `/api/v1/auth/login` | No | Validates credentials, returns access + refresh tokens |
| POST | `/api/v1/auth/refresh` | No | Exchanges refresh token for new access token |
| GET | `/api/v1/auth/me` | Yes | Returns the current user from JWT |
| DELETE | `/api/v1/auth/logout` | Yes | Revokes the refresh token and invalidates the session |
| GET | `/api/v1/profile` | Yes | Returns own profile |
| PATCH | `/api/v1/profile` | Yes | Updates display_name, bio, city, gender, date_of_birth |
| POST | `/api/v1/profile/photos` | Yes | Uploads a photo, returns updated photos array |
| DELETE | `/api/v1/profile/photos/:index` | Yes | Removes photo at position index |
| GET | `/api/v1/profile/preferences` | Yes | Returns own preference_profile |
| PATCH | `/api/v1/profile/preferences` | Yes | Updates looking_for, age_min, age_max, max_distance_km, gender_targets, dealbreakers, city |

JWT payload: `{ user_id: integer, exp: unix_timestamp }`
All protected endpoints require: `Authorization: Bearer <token>`

Ref: `docs/api/openapi.yaml`

### Premium Gating

None — registration, login, and profile management are available on all tiers.

### Open Questions

See `docs/decisions.md` — filter by `source: docs/features/profile-v1.md`.

---

## Step 1.1 — Password Recovery and Credential Management

**Phase:** 1
**Status:** Draft

### Overview

Covers all credential recovery flows for active accounts: forgot password,
reset password via email link, and change password while authenticated.
Also covers the resend flow for guest magic links (documented under Step 0 endpoints
but technically part of the same token infrastructure).

All recovery tokens use the same JWT structure already in use for magic links:
```
payload: { user_id: integer, purpose: string, exp: unix_timestamp }
```
No new tables are introduced — the existing `refresh_tokens` table and
`password_digest` column on `users` are sufficient.

### Forgot Password Flow

```
User enters email on "Forgot password" screen
        ↓
POST /api/v1/auth/forgot_password  { email }
        ↓
Backend looks up user by email
  → If not found or account_type: :guest: always return 200 (no email enumeration)
  → If found and account_type: :active:
      generates JWT { user_id, purpose: 'password_reset', exp: 1h }
      sends email with deep link: synca://auth/reset?token=<jwt>
        ↓
User taps link in email → app opens reset password screen
        ↓
POST /api/v1/auth/reset_password  { token, new_password }
        ↓
Backend verifies JWT (purpose must be 'password_reset', not expired)
  → Updates user.password_digest
  → Revokes ALL active refresh_tokens for that user (force logout everywhere)
  → Returns new access token + refresh token
  → User is logged in immediately after reset
```

> The response to `POST /api/v1/auth/forgot_password` is always HTTP 200
> regardless of whether the email exists. This prevents email enumeration attacks.

### Change Password Flow (authenticated)

```
Authenticated user opens "Change password" in settings
        ↓
PATCH /api/v1/auth/password  { current_password, new_password }  [Auth required]
        ↓
Backend verifies current_password with authenticate
  → If invalid: 422 Unprocessable Entity
  → If valid:
      Updates user.password_digest
      Revokes all refresh_tokens except the one used in the current session
      Returns 200 OK
```

### Resend Magic Link Flow (guest accounts)

```
Guest user did not receive or the magic link expired
        ↓
POST /api/v1/auth/resend_magic_link  { email }  [No auth required]
        ↓
Backend looks up user by email
  → If not found or account_type: :active: always return 200
  → If found and account_type: :guest:
      Generates new JWT { user_id, purpose: 'activation', exp: 72h }
      Sends activation email
      Rate limit: max 1 resend per 5 minutes per email
```

### Token Rules Summary

| Purpose | Expiry | Revocation on use |
|---------|--------|-------------------|
| `activation` (magic link) | 72h | Yes — single-use |
| `password_reset` | 1h | Yes — single-use |
| Access token (JWT) | 30 days | No (stateless) |
| Refresh token | 90 days | Yes — rotated on use |

> `activation` and `password_reset` tokens are stateless JWTs — revocation is
> implicit via expiry and single-use enforcement (backend rejects a token whose
> `password_digest` has already changed after the token was issued, using `iat` claim).

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/auth/forgot_password` | No | Sends password reset email; always returns 200 |
| POST | `/api/v1/auth/reset_password` | No | Validates reset token, updates password, revokes all refresh tokens, returns new tokens |
| PATCH | `/api/v1/auth/password` | Yes | Changes password for authenticated user; revokes other sessions |
| POST | `/api/v1/auth/resend_magic_link` | No | Resends activation magic link for guest accounts; rate-limited |

Ref: `docs/api/openapi.yaml`

### Premium Gating

None — credential recovery is available to all users.

### Open Questions

See `docs/decisions.md` — filter by `source: docs/features/profile-v1.md`.

---

## Step 2.0 — Social Login

**Phase:** 2
**Status:** Planned

### User Flow

1. User selects "Continue with Apple" / "Continue with Google" / "Continue with VK".
2. Provider returns an OAuth token to the client.
3. Client sends the token to `POST /api/v1/auth/social`.
4. Backend verifies the token, finds or creates `User` + `Profile`.
5. Returns a Synca access token + refresh token. Flow is identical to Step 1.0
   from this point on.

If the provider email matches an existing account, the two are linked
automatically via `identity_providers`.

### DB Schema

```sql
identity_providers
  id          bigint PK
  user_id     bigint FK -> users NOT NULL
  provider    string NOT NULL   -- 'apple' | 'google' | 'vk'
  uid         string NOT NULL
  created_at  datetime
  UNIQUE (provider, uid)
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/auth/social` | No | Verifies OAuth token, returns Synca access + refresh tokens |

### Premium Gating

None — social login is available on all tiers.

### Open Questions

See `docs/decisions.md` — filter by `source: docs/features/profile-v1.md`.

---

## Step 3.0 — Profile Completeness Score

**Phase:** 2
**Status:** Planned

`completeness_score` (0–100) is computed server-side and **persisted on `profiles`**.
It is returned by `GET /api/v1/profile` and feeds into `trust_score` as one of its inputs.

The score is updated explicitly via `Profile::CompletenessCalculator` whenever a
relevant profile change occurs (photo upload/removal, bio update, preferences saved,
phone verification, signals connected). A nightly reconciliation job re-computes
all scores to ensure consistency.

Health signals data is synced separately (ref: `docs/features/signals-v1.md`) and
does not directly affect `completeness_score`. It is used by Matching and Spark
scoring instead.

-- ref: docs/features/trust-v1.md

| Input | Weight |
|-------|--------|
| At least 1 photo | 20 |
| Bio present | 15 |
| Signals connected (≥1) | 20 |
| Declared preferences completed | 5 |
| Phone verified | 20 |
| Age + gender + city set | 20 |

Declared preferences are stored in the `declared_preferences` table
(ref: `docs/features/signals-v1.md — Step 0`). Completing the questionnaire
adds 5 points to the profile completeness score.

No new tables introduced in this step. `GET /api/v1/profile` returns the
existing response extended with `{ "completeness_score": 85 }`.
The `completeness_score` column is defined in the `profiles` schema above (Step 1.0).

### Open Questions

See `docs/decisions.md` — filter by `source: docs/features/profile-v1.md`.
