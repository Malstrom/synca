# Synca — Product Vision

## The Problem

Modern dating apps are optimised for engagement, not outcomes. Endless swiping creates
fatigue, fake profiles erode trust, and surface-level matching (photos + one-liner) rarely
predicts real compatibility.

But the deeper problem is invisible until it is too late: **behavioural frictions that emerge
over time**. Two people can enjoy a first date and still be fundamentally misaligned in the
ways that matter most for sustained connection — when they sleep, how active they actually
are, whether they need silence in the morning or noise at night. These frictions do not show
up on a profile. They show up after weeks or months of spending time together.

Representative examples include sleep schedule mismatch in relationships, sleeping temperature
conflicts during travel, large gaps between perceived and actual activity level, and early-bird
vs night-owl energy mismatch. None of these can be detected from a photo or a self-written bio.
See [`user-research.md`](./user-research.md) and [`../research/`](../research/) for the full case studies and field research materials.

## The Hypothesis

Two people with aligned daily rhythms — sleep schedules, activity patterns, lifestyle
habits — are significantly more likely to enjoy spending time together than two people
who only share superficial interests.

This compatibility is not immediately visible. It reveals itself over time, through the
accumulation of small moments of friction or ease. Synca’s hypothesis is that **behavioural
data, collected passively, is a better early signal of this alignment than anything a person
chooses to write about themselves**.

Critically, compatibility is not binary and it is not static. Two people do not need to be
aligned on everything — they need to be aligned on the dimensions that matter most to each
of them. This is why Synca combines two layers:

- **Objective signals**: what the data shows you actually do — your real sleep onset, your
  real step count, your real energy peaks. Hard to fake, consistent over time.
- **Declared preferences**: what you tell us matters to you — whether you need to fall
  asleep with someone next to you, whether you run cold or hot, how much daily movement
  feels right to your body. These are not filters; they are weights that personalise how
  objective signals are interpreted.

A night owl who does not care about falling asleep together is compatible with an early bird
in ways that a night owl who cannot sleep without their partner is not.

## The Solution

Synca is not a dating app in the conventional sense. It is a **lifestyle compatibility
platform** — a new way to find people whose lives align with yours, whatever that
alignment will become over time. A romantic relationship, a close friendship, a running
group, a travel companion. The app does not decide what the connection should be. It finds
the people with whom connection is most likely to feel natural.

The entry point is familiar: Synca uses the Tinder frame as a communication hook because
every adult understands it immediately. But the underlying logic is fundamentally different.
Tinder optimises for volume. Synca optimises for alignment.

Core principles:

- **Fewer connections, better quality.** Users receive at most 1–3 curated matches per nightly algorithm run. Scarcity is a product value, not a constraint.
- **Objective data over self-presentation.** Behavioural signals are collected passively
  from Apple Health, Health Connect, music streaming services, and location history.
  Raw data never leaves the device.
- **Declared preferences as personalisation layer.** A short preference questionnaire
  captures what each user considers non-negotiable or important — these weights shape
  how objective signals are interpreted, without replacing them.
- **No raw data exposed.** Only derived compatibility scores and plain-language
  explanations are shown to users.
- **Anti-swipe-fatigue by design.** Profiles that are clearly incompatible are silently excluded.
- **Trust first.** Every user has a TrustScore. Low-trust profiles are ranked down or gated.
  See [`trust-v1.md`](../features/trust-v1.md).
- **Meaningful time together as the goal.** The app guides matched users toward a structured
  Moment — a meeting proposal with venue, time, and mutual acceptance. A Moment is not
  necessarily a romantic date; it is a first shared experience. See [`moments-v1.md`](../features/moments-v1.md).
- **IRL as the strongest signal.** Spark lets two people meet in real life — at a gym,
  sauna, or run club — and instantly compute compatibility on the spot. It is the strongest
  liveness and trust signal in the system, and the primary acquisition mechanism at
  community events. Spark-origin matches carry the highest trust weight.
  See [`spark-v1.md`](../features/spark-v1.md).
- **Algorithm as discovery.** A nightly `MatchingJob` (origin: `algorithm`) analyses
  signals across the user base and surfaces suggested matches.
  See [`matching-v1.md`](../features/matching-v1.md).

## Two Match Origins

