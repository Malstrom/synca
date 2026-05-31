# Feature: Circles
**Version:** 2.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1

---

## Overview

Circles are conversational and coordination spaces that exist only when a verified
physical compatibility exists between all members. A Circle is not a generic group
chat — it is proof that the people inside it have actually met and been compatible.

The canonical name is **Circle** (table: `circles`, channel: `CircleChannel`).
The term **"Sync Room" is deprecated** and must not appear anywhere.

Prerequisites: `users`, `profiles` (profile-v1.md) · `matches`, `sparks` (matching-v1.md, spark-v1.md).

---

## Steps

| Step | Phase | Status | Description |
|---|---|---|---|
| 1.0 — Duo Circle | 1 | Draft | 1:1 conversation space, created automatically on every match |
| 2.0 — Small Group and Event Circles | 4 | Planned | 3–8 and 9–22 member circles |

UX flows:
- Phase 1 → [phase-1.md — UF-09](../product/phases/phase-1.md#uf-09--duo-circle-creation-and-messaging)

---

## Business Rules

### Admission rules

| Circle type | Members | Admission rule |
|---|---|---|
| `duo` | 2 | Created automatically on match confirmation. Spark required for spark-origin; nil for algorithm-origin. |
| `small_group` | 3–8 | Every pair of members must have ≥1 confirmed Spark (full graph). Phase 4+. |
| `event` | 9–22 | Every member must have ≥1 confirmed Spark with the circle creator (hub-and-spoke). Phase 4+. |

### Duo Circle creation
- A Duo Circle is created automatically when a `Match` record is created,
  regardless of origin (`:spark` or `:algorithm`).
- For algorithm-origin matches, `spark_id` in `circle_memberships` is `nil`.

### Messaging
- Only active accounts (not guests) can send messages in a Circle.
- Real-time delivery via `CircleChannel` (Action Cable).
- Read receipts are tracked per-user per-message via `circle_message_reads`.
  This supports group circles from Phase 4 without schema changes.

### Small group and Event Circles (Phase 4)
- `POST /api/v1/circles` becomes available for manual creation.
- Group Moment proposals become available for these circle types
  (ref: `docs/features/moments-v1.md`).

---

## References

- DB Schema → [docs/architecture/db-schema.md § Circles](../architecture/db-schema.md#circles)
- API → `docs/api/openapi.yaml`
- Rails Model → [docs/conventions/backend.md § Domain Model](../conventions/backend.md#domain-model-rails-associations)
- Monetization → [docs/product/monetization.md](../product/monetization.md)

---

## Open Questions

See [docs/product/decisions.md](../product/decisions.md) — filter by `source: docs/features/circles-v1.md`.
