# Synca — Product Vision

## The Problem

Modern dating apps are optimised for engagement, not outcomes. Endless swiping creates
fatigue, fake profiles erode trust, and surface-level matching (photos + one-liner) rarely
predicts real compatibility.

The result: users spend hours swiping and go on very few meaningful dates.

## The Hypothesis

Two people with aligned daily rhythms — sleep schedules, activity patterns, lifestyle habits —
are significantly more likely to enjoy spending time together than two people who only share
superficial interests.

Behavioral data, collected passively from Apple Health, Health Connect, music streaming
services, and location history, provides an objective, hard-to-fake window into those rhythms.

## The Solution

Synca is a dating app that uses aggregated behavioral signals to generate **few, high-quality
matches** instead of an infinite swipe list.

Core principles:

- **Fewer matches, better quality.** Users receive 1–5 curated matches per day.
- **No raw data exposed.** Only derived compatibility scores and plain-language explanations
  are shown to users. Raw health, music, and travel data never leaves the device.
- **Anti-swipe-fatigue by design.** Profiles that are clearly incompatible are silently excluded.
- **Trust first.** Every user has a TrustScore. Low-trust profiles are ranked down or gated.
  See [`trust-v1.md`](../features/trust-v1.md).
- **Real dates as the goal.** The app guides matched users toward a structured Moment — a
  date proposal with venue, time, and mutual acceptance. See [`moments-v1.md`](../features/moments-v1.md).
- **IRL as the strongest signal.** Spark lets two people meet in real life — at a gym, sauna,
  or run club — and instantly compute compatibility on the spot. It is the strongest liveness
  and trust signal in the system, and the primary acquisition mechanism at community events.
  Spark-origin matches carry the highest trust weight. See [`spark-v1.md`](../features/spark-v1.md).
- **Algorithm as discovery.** A nightly `MatchingJob` (origin: `algorithm`) analyses signals
  across the user base and surfaces suggested matches. Algorithm matches are premium — they
  increase match volume while preserving the quality bar. See [`matching-v1.md`](../features/matching-v1.md).

## Two Match Origins

Synca supports two complementary paths to a match:

| Origin | Trigger | Trust level | Tier |
|---|---|---|---|
| `spark` | Verified in-person Spark session | Highest — IRL proof | Free |
| `algorithm` | Nightly `MatchingJob` on behavioral signals | Medium — behavioral inference | Premium |

Both origins produce the same `Match` object. The `origin` field is visible to the client
so the UI can label them differently (*"Synca confirmed"* vs *"Synca suggested"*).

## Target Users

Primary: adults 25–38, health-conscious, active lifestyle, tired of low-quality dating apps.

Geographic focus (in order):

1. Moscow — large market, vacuum left by Tinder/Bumble exit, Android-dominant.
2. Bangkok — high density of active singles, strong expat community, high fake-profile problem.
3. Dubai / Milan / Seoul — expansion cities in Year 2–3.

## Signal Evolution

Compatibility in Synca is not static. The model deepens as each new signal source is
integrated, always without exposing raw data to other users.

### Phase 1 — Health Rhythms

The foundation. Apple Health (iOS) and Health Connect (Android) provide:

- Sleep duration, variability, chronotype, social jetlag
- Activity minutes, resting heart rate, step count, peak activity window
- Routine stability index — how consistent a person's daily schedule is

Two people whose sleep schedules, activity windows, and routine stability align are
more likely to actually enjoy spending time together. This is the core hypothesis.

See [`signals-v1.md — Step 1.0`](../features/signals-v1.md).

### Phase 2 — Music Taste

Music listening patterns reveal personality dimensions that health data does not capture:
energy level, emotional range, and cultural affinity.

Synca integrates with **Spotify** and **Yandex Music** to derive:

- Top genres weighted by listening time
- Audio energy and valence averages
- Peak listening time-of-day window

Music taste is added as a sub-signal within the Lifestyle compatibility domain — it
enriches existing matches without replacing health data as the primary signal.

See [`signals-v1.md — Step 2.0`](../features/signals-v1.md).

### Phase 3 — Travel Behavior

Travel patterns reveal how adventurous, spontaneous, or routine-oriented a person is —
qualities that are hard to self-report honestly but easy to infer from behavior.

Synca integrates with **Polarsteps** and device location history to derive:

- Average trips per year and typical trip duration
- Travel style: `city` | `nature` | `mixed`
- Preferred regions

All aggregation happens on-device. Only derived metrics are sent to the backend.
Travel behavior is added as a sub-signal within the Lifestyle compatibility domain.

See [`signals-v1.md — Step 3.0`](../features/signals-v1.md).

## Long-Term Vision

Build the first dating platform where compatibility is grounded in behavioral data, not
self-reported preferences — and where every match has a real chance of becoming a real date.

### Circles — Spaces That Require Physical Proof

As the Spark graph grows, it becomes possible to create **Circles**: group conversation
spaces that exist only if a verified physical compatibility exists between all members.
A Circle is not a generic group chat — it is proof that the people inside it have
actually met and been compatible.

Three Circle types, gated by Spark history:

| Type | Members | Admission rule |
|------|---------|----------------|
| `duo` | 2 | 1 confirmed Spark between the two (every match) |
| `small_group` | 3–8 | Full Spark graph: every pair ≥1 Spark |
| `event` | 9–22 | Every member ≥1 Spark with the creator |

See [`circles-v1.md`](../features/circles-v1.md).

### Group Compatibility Engine

The long-term ambition is to extend pairwise compatibility scores to model **group
cohesion** — predicting not just whether two people are compatible, but whether a
specific group of people will enjoy spending time together.

This unlocks:

- **Group Moments**: curated activity proposals (morning runs, sauna sessions, padel
  games) suggested to a Circle based on lifestyle alignment across all members.
- **Group Moment packs**: a monetization surface co-branded with venue partners.
- A broadened addressable market from dating into the wider **social wellness** category.

No re-architecture is required. Individual compatibility profiles and Spark IRL data
from earlier phases are the direct data foundation for group scoring.

See [`spark-v1.md — Step 2.0`](../features/spark-v1.md) and [`moments-v1.md`](../features/moments-v1.md).
