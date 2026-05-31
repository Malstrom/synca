# Synca — Monetization & Premium Gating

**Version:** 1.0  
**Last updated:** May 2026  
**Status:** Draft

This is the single source of truth for all premium gating decisions.
Feature docs must not contain monetization logic — they reference this file.

---

## Tiers

| Tier | Description |
|---|---|
| **Free** | Default for all users. Core features available. |
| **Premium** | Paid subscription. Unlocks advanced matching, unlimited Sparks, and extended features. |
| **Guest** | Pre-activation account. Subset of Free features until magic link is used. |

Pricing details: see `docs/investor/financial-model.md`.

---

## Feature Gating

| Feature | Step | Guest | Free | Premium | Notes |
|---|---|---|---|---|---|
| Guest onboarding | profile Step 0 | ✅ | ✅ | ✅ | Always available by definition |
| Spark sessions | spark Step 1.0 | ✅ | ✅ | ✅ | Core acquisition mechanic — never gated |
| Declared preferences | signals Step 0 | ✅ | ✅ | ✅ | Available from guest onboarding |
| Apple Health / Health Connect | signals Step 1.0 | ✅ | ✅ | ✅ | Free — more signals benefit everyone |
| Cycle signals | signals Step 1.1 | ❌ | ✅ | ✅ | Requires active account + explicit opt-in |
| Music signals | signals Step 2.0 | ❌ | ✅ | ✅ | Requires active account |
| Travel signals | signals Step 3.0 | ❌ | ✅ | ✅ | Requires active account |
| Signals summary (self-view) | signals user-facing | ❌ | ✅ | ✅ | Requires signals record |
| Full registration + profile | profile Step 1.0 | ❌ | ✅ | ✅ | Requires active account |
| Password recovery | profile Step 1.1 | ❌ | ✅ | ✅ | Active accounts only |
| Social login | profile Step 2.0 | ❌ | ✅ | ✅ | Phase 2 |
| Algorithm-origin matching | matching Step 1.0 | ❌ | ❌ | ✅ | Requires signals ≥ 7 days + premium |
| Spark-origin matching | matching Step 1.0 | ✅ | ✅ | ✅ | No premium required |
| Duo Circle (messaging) | circles Step 1.0 | ❌ | ✅ | ✅ | Active account required to send messages |
| Small group Circle | circles Step 2.0 | ❌ | ✅ | ✅ | Phase 4 |
| Event Circle | circles Step 2.0 | ❌ | ✅ | ✅ | Phase 4 |
| Moment proposals | moments Step 1.0 | ❌ | ✅ | ✅ | Requires active match |
| Phone verification | trust Step 1.0 | ❌ | ✅ | ✅ | Free for all active accounts |
| Reporting | trust Step 1.0 | ❌ | ✅ | ✅ | Free for all active accounts |
| Liveness check | trust Step 2.0 | ❌ | ✅ | ✅ | Phase 4 |
| Push + in-app notifications | notifications Step 1.0 | ❌ | ✅ | ✅ | Active account required |
| Telegram notifications | notifications Step 1.0 | ❌ | ✅ | ✅ | Opt-in, all tiers |
| Group Spark | spark Step 2.0 | ❌ | ✅ | ✅ | Phase 2 |

---

## Spark Rewards

Rewards are issued automatically on Spark completion. They are not a gating
mechanism — they are a conversion and retention tool.

| Reward | Recipient | Trigger |
|---|---|---|
| `premium_week` trial | Free users | Complete any Spark |
| `match_credit` | Premium users | Complete any Spark |
| `low_score_bonus` | Any user | Spark produces low compatibility score (threshold TBD — see `decisions.md`) |

Ref: `docs/features/spark-v1.md` — Step 1.0.

---

## Open Questions

See [docs/product/decisions.md](decisions.md) — filter by `source: docs/product/monetization.md`.
