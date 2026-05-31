# Synca — Go-to-Market Strategy
**Version:** 1.0
**Last updated:** May 2026
**Status:** Draft

---

## Overview

This document defines the GTM strategy for each product phase.
It is synchronized with `docs/product/roadmap.md` — each section below maps
directly to a product phase.

Positioning language and competitor framing: `docs/growth/positioning.md`.
Operational playbook for the Moscow launch: `docs/growth/playbooks/moscow-phase-0.md` *(planned)*.

> **Rule:** this document covers strategy and metrics.
> Operational details (scripts, venue lists, event calendar) live in `playbooks/`.

---

## Phase 0 — Validation MVP · Month 0–3

Ref: `docs/product/roadmap.md § Phase 0`, `docs/product/phases/phase-0.md`

### Goal

Prove that two people who do a Spark together want to meet again.
The success metric is not downloads — it is **re-encounters**: 5+ spontaneous
physical meetings between matched users within 30 days of a Spark session.

### Target

50 active users in Moscow. All recruited manually by the founder.
No paid acquisition. No public launch.

### Channels

| Channel | Mechanic | Expected output |
|---|---|---|
| **Founder network** | Founder presents Spark in person to friends, colleagues, community contacts | First 10–20 users |
| **Run clubs / gyms / sauna** | Founder attends 2–3 recurring sessions per week, demonstrates Spark on the spot | 20–40 additional users |
| **Spark QR virality** | Every Spark session generates a QR that can be scanned by someone without the app | Organic installs, zero ad spend |
| **Field research bot** | Structured interviews surface pain points and refine the hypothesis | Qualitative signal, not acquisition |

> Phase 0 acquisition is entirely founder-led. No marketing budget required.
> Every Spark is both a validation data point and a potential acquisition event.

### Key Metrics

| Metric | Target | Why it matters |
|---|---|---|
| Active users | 50 | Minimum viable signal pool |
| Completed Spark sessions | 20 | Core hypothesis validation |
| Re-encounter rate (30d) | ≥5 spontaneous meetings | Proof that Spark creates real-life value |
| Guest → active conversion | ≥60% | Measures magic link effectiveness |
| Health data connection rate | ≥70% | Measures willingness to share behavioral data |

### What is NOT done in Phase 0

- No social media presence
- No press outreach
- No paid ads
- No Android
- No public App Store listing (TestFlight only)

### Exit criteria

Phase 0 is complete when **all three** are true:
1. ≥20 completed Spark sessions
2. ≥5 documented re-encounters
3. ≥60% guest → active conversion

---

## Phase 1 — iOS MVP · Month 3–9

Ref: `docs/product/roadmap.md § Phase 1`

### Goal

Grow to 500 active users in Moscow. First public App Store presence.
Begin building a repeatable acquisition loop around Spark IRL in wellness venues.

### Channels

| Channel | Mechanic | Expected output |
|---|---|---|
| **App Store listing** | Public iOS release, ASO-optimized for Moscow | Organic search installs |
| **Wellness venue partnerships** | 3–5 gyms / run clubs with Synca QR codes at entrance or locker area | 50–100 installs per venue per month |
| **Founder content** | Short-form video on Telegram / VK showing real Spark sessions (with consent) | Brand awareness, inbound curiosity |
| **PR — tech angle** | Pitch to 2–3 Russian tech media (vc.ru, Habr, Techcrunch RU) | Credibility, backlinks, installs spike |
| **Referral** | In-app: "Share Spark" generates a named QR tracked back to the referrer | Viral coefficient measurement |

### Key Metrics

| Metric | Target | Why it matters |
|---|---|---|
| Active users (Moscow) | 500 | MVP traction threshold |
| Weekly Spark sessions | ≥50 | Algorithm matching needs data volume |
| D30 retention | ≥30% | Health signal quality requires sustained use |
| Organic referral rate | ≥20% of installs | Validates Spark QR as acquisition mechanic |
| Match → Circle message rate | ≥40% | Measures whether matches lead to real conversation |
| CAC | <₽500 (≋$6) | Benchmark for paid channel viability in Phase 2 |

### Positioning for Phase 1

Public message: **"The app that uses your Apple Health data to find people whose
life actually fits yours."**

Do not lead with "dating app" — lead with the health data angle.
It is the differentiator and the PR hook.

Ref: `docs/growth/positioning.md § For the press`

---

## Phase 2 — Android + Payments · Month 9–12

Ref: `docs/product/roadmap.md § Phase 2`

### Goal

First revenue. Android unlocks the Moscow market fully (Android-dominant city).
Target: ₽500k MRR by end of phase.

