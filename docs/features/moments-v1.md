# Feature: Moments
**Version:** 1.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 3
**User flows:** `docs/product/phases/` — no flows in Phase 0–2; flows will be added in phase-3.md

> **Canonical name:** `Moments`.
> The DB table is `moments`, the API resource is `/api/v1/moments`,
> and the Rails model is `Moment`.
> The term **"date_proposals"** is **deprecated** and must not appear anywhere
> in code, migrations, API paths, UI copy, or documentation.

---

## Overview

Moments is the feature that transforms a match into a real-world appointment.
It covers the full lifecycle of a meeting: proposal, negotiation, confirmation,
completion, and post-meeting rating.

A Moment can only be initiated between two profiles that share an active match.

-- ref: docs/features/matching-v1.md
-- ref: docs/features/trust-v1.md

---

## Step 1.0 — Moment Proposal

**Phase:** 3
**Status:** Draft

### User Flow

**Step 1 — Propose**
1. User A opens a match and taps “Propose a meeting”.
2. Fills in: location (free text), date, time.
3. Backend creates a `Moment` with `status: pending` and notifies User B.

**Step 2 — Respond**
User B can:
- **Accept** → `status` becomes `confirmed`. Both users receive a confirmation notification.
- **Decline** → `status` becomes `declined`. No further action.
- **Counter-propose** → creates a new `Moment` linked via `parent_id`,
  original becomes `superseded`. User A is notified and can accept, decline, or
  counter again.

Counter-proposal chain is capped at 5 rounds to prevent infinite loops.

**Step 3 — Complete + Rate**
After the scheduled date/time has passed, both users are prompted to mark the moment:
- **Completed** → `status` becomes `completed`. Each user submits a rating (1–5 stars).
- **No-show** → `status` becomes `no_show`. The reporter is unaffected;
  the no-show profile receives `−15` to `trust_score`.

Ratings are private and feed into `TrustScore v1`.

-- ref: docs/features/trust-v1.md

### DB Schema

```sql
-- Canonical table name: moments
moments
  id               bigint PK
  proposer_id      bigint FK -> profiles NOT NULL
  receiver_id      bigint FK -> profiles NOT NULL
  match_id         bigint FK -> matches NOT NULL
  parent_id        bigint FK -> moments           -- set on counter-proposals
  location         string NOT NULL
  scheduled_at     datetime NOT NULL
  status           string NOT NULL DEFAULT 'pending'
                   -- 'pending' | 'confirmed' | 'declined' | 'superseded'
                   -- 'completed' | 'no_show'
  proposer_rating  integer                        -- 1-5, set on completion
  receiver_rating  integer                        -- 1-5, set on completion
  completed_at     datetime
  created_at       datetime
  updated_at       datetime
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/moments` | Yes | Creates a new moment proposal |
| GET | `/api/v1/moments` | Yes | Lists own moments (all statuses) |
| GET | `/api/v1/moments/:id` | Yes | Returns a single moment |
| PATCH | `/api/v1/moments/:id/accept` | Yes | Accepts a pending proposal |
| PATCH | `/api/v1/moments/:id/decline` | Yes | Declines a pending proposal |
| POST | `/api/v1/moments/:id/counter` | Yes | Creates a counter-proposal |
| PATCH | `/api/v1/moments/:id/complete` | Yes | Marks moment as completed and submits rating |
| PATCH | `/api/v1/moments/:id/no_show` | Yes | Reports a no-show |

Ref: `docs/api/openapi.yaml`

### Premium Gating

None — moment proposals are available on all tiers.

### Open Questions

- Should `location` be a free-text field only, or should we integrate a maps API
  for structured venue selection?
- Is the 5-round counter-proposal cap enforced server-side or client-side only?
- Should ratings be visible to the rated user or remain fully private?

---

## Step 2.0 — Reputation Signals from Moments

**Phase:** 4
**Status:** Planned

Completed moments and ratings feed into `TrustScore v1` as behavioral signals.
No-show events are surfaced in the match list as a warning indicator for
profiles with repeated no-shows.

No new tables introduced in this step.

-- ref: docs/features/trust-v1.md

### Open Questions

- After how many confirmed no-shows should a profile be automatically suspended?
- Should positive ratings unlock any in-app reward or badge?
