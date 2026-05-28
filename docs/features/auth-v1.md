# Feature: Auth
**Version:** 1.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1

---

## Overview

Auth handles user registration, login, and session management across iOS, Android,
and future web clients. It is the prerequisite for every other feature — no other
feature is accessible without a verified account.

Authentication uses `has_secure_password` (bcrypt) + JWT. No dependency on Devise
or Warden. The JWT token is stored in the iOS Keychain and Android
EncryptedSharedPreferences — never in unencrypted storage.

---

## Step 1.0 — Email + Password

**Phase:** 1
**Status:** Draft

### User Flow

1. User opens the app for the first time.
2. Selects "Sign up".
3. Enters email + password (minimum 8 characters).
4. Backend creates `User` + `Profile`, returns a JWT.
5. JWT saved to Keychain (iOS) / EncryptedSharedPreferences (Android).
6. User redirected to the **Profile** onboarding flow.

Subsequent login:
1. User enters email + password.
2. Backend validates credentials, returns a new JWT.
3. App updates the token in Keychain.

Token expiry: 30 days. No refresh token in Step 1.0.

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
  photos                 jsonb DEFAULT '[]'
  trust_score            float NOT NULL DEFAULT 50.0
  spark_verified         boolean NOT NULL DEFAULT false
  irl_verification_count integer NOT NULL DEFAULT 0
  premium                boolean NOT NULL DEFAULT false
  created_at             datetime
  updated_at             datetime
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/auth/register` | No | Creates `User` + `Profile`, returns JWT |
| POST | `/api/v1/auth/login` | No | Validates credentials, returns JWT |
| GET | `/api/v1/auth/me` | Yes | Returns the current user from JWT |
| DELETE | `/api/v1/auth/logout` | Yes | Invalidates the session on the client side |

Ref: `docs/api/openapi.yaml`

JWT payload: `{ user_id: integer, exp: unix_timestamp }`
All protected endpoints require: `Authorization: Bearer <token>`

### Premium Gating

None — registration and login are entirely free.

### Open Questions

- Add refresh token in Step 1.0 or defer to Step 2.0?
- Should JWT expiry be configurable per city (e.g. markets with different regulations)?
- Is email verification mandatory before accessing the app, or optional in MVP?

---

## Step 2.0 — Social Login

**Phase:** 2
**Status:** Planned

### User Flow

1. User selects "Continue with Apple" / "Continue with Google" / "Continue with VK".
2. The provider returns an OAuth token to the client.
3. Client sends the token to the backend (`POST /api/v1/auth/social`).
4. Backend verifies the token with the provider, finds or creates `User` + `Profile`.
5. Returns a Synca JWT. Flow is identical to Step 1.0 from this point on.

If the provider email matches an existing email account, the two accounts are
linked automatically via `identity_providers`.

### DB Schema

```sql
users
  id              bigint PK
  email           string UNIQUE          -- nullable for social-only accounts
  password_digest string                 -- nullable for social-only accounts
  created_at      datetime
  updated_at      datetime

profiles
  id                     bigint PK
  user_id                bigint FK -> users NOT NULL
  display_name           string
  bio                    text
  photos                 jsonb DEFAULT '[]'
  trust_score            float NOT NULL DEFAULT 50.0
  spark_verified         boolean NOT NULL DEFAULT false
  irl_verification_count integer NOT NULL DEFAULT 0
  premium                boolean NOT NULL DEFAULT false
  created_at             datetime
  updated_at             datetime

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
| POST | `/api/v1/auth/register` | No | Unchanged from Step 1.0 |
| POST | `/api/v1/auth/login` | No | Unchanged from Step 1.0 |
| POST | `/api/v1/auth/social` | No | Verifies OAuth token, returns Synca JWT |
| GET | `/api/v1/auth/me` | Yes | Unchanged from Step 1.0 |
| DELETE | `/api/v1/auth/logout` | Yes | Unchanged from Step 1.0 |

Ref: `docs/api/openapi.yaml`

### Premium Gating

None — social login is available on all tiers.

### Open Questions

- Is VK a priority for the Russian market — implement in Step 2.0 or in a
  separate Step 2.1 after Apple and Google?
- Orphan account handling: if a user registers with Apple and later wants to
  add a password, what does that flow look like?
- Token revocation: if a user revokes access from Apple/Google, how is the
  active Synca session handled?
