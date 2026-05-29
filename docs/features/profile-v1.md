# Feature: Profile
**Version:** 1.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1

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

### User Flow

1. User opens the app for the first time.
2. Enters email only — no password, no name, no photo.
3. Backend creates a `User` record with `account_type: :guest` and issues a
   short-lived guest JWT (24-hour expiry).
4. User proceeds directly to the Declared Preferences questionnaire
   (ref: `signals-v1.md — Step 0`) and then to the Spark screen.
5. After completing their first Spark session, a magic link is sent to their email:
   *"Activate your Synca account to save your compatibility results."*
6. User clicks the magic link → sets a display name → account upgraded to
   `account_type: :active`. A permanent JWT is issued.
7. If the user never clicks the magic link: guest record and all associated data
   are purged after 30 days.

### Guest account constraints

- Can complete Spark sessions
- Can answer the Declared Preferences questionnaire
- Can connect Apple Health / Health Connect
- Cannot send messages in a Circle (requires active account)
- Cannot receive algorithm-origin matches (requires active account + Premium)
- Cannot upload photos (requires active account)

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

### Premium Gating

None — guest onboarding is available to all users by definition.

### Open Questions

- Should the magic link be sent immediately after guest account creation, or only
  after the first Spark session completes?
- 30-day purge for inactive guests: is this compliant with GDPR right-to-erasure
  requirements if no explicit consent was collected at account creation?
- Should guests be able to view their own Lifestyle Profile before activating?

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

- Is email verification mandatory before accessing the app, or optional in MVP?
- Should `city` in `preference_profiles` be a FK to a future `city_configs` table
  or a free string in MVP?
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

- Is VK a priority for the Russian market in Step 2.0, or deferred to Step 2.1?
- Orphan account: user registers with Apple and later wants to add a password —
  what is the flow?
- Token revocation: if a user revokes access from Apple/Google, how is the active
  Synca session handled?

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
