# Feature: Moments
**Version:** 2.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 3

> **Canonical name:** `Moments`.
> Table: `moments` · API: `/api/v1/moments` · Model: `Moment`.
> The term **"date_proposals" is deprecated** and must not appear anywhere.

---

## Overview

Moments is the feature that transforms a match into a real-world appointment.
It covers the full lifecycle of a meeting: proposal, negotiation, confirmation,
completion, and post-meeting rating.

A Moment can only be initiated between two users that share an active match.

Prerequisites: `matches` (matching-v1.md) · `trust_score` (trust-v1.md).

---

## Steps

| Step | Phase | Status | Description |
|---|---|---|---|
| 1.0 — Moment Proposal | 3 | Draft | Propose, accept, decline, counter-propose, complete, no-show |
| 2.0 — Reputation Signals from Moments | 4 | Planned | Completed moments and ratings feed TrustScore v1 |

UX flows:
- Phase 2 → [phase-2.md — UF-13](../product/phases/phase-2.md#uf-13--moment-proposal-basic-propose-accept-decline)

---

## Business Rules

### Proposal and negotiation
- A Moment can only be proposed between two users with an `active` match.
- Counter-proposal chain is capped at **5 rounds** to prevent infinite loops.
  Enforced server-side by counting the depth of the `parent_id` chain in
  `MomentProposalService`. Returns `422 Unprocessable Entity` when cap is exceeded.
  Counter-proposal data is retained for analytics and future ML models.

### Status transitions

| From | To | Trigger |
|---|---|---|
| `pending` | `confirmed` | Receiver accepts |
| `pending` | `declined` | Receiver declines |
| `pending` | `superseded` | Counter-proposal created |
| `confirmed` | `completed` | Either user marks as completed |
| `confirmed` | `no_show` | Either user reports a no-show |

### Ratings
- Ratings are private (1–5) and set on completion.
- Ratings feed into TrustScore v1 (ref: `docs/features/trust-v1.md § Step 3.0`).

### No-show
- The reporter is unaffected.
- The reported profile receives −15 to `trust_score`.

### Reputation signals (Step 2.0)
- Completed moments and ratings feed `TrustScore v1` as behavioral signals.
- Profiles with repeated no-shows surface a warning indicator in the match list.

---

## References

- DB Schema → [docs/architecture/db-schema.md § Moments](../architecture/db-schema.md#moments)
- API → `docs/api/openapi.yaml`
- Rails Model → [docs/conventions/backend.md § Domain Model](../conventions/backend.md#domain-model-rails-associations)
- Trust score inputs → [docs/features/trust-v1.md](trust-v1.md)
- Monetization → [docs/product/monetization.md](../product/monetization.md)

---

## Open Questions

See [docs/product/decisions.md](../product/decisions.md) — filter by `source: docs/features/moments-v1.md`.
