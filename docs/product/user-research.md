# User Research

**Version:** 1.0  
**Last updated:** May 2026  
**Status:** Draft

---

## Purpose

This document is the canonical source of truth for the qualitative user research
that informs Synca's product direction.

Its goal is not to describe implementation details, schemas, or APIs. Its goal is
to capture the real human frictions that existing dating and social apps fail to
see — especially the behavioral mismatches that emerge only after people start
spending real time together.

All product, feature, and investor documents should reference this file instead
of duplicating case studies inline.

---

## Research Status

As of May 2026, this document contains the initial set of qualitative observations
and concrete cases collected before Phase 0 development.

This is an early research base, not a finished research program. The next iteration
should add:
- Direct user quotes
- Interview count and date range
- Source context for each case (relationship, friendship, travel, fitness, etc.)
- Validation results from Phase 0 users after real Spark sessions

---

## Core Observations

### 1. Compatibility problems often appear too late

Most people can detect attraction, conversation quality, and surface-level interests
on a first date. What they cannot detect reliably is whether daily life will feel
easier or harder with the other person over time.

The mismatches that matter most are often small, repetitive, and behavioral:
- Sleep timing
- Energy windows
- Temperature preferences
- Activity intensity
- Routine rigidity vs flexibility

These are rarely visible on a profile and are almost never measured by existing apps.

### 2. Self-description is too weak to model lived compatibility

When people describe themselves, they usually describe identity, aspiration, or
self-image — not repeated daily behavior.

Examples:
- "I love walking" can mean 3,000 steps or 20,000 steps.
- "I'm flexible" can hide a very rigid morning routine.
- "I'm a night owl" may matter a lot to one person and very little to another.

This is why Synca needs both objective signals and declared preferences.

### 3. The meaning of a mismatch depends on the person

The same behavioral difference can be irrelevant for one person and decisive for
another.

A chronotype mismatch is not automatically bad. It becomes important when the user
cares deeply about shared evenings, shared bedtime, or aligned energy windows.
This is why the product cannot rely only on passive data — it also needs a
personalization layer that captures what each user values.

---

## Case Studies

### Case 1 — Sleep schedule mismatch in a relationship

One partner goes to bed at 23:00 and the other at 02:00. Over time, the shared
evening — the period where both are awake, relaxed, and emotionally available —
shrinks to less than an hour.

The early sleeper has only two options:
- Wait up and damage their sleep quality
- Go to bed alone every night

Neither option is dramatic on day one. Both become corrosive over time.

**Product implication:** sleep alignment is not just a health metric. It can be a
relationship-quality predictor when the user values shared evenings or shared sleep timing.

### Case 2 — Sleeping temperature conflict during travel

Two close friends share a hotel room during a trip. One cannot sleep without air
conditioning. The other gets cold easily and cannot sleep with strong cold airflow.

This conflict is invisible before the trip and difficult to resolve once it has
started. After two or three nights, one of them is sleep-deprived and the shared
experience degrades.

**Product implication:** compatibility should not be reduced to attraction or hobby
similarity. Physical comfort preferences matter in close-contact contexts.

### Case 3 — Perceived vs actual activity level

Two people both say they love walking. For one person, this means a light daily
walk of about 30 minutes. For the other, it means a long, physically demanding
outing that easily reaches 20,000 steps.

On paper, they sound similar. In lived experience, they organise their days very
differently.

**Product implication:** self-description is insufficient. Objective activity signals
should capture actual lifestyle intensity, while a short preference question should
help calibrate what "active enough" means to each user.

### Case 4 — Early bird vs night owl energy mismatch

One person is naturally alert and sociable late in the evening. The other starts
shutting down mentally by 21:30.

This affects more than bedtime. It changes when dinner happens, whether a late walk
feels enjoyable, how much emotional energy remains for conversation, and whether the
pair actually experiences leisure time together.

**Product implication:** energy-window compatibility should be modeled as a meaningful
part of real-world alignment, not as a cosmetic personality trait.

---

## Product Implications

The research above supports five product decisions.

### 1. Objective signals must be first-class

Health, activity, recovery, and routine data provide a better baseline than bios or
self-descriptions for modeling lived compatibility.

### 2. Declared preferences are a required interpretation layer

Behavioral data answers: "What does this person actually do?"  
Declared preferences answer: "Which differences matter to this person?"

Without the second layer, the scoring model risks over-penalizing harmless differences
or underestimating important ones.

### 3. Synca should optimize for quality of time together

The goal is not just to create matches. The goal is to increase the probability that
spending time together will feel natural, easy, and repeatable.

### 4. Spark is a valid validation mechanic

Spark is not only an acquisition tool. It is a research tool that creates real-world
moments where compatibility can be observed, discussed, and later compared with the
model's prediction.

### 5. The product should remain broader than classic dating

The same frictions appear in romantic relationships, friendships, travel pairings,
fitness communities, and small social groups.

This supports the positioning of Synca as a lifestyle compatibility platform rather
than a narrow swipe-based dating app.

---

## Phase 0 Validation Questions

| Question | Why it matters |
|---|---|
| Do users recognize themselves in the Lifestyle Profile? | Validates that the signal model feels legible and credible |
| Do users agree that the declared preference questions are meaningful? | Validates the personalization layer |
| After a Spark session, do users say the result "felt right"? | Tests intuitive trust in the compatibility snapshot |
| Which mismatches do users say matter most in real life? | Helps prioritize future questions and score weights |
| Are users willing to connect health data before receiving a match? | Tests onboarding friction vs perceived value |

---

## Referenced By

- [`docs/product/vision.md`](./vision.md)
- [`docs/features/signals-v1.md`](../features/signals-v1.md)
- `docs/investor/litepaper.md` (planned)
- `docs/investor/technical-whitepaper.md` (planned)
