# Synca — Product Vision

## The Problem

Modern dating apps are optimized for engagement, not outcomes. Endless swiping creates fatigue,
fake profiles erode trust, and surface-level matching (photos + one-liner) rarely predicts
real compatibility.

The result: users spend hours swiping and go on very few meaningful dates.

## The Hypothesis

Two people with aligned daily rhythms — sleep schedules, activity patterns, lifestyle habits —
are significantly more likely to enjoy spending time together than two people who only share
superficial interests.

Health data, read from Apple Health and Health Connect, provides an objective, hard-to-fake
window into those rhythms.

## The Solution

Synca is a dating app that uses aggregated health and lifestyle signals to generate **few,
high-quality matches** instead of an infinite swipe list.

Core principles:

- **Fewer matches, better quality.** Users receive 1–5 curated matches per day.
- **No raw health data exposed.** Only derived compatibility scores are shown.
- **Anti-swipe-fatigue by design.** Profiles that are clearly incompatible are silently excluded.
- **Trust first.** Every user has a TrustScore. Low-trust profiles are ranked down or gated.
- **Real dates as the goal.** The app guides matched users toward a structured date proposal.
- **IRL as the strongest signal.** Synca Spark lets two people meet in real life — at a gym,
  sauna, or run club — and instantly compute compatibility on the spot. It is the strongest
  liveness and trust signal in the system, and the primary acquisition mechanism at community
  events. Spark-origin matches carry the highest trust weight.
- **Algorithm as discovery.** A nightly matching job (origin: `algorithm`) analyses health
  summaries across the user base and surfaces suggested matches for users who have not yet met
  in person. Algorithm matches are a premium feature — they increase match volume from day one
  while preserving the quality bar.

## Two Match Origins

Synca supports two complementary paths to a match:

| Origin | Trigger | Trust level | Tier |
|---|---|---|---|
| `spark` | Verified in-person Spark session | Highest — IRL proof | Free |
| `algorithm` | Nightly `MatchingJob` on health data | Medium — behavioral inference | Premium |

Both origins produce the same `Match` object. The `origin` field is visible to the client
so the UI can label them differently (e.g. *"Synca confermata"* vs *"Synca suggerita"*).

## Target Users

Primary: adults 25–38, health-conscious, active lifestyle, tired of low-quality dating apps.

Geographic focus (in order):

1. Moscow — large market, vacuum left by Tinder/Bumble exit, Android-dominant.
2. Bangkok — high density of active singles, strong expat community, high fake-profile problem.
3. Dubai / Milan / Seoul — expansion cities in Year 2–3.

## Long-Term Vision

Build the first dating platform where compatibility is grounded in behavioral data, not just
self-reported preferences — and where every match has a real chance of becoming a real date.

Signal expansion roadmap:
- **v1**: Spotify music profile, travel behavior (Polarsteps / Maps)
- **v2**: Cross-signal validation, predictive compatibility modeling, outcome-based weight tuning.
  Introduction of **Sync Rooms** — group conversation spaces that can only be created when
  all members have verified Spark sessions with the creator. Three room types:
  - `duo` (2 members) — the standard 1-to-1 match chat
  - `small_group` (3–8 members) — friends, aperitivo, weekend plans; full Spark graph required
  - `event_room` (9–22 members) — calcetto, escape room, padel; each member needs ≥1 Spark with creator
- **v3+**: Predictive group compatibility engine — extend pairwise scores to model multi-user
  group cohesion. Broadens Synca's addressable market from dating into the wider social wellness
  category. No re-architecture required: individual compatibility profiles and `SparkSession`
  IRL data from earlier phases are the direct data foundation.