Synca supports two complementary paths to a match:

| Origin | Trigger | Trust level |
|---|---|---|
| `spark` | Verified in-person Spark session | Highest — IRL proof |
| `algorithm` | Nightly `MatchingJob` on behavioral signals | Medium — behavioral inference |

Both origins produce the same `Match` object. The `origin` field is visible to the client
so the UI can label them differently (*“Synca confirmed”* vs *“Synca suggested”*).

## Target Users

Primary: adults 25–38, health-conscious, active lifestyle, tired of low-quality apps,
who have experienced at least once the friction of discovering incompatibility too late.

Geographic focus (in order):

1. Moscow — large market, vacuum left by Tinder/Bumble exit, Android-dominant.
2. Bangkok — high density of active singles, strong expat community, high fake-profile problem.
3. Dubai / Milan / Seoul — expansion cities in Year 2–3.

## Signal Architecture

Compatibility in Synca is built from two complementary layers that together produce a
personalised alignment score.

### Layer A — Objective Behavioral Signals

Passively collected data that reflects how a person actually lives. Cannot be gamed
without sustained behavioral change over weeks.

#### Phase 1 — Health Rhythms

Apple Health (iOS) and Health Connect (Android) provide:

- Sleep onset and offset times, duration, variability, chronotype, social jetlag
- Activity minutes, resting heart rate, step count, peak activity window
- Routine stability index — how consistent a person’s daily schedule is
- Recovery quality (HRV when available)

Two people whose sleep schedules, activity windows, and routine stability align are
more likely to actually enjoy spending time together. This is the core signal.

See [`signals-v1.md — Step 1.0`](../features/signals-v1.md).

#### Phase 2 — Music Taste

Music listening patterns reveal personality dimensions that health data does not capture:
energy level, emotional range, and cultural affinity.

Synca integrates with **Spotify** and **Yandex Music** to derive:

- Top genres weighted by listening time
- Audio energy and valence averages
- Peak listening time-of-day window

See [`signals-v1.md — Step 2.0`](../features/signals-v1.md).

#### Phase 3 — Travel Behavior

Travel patterns reveal how adventurous, spontaneous, or routine-oriented a person is.

Synca integrates with **Polarsteps** and device location history to derive:

- Average trips per year and typical trip duration
- Travel style: `city` | `nature` | `mixed`
- Preferred regions

See [`signals-v1.md — Step 3.0`](../features/signals-v1.md).

### Layer B — Declared Preferences

A short questionnaire completed during onboarding. These are not dealbreaker filters —
they are personalisation weights that shape how objective signals are interpreted.

Examples:
- *“Is it important to you to fall asleep at the same time as your partner?”*
  → weights sleep onset alignment more heavily for this user
- *“Do you prefer sleeping in a cool or warm environment?”*
  → used as a compatibility dimension for close-contact scenarios
- *“How much daily movement feels right for you?”*
  → calibrates step count similarity threshold
- *“How important is it that your energy rhythms match the people around you?”*
  → global weight on chronotype alignment

See [`signals-v1.md — Step 0`](../features/signals-v1.md) and [`user-research.md`](./user-research.md).

## Long-Term Vision

Build the first platform where compatibility is grounded in behavioral data, not
self-reported preferences — and where every connection has a real chance of becoming
something meaningful, whatever form that takes.

### Circles — Spaces That Require Physical Proof

As the Spark graph grows, it becomes possible to create **Circles**: group conversation
spaces that exist only if a verified physical compatibility exists between all members.
A Circle is not a generic group chat — it is proof that the people inside it have
actually met and been compatible.

Three Circle types, gated by Spark history:

| Type | Members | Admission rule |
|------|---------|----------------|
| `duo` | 2 | 1 confirmed Spark between the two (every match, from Phase 1) |
| `small_group` | 3–8 | Full Spark graph: every pair ≥1 Spark (Phase 4+) |
| `event` | 9–22 | Every member ≥1 Spark with the creator (Phase 4+) |

Different Circle types require different depths of alignment. A duo Circle between
two potential romantic partners benefits from tight sleep and routine alignment.
An event Circle for a padel game needs only overlapping energy windows and similar
activity levels — the full lifestyle score is not the right lens for a Sunday match.

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