### Channels

| Channel | Mechanic | Expected output |
|---|---|---|
| **Android launch** | Play Store listing, ASO parity with iOS | 2× addressable market in Moscow |
| **Paid acquisition (test)** | Small budget (≋₽50k/month) on VK Ads and Telegram Ads targeting health/fitness interests | CAC benchmarking |
| **Premium launch PR** | "Synca launches paid tier — algorithm matching powered by health data" | Media coverage, conversion spike |
| **Venue partner expansion** | 10–20 venues across Moscow; co-branded Spark events | Sustained organic installs |
| **Telegram channel** | @SyncaApp — founder updates, product news, Spark stories | Owned audience, zero CAC |

### Key Metrics

| Metric | Target | Why it matters |
|---|---|---|
| MRR | ₽500k | First revenue milestone |
| Premium conversion | ≥5% of active users | Freemium benchmark |
| Android / iOS install split | ≥40% Android | Market penetration |
| Paid CAC | <₽1,000 | Threshold for scaling paid channels |
| LTV / CAC ratio | ≥3× | Unit economics viability |

---

## Phase 3 — Safety + Full Moments · Month 12–15

Ref: `docs/product/roadmap.md § Phase 3`

### Goal

Trust is now a marketing asset. Liveness verification and no-show reputation
become public-facing differentiators. Moments is the hook for press angle 2:
**"The app that doesn’t just match you — it gets you to actually meet."**

### Channels

| Channel | Mechanic | Expected output |
|---|---|---|
| **PR — safety angle** | "Synca introduces liveness verification for all users" | Trust-focused press, differentiates from fake-heavy competitors |
| **Moments launch content** | User stories: real couples / friends who met via Spark and completed a Moment | Social proof, conversion |
| **Venue Moment packs (preview)** | Partner venues offer discounts to Synca users who complete a Moment there | Retention, venue partnership depth |

---

## Phase 4–5 — Signal Expansion + Multi-city · Month 15–24

Ref: `docs/product/roadmap.md § Phase 4–5`

### Goal

Expand to Bangkok (Phase 4–5 target city). Music and travel signals unlock
a new PR angle and a broader user profile beyond health-obsessed early adopters.

### City expansion playbook

Each new city follows the same Phase 0 → Phase 1 loop:
1. Founder or local ambassador recruits first 50 users manually
2. Identifies 3–5 wellness venues for Spark QR deployment
3. Localized App Store listing in local language
4. 1–2 local press pitches (tech + lifestyle media)

Ref: `docs/growth/playbooks/` *(city-specific files planned)*

### Key Metrics (multi-city)

| Metric | Target |
|---|---|
| Active cities | 3 by Month 24 (Moscow, Bangkok, + 1 TBD) |
| Cross-city users (expats / travelers) | ≥5% of active base |
| MRR | ₽5M by Month 24 |

---

## Phase 6–7 — Group Compatibility + Social Wellness · Month 24+

Ref: `docs/product/roadmap.md § Phase 6–7`

### Goal

Reposition from dating-adjacent to **social wellness platform**.
Group Moments and venue Moment packs open a B2B revenue stream alongside the
existing B2C subscription.

### Channels

| Channel | Mechanic | Expected output |
|---|---|---|
| **Venue Moment packs** | Co-branded experiences (sauna morning, padel game, run) sold via the app | New revenue stream, brand awareness |
| **Wellness brand partnerships** | Co-marketing with gyms, run clubs, wellness apps already in users’ health stack | Distribution, credibility |
| **Group Spark events** | Synca-organized events in partner venues; ticketed or sponsored | Acquisition, press |

---

## Marketing Budget Principles

1. **Phase 0–1: zero paid acquisition.** Every ruble spent on ads in Phase 0 is a
   ruble not spent on learning. Organic Spark virality is the hypothesis to validate.
2. **Phase 2: test paid only after organic CAC is known.** Never start paid
   acquisition without a baseline organic CAC to benchmark against.
3. **Paid channels scale only when LTV/CAC ≥3×** is confirmed on organic cohorts.
4. **Venue partnerships are always preferred over ads** for the core user profile
   (health-active, 25–38). These users are already in gyms and run clubs —
   meet them there.

---

## References

- Product phases and success metrics: `docs/product/roadmap.md`
- User flows per phase: `docs/product/phases/`
- Positioning and messaging: `docs/growth/positioning.md`
- City playbooks (operational): `docs/growth/playbooks/` *(planned)*
- Financial model and ARPU targets: `docs/investor/`
