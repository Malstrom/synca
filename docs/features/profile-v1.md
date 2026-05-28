# Feature: Profile
**Version:** 1.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1

---

## Overview

Profile covers the onboarding flow that a new user completes immediately after
registration, and the ongoing management of personal data, photos, and match
preferences. It is the prerequisite for Signals, Matching, and Spark.

The `profiles` table is introduced in `auth-v1.md`. This feature only extends it
and introduces `preference_profiles`.

-- ref: docs/features/auth-v1.md

---

## Step 1.0 — Onboarding + Preferences

**Phase:** 1
**Status:** Draft

### User Flow

After registration the user is redirected to a 4-step onboarding wizard.
No step can be skipped. The app stores progress locally and resumes from the
last completed step if the user quits mid-flow.

**Step 1 — Basic info**
- Display name (required, 2–40 chars)
- Date of birth (required, age ≥ 18 enforced)
- Gender (required): `man` | `woman` | `non_binary`
- City (required): selected from a predefined list

**Step 2 — Photos**
- Upload 1–6 photos (at least 1 required to complete onboarding)
- Each photo goes through image moderation before being stored
- Photos stored as an ordered JSON array in `profiles.photos`

**Step 3 — Bio**
- Free-text bio (optional, max 300 chars)

**Step 4 — Match preferences**
- Looking for: `man` | `woman` | `both`
- Age range: min/max (default: ±5 years from own age)
- Max distance: integer km (default: 25)

On completion `profiles.onboarding_completed` is set to `true` and the user
is admitted to the main app.

### DB Schema

Extensions to `profiles` (introduced in `auth-v1.md`):

```sql
-- ref: docs/features/auth-v1.md
-- Columns added to profiles in this feature:
ALTER TABLE profiles ADD COLUMN date_of_birth        date NOT NULL;
ALTER TABLE profiles ADD COLUMN gender               string NOT NULL;  -- 'man' | 'woman' | 'non_binary'
ALTER TABLE profiles ADD COLUMN city                 string NOT NULL;
ALTER TABLE profiles ADD COLUMN onboarding_completed boolean NOT NULL DEFAULT false;
```

New table introduced by this step:

```sql
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
| GET | `/api/v1/profile` | Yes | Returns own profile |
| PATCH | `/api/v1/profile` | Yes | Updates display_name, bio, city, gender, date_of_birth |
| POST | `/api/v1/profile/photos` | Yes | Uploads a photo, returns updated photos array |
| DELETE | `/api/v1/profile/photos/:index` | Yes | Removes photo at position index |
| GET | `/api/v1/profile/preferences` | Yes | Returns own preference_profile |
| PATCH | `/api/v1/profile/preferences` | Yes | Updates looking_for, age_min, age_max, max_distance_km |

Ref: `docs/api/openapi.yaml`

### Premium Gating

None — onboarding and preference management are available on all tiers.

### Open Questions

- Should `city` be a FK to a `city_configs` table (Phase 7) or a free string in MVP?
- Photo ordering: drag-and-drop on client only, or persisted server-side?
- Is a minimum of 1 photo enforced at the API level or only on the client?

---

## Step 2.0 — Profile Completeness Score

**Phase:** 2
**Status:** Planned

A `completeness_score` (0–100) is computed on the backend and exposed via
`GET /api/v1/profile`. It feeds into `trust_score` as one of its inputs.

-- ref: docs/features/trust-v1.md

Inputs and weights:

| Field | Weight |
|-------|--------|
| At least 1 photo | 20 |
| Bio present | 15 |
| Signals connected (≥1) | 25 |
| Phone verified | 20 |
| Age + gender + city set | 20 |

No new tables introduced in this step.

### API Endpoints

`GET /api/v1/profile` returns the existing response extended with:
```json
{ "completeness_score": 85 }
```

### Open Questions

- Should `completeness_score` be stored on the `profiles` table or computed
  on every request?
