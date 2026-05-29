# Synca Litepaper

**Version 1.5 — May 2026**
*Confidential — For Investor and Partner Use Only*

---

## 1. Vision

The way people meet has not fundamentally changed in ten years. The swipe interface, introduced by Tinder in 2012, became the default interaction model for an entire generation. It optimized for one thing: volume. More swipes, more matches, more engagement time. What it did not optimize for — and structurally cannot — is compatibility.

Synca starts as a dating app. But read to the end: the compatibility engine Synca is building is not limited to romantic connections. The same passive behavioral data that reveals whether two people are romantically aligned also reveals whether eight people are the right fit for a weekly padel group, a calcetto team, or a Saturday morning trail run. Dating is the point of entry. **Lifestyle compatibility is the category.**

---

## 2. The Problem

### 2.1 Swipe Fatigue Is Structural, Not Cyclical

Dating app burnout is not a passing trend. It is the inevitable output of a system designed to maximize session length rather than successful outcomes. Nearly 79% of Gen Z users report emotional exhaustion from dating apps. Bumble lost 19% of its downloads in 2024 alone. Social sentiment around dating apps is net negative: 27% of mentions are negative versus 16% positive.

The apps know this. Hinge's entire brand proposition — "designed to be deleted" — is an implicit admission that the swipe model fails users. Yet even Hinge's core mechanic is still profile browsing. The format has been reframed but not replaced.

### 2.2 Self-Reported Data Is Broken by Design

Every current matching system is ultimately trained on what users say about themselves, not on how they behave. This creates three compounding problems:

- **Presentation bias**: people optimize their profiles for attractiveness, not accuracy.
- **Static snapshots**: a profile captures one moment and does not update as the person's life changes.
- **Absence of behavioral data**: nobody accurately describes their actual sleep schedule, energy patterns, or weekly calorie burn during sport.

### 2.3 The Fake and Escort Problem

On platforms operating in Bangkok, Dubai, Moscow, and similar urban markets, a significant portion of female profiles are not genuine users seeking relationships. They are either professional escorts, accounts managed by third-party agencies, or outright fakes. The result is a broken trust environment that degrades the experience for all authentic users.

### 2.4 The Post-Match Failure

Even when a genuine match occurs, the majority fail to convert into a real meeting. Neither person knows how to break the conversational ice, no one wants to be the first to propose something specific, and the logistics of finding a mutually convenient time and place become an obstacle. Most matches end in silence within 48 hours.

---

## 3. The Synca Approach

Synca replaces the swipe model with a **lifestyle compatibility engine** that works passively in the background, proposes a match only when conditions are genuinely aligned, and immediately bridges that match to a real-world meeting.

### 3.1 From Profiles to Behavioral Signals

Synca does not ask users to describe themselves. It reads what they actually do — collected passively every day from their phone and wearable:

- When they fall asleep and wake up, and how consistent that schedule is across days
- How active they are: average daily step count, weekly active minutes, calorie burn during workouts
- When their energy peaks: morning, midday, or evening
- How they recover: resting heart rate trends, heart rate variability
- What music they listen to, when, and what energy and emotional tone it carries
- How often they travel, how far, and whether they seek novelty or familiarity

This data cannot be gamed without sustaining behavioral change over weeks. It is not a snapshot — it is a fingerprint.

### 3.2 Declared Preferences: The Interpretation Key

Objective signals tell Synca what a person *does*. A short onboarding questionnaire — under 2 minutes — tells Synca what a person *values*. The combination is more predictive than either alone.

Two people with different wake-up times may be perfectly compatible if neither considers sleeping at the same hour important. Two people with identical chronotypes may clash if one needs complete silence in the morning. The declared preference is what unlocks that distinction.

Examples from the onboarding questionnaire:

- *Is it important to you to fall asleep at roughly the same time as your partner?* (1–5 scale)
- *Do you prefer sleeping in a cool or warm environment?* (Cool / Warm / No preference)
- *How much daily movement feels right for you?* (Under 3,000 steps / 3,000–8,000 / Over 10,000)
- *How many calories do you typically burn during a sport session?* (Under 300 kcal / 300–600 kcal / Over 600 kcal)
- *Do you play team sports like calcetto, padel, or basketball? How often?* (Never / Occasionally / Weekly / Several times a week)
- *How important is it that the people close to you share your daily rhythm?* (1–5 scale)
- *Do you consider yourself a morning or evening person?* (cross-validated against HealthKit data)

These preferences become multipliers in the compatibility score — they do not filter candidates, they shape how signals are weighted for each specific user.

### 3.3 The Five Signal Layers

**Layer 1 — Health Biometrics (HealthKit / Health Connect)**
The foundation. Sleep alignment, activity level similarity, peak activity window overlap, routine stability matching, personal space index, and recovery pattern compatibility combine into a lifestyle rhythm score. Raw health data never leaves the user's device — only derived, aggregated metrics are transmitted.

**Layer 2 — Visual Preference Inference**
During onboarding, users make a series of intuitive visual choices — not categories or filters, but immediate reactions to AI-generated person archetypes. Over 10–15 rounds, these build a personal preference embedding that captures aesthetic alignment without requiring self-description.

**Layer 3 — Photo Context Analysis**
When users upload profile photos, Synca's AI analyzes contextual signals: setting, objects and props, activity type, style consistency across photos.

**Layer 4 — Music Listening Profile**
Spotify or Yandex Music OAuth integration exposes audio features across each user's listening history: energy level, emotional valence, genre diversity, and listening time patterns. Added post-MVP v1.

**Layer 5 — Travel Behavior**
Integration with travel services reveals how often someone travels, how far from home, and whether they seek new experiences or prefer familiar places. Added post-MVP v1.

---

## 4. Product Experience

### 4.1 Onboarding

1. **Sign in with Apple / Google** — identity and basic profile
2. **Health data authorization** — HealthKit (iOS) or Health Connect (Android), with granular consent controls
3. **Declared preferences questionnaire** — under 2 minutes; the interpretation key for all passive signals
4. **Visual preference game** — 10–15 rounds of intuitive archetype choices
5. **Optional enrichments** — connect Spotify or Yandex Music, enable location zones, indicate travel style
6. **Dashboard unlock** — the user immediately sees their own lifestyle profile: chronotype, peak energy window, routine stability, activity level, music personality

The dashboard provides standalone value on day one, before any match exists. Users see a reflection of how they actually live — not how they think they live.

### 4.2 The Match Experience

Synca produces matches through two distinct origins, each with its own UX label so users always understand the source of the connection.

**Match from Spark (IRL — available to all tiers)**
When two users complete a Spark session and their compatibility score meets the match threshold, a Match is created automatically. The match card displays a **"Synca Confermata"** badge — signalling a verified in-person origin. This is the primary match flow for MVP.

**Match from Algorithm (Curated — Premium only)**
When the nightly algorithm identifies a sufficiently strong bilateral compatibility between two users who have not yet met, a match proposal is surfaced. The match card displays a **"Synca Suggerita"** badge. Both users see the proposal independently. If both accept, a chat opens — already anchored to a suggested date context. Algorithm-originated matches require an active Premium subscription.

### 4.3 Synca Spark — Live In-Person Compatibility

Synca Spark is the bridge between the physical and digital world. When two people meet in real life — at a gym, a sauna, a run club event, a coworking space, or any social gathering — either person can initiate a Spark session directly from the app.

**How it works:**

1. User A opens Synca and taps **"Spark"**. A session QR code and 6-digit code appear on screen.
2. User B scans the QR code or enters the code. Both phones are now linked.
3. Both users confirm their physical presence. No questionnaire, no manual input — the fact that two people choose to Spark together is itself a meaningful intent signal.
4. The backend computes a compatibility score from both users' existing passive signals.
5. The result screen appears simultaneously on both phones:
   - **Instant compatibility snapshot** across the core dimensions, expressed in plain language (never as a raw number)
   - A **suggested first meeting proposal** based on their combined signals and current location context
   - A **reward for both**: one free week of Premium (free-tier users) or one free curated match credit (Premium users)
6. If the compatibility score meets the match threshold, a **Match is created automatically** and both users are notified.

**Why Spark matters strategically:**

- **Acquisition**: every Spark session onboards two fully profiled users simultaneously at zero marginal cost
- **Viral loop**: every gym, sauna, or run club event becomes a natural Synca distribution point
- **Trust boost**: both participants receive a verified IRL interaction badge, raising their Trust Score and making them more visible in the matching pool
- **Anti-fake signal**: a Spark session between two real people in the same physical location is nearly impossible to fake — it is the strongest liveness verification in the system
- **Group foundation**: Spark is also the admission credential for Circles (see Section 5)

**Reward mechanics by user type:**

| User type | Reward received |
|---|---|
| Free tier | 7 days of Premium, unlocked immediately |
| Premium (active) | 1 free curated match credit, valid 30 days |
| Lapsed Premium | 7 days of Premium re-activation |

The Spark reward system is designed to be self-funding: each 7-day trial converts at an estimated 20–35% to paid Premium. The cost of one free week is approximately €3.50 at blended ARPU — justified by the dual acquisition value of the session.

### 4.4 Moments — From Match to Real Meeting

Once a Match exists, either user can propose a **Moment**: a specific meeting with location, date, and time. The other person can accept, decline, or counter-propose. A counter-proposal chain is capped at 5 rounds.

After the meeting, both users rate the experience. No-show events reduce the offending profile's Trust Score. Completed Moments with positive ratings reinforce it. The Moment lifecycle transforms a match from a digital event into a real-world outcome — which is the only metric Synca ultimately optimizes for.

### 4.5 Trust Architecture

Every profile carries a dynamic Trust Score that determines visibility in the matching pool:

- **Photo liveness check**: anti-spoofing at upload
- **Image forensics**: AI-generated image detection, EXIF analysis, metadata inconsistencies
- **Reverse image lookup**: near-duplicate search across platforms
- **Behavioral signals**: message patterns, external link sharing, patterns correlated with transactional accounts
- **Health data consistency**: impossibly uniform data signals fabrication; cross-signal contradiction lowers the score
- **IRL verification**: completed Spark sessions are the strongest available liveness signal; each session increments the IRL verification count
- **Moment history**: no-show events reduce score; completed Moments raise it

Profiles below Trust Score thresholds receive progressively reduced visibility — selective ghosting. They are not banned and not notified. They can raise their score by completing genuine onboarding steps and Spark sessions.

---

## 5. Beyond Dating: The Bigger Picture

The compatibility engine Synca builds for romantic matching is identical to what is needed to form high-quality groups for any social or physical activity.

Consider what the system already knows about each user by the time they have a full signal profile:

- Their weekly calorie burn during sport sessions
- The time of day they prefer to be physically active
- Whether they train at high intensity or moderate pace
- Whether they play team sports and how frequently
- Their travel style and openness to novel experiences
- Their social rhythm: do they prefer quiet evenings or active social schedules?

This is exactly the data needed to know whether seven people are the right fit for a weekly calcetto group, a Saturday padel ladder, a morning trail run club, or a recurring sauna session. Synca does not need to build a new product to enter this space — the data infrastructure, the Spark mechanism, and the compatibility engine are the same.

### 5.1 Circles — Verified Group Spaces

Circles are conversational and coordination spaces that exist only when a verified physical compatibility graph exists between all members. They are not generic group chats — they are spaces where every participant has physically met and been Spark-verified with the relevant other members.

| Type | Members | Admission rule | Use case |
|---|---|---|---|
| **Duo** | 2 | 1 confirmed Spark between the two members | Match chat — default post-match |
| **Small Group** | 3–8 | Every pair has ≥1 confirmed Spark | Aperitivo group, activity circle, calcetto |
| **Event** | 9–22 | Every member has ≥1 Spark with the creator | Tournament, group outing, sauna event |

The Event Circle relaxes the full-graph requirement: not all 10 players in a calcetto match need to have met each other. The creator acts as social guarantor — each member has a verified Spark with them.

This is what Synca becomes at scale: **the trust layer for small-group real-world experiences**. Not just "who should I date" but "who should be in my padel group this season".

### 5.2 Group Spark

Paralleling the duo Spark, a Group Spark allows multiple users physically co-located — at a gym event, a sauna, a run club — to initiate a multi-person session simultaneously. The system computes pairwise compatibility scores for every combination in the group. Pairs above the match threshold receive individual matches; the group as a whole becomes eligible for a Circle when the required Spark graph is complete.

Every Group Spark is simultaneously a user acquisition event, a trust verification event, and a group formation event.

---

## 6. Business Model

### 6.1 Revenue Streams

**Premium Subscription**
Market-adjusted pricing (€7.99 Moscow, $8.99 Bangkok, €14.99 Milan, €16.99 Berlin/Dubai). All subscription payments processed outside App Store and Google Play — eliminating the standard 30% platform commission.

**Pay-per-Match / Moment Pack**
Users purchase a single curated match or a ready-made meeting experience.

**Spark Reward Loop**
The 7-day trial re-engagement conversion (est. 20–35%) makes the reward system self-funding. Cost per Spark reward: ~€3.50. Expected LTV uplift per converted re-activation: ~€54 (3 months average retention at €18 ARPU).

**B2B Venue Partnerships**
Gyms, saunas, padel courts, and cafés become active partners. Revenue share: 15–20% of each booked Moment. Spark sessions at partner venues carry a co-branded experience, reinforcing venue loyalty programs.

**Group Activity Packs**
Curated small-group experiences (morning runs, sauna sessions, calcetto, padel tournaments) sold as premium packs, co-branded with venue partners. This surface opens naturally as Circles and Group Spark reach critical density — no additional data infrastructure required.

### 6.2 Feature Access by Tier

| Feature | Free | Premium |
|---|---|---|
| Spark sessions (duo) | ✅ unlimited | ✅ unlimited |
| Group Spark | ✅ unlimited | ✅ unlimited |
| Match from Spark (IRL origin) | ✅ | ✅ |
| Match from Algorithm (curated) | ❌ | ✅ |
| Moment proposals | ✅ | ✅ |
| Circle Duo (1:1 chat) | ✅ 1 active | ✅ unlimited |
| Circle Small Group (3–8) | 1 active | ✅ unlimited |
| Circle Event (9–22) | ❌ | ✅ |
| Spark invite relay | ❌ | ✅ |
| Detailed compatibility analytics | ❌ | ✅ |

### 6.3 Unit Economics (Indicative)

| Metric | Estimate | Basis |
|---|---|---|
| Target blended ARPU (net) | €12.60/month | €18 gross × 70% after store fees |
| Spark reward cost | ~€3.50 per session | 7-day trial at blended daily ARPU |
| Spark → paid conversion (re-engagement) | 20–35% | RevenueCat 2025 re-engagement trial data |
| Spark net LTV contribution | ~€7–15 per session | After reward cost, net of churn |
| B2B venue fee per booking | 15–20% | Standard affiliate/referral model |
| Platform commission saved | 30% | Via Telegram/web payment routing |

---

## 7. Go-To-Market

### 7.1 The Community-First Principle

Synca does not launch to a city. It launches to a community within a city. The minimum viable density is approximately 300–500 active users per city.

The playbook for every city:

1. Identify 2–3 anchor communities: run clubs, boutique gyms, saunas, coworking spaces, expat networks
2. Recruit local ambassadors: 1–3 community organizers per city
3. Host seeding events: invite-only gatherings where entry requires completing Synca onboarding
4. Physical presence: posters and cards in gyms, saunas, and fitness spaces with QR codes linking to onboarding
5. **Spark activation at every event**: organizers demo the feature live, generating 20–50 Spark sessions per event and onboarding user pairs simultaneously
6. Activate algorithm matching once density threshold is reached
7. Launch B2B venue partnerships within 8 weeks of city activation

### 7.2 Seven-City Roadmap

**Wave 1 — Months 1–6:** Moscow (primary), Bangkok, Dubai
**Wave 2 — Months 6–18:** Seoul, Milan
**Wave 3 — Months 18–30:** São Paulo, Mexico City

Russia distribution: Telegram Mini App as primary product surface + RuStore for Android, bypassing App Store and Play Store friction. Russian user data stored on Yandex Cloud or VK Cloud per 242-FZ data residency requirements.

---

## 8. Competitive Positioning

| | Tinder/Bumble | Hinge | Keeper/Sitch | **Synca** |
|---|---|---|---|---|
| Matching signal | Self-reported | Self-reported + light behavior | AI on profiles | **Passive multi-signal: health + music + travel + declared preferences** |
| Volume | Infinite swipe | Curated browse | Curated | **Few, high-quality matches** |
| Post-match | Up to users | Some prompts | Some guidance | **Pre-organized Moment proposal** |
| Fake filter | Weak | Moderate | Moderate | **Multi-layer Trust Score + selective ghosting** |
| Live IRL feature | None | None | None | **Spark: passive IRL compatibility verification + reward** |
| Group / social layer | None | None | None | **Circles: IRL-verified group spaces for any activity** |
| Distribution Russia | Blocked | Blocked | Not present | **Telegram Mini App + RuStore** |
| Health data | None | None | None | **Core signal — on-device, privacy-first** |
| Music data | None | None | None | **Spotify / Yandex Music integration** |
| Travel data | None | None | None | **Travel behavior integration** |

The competitive moat is not a feature. It is the **data flywheel**: every Spark session generates verified behavioral data that improves matching for all users. Competitors cannot replicate this without rebuilding from the data layer up.

---

## 9. Why Now

Three infrastructure conditions converge today:

- **Apple HealthKit** has reached 89 million active users. The data is already being collected — Synca is the first product to use it for social compatibility.
- **Android Health Connect** is replacing Google Fit as the platform-level health data standard in 2026, opening the same data access to the full Android ecosystem.
- **Spotify's API** gives programmatic access to music behavioral data for 675 million users.
- **IRL fitness communities** — run clubs, boutique gyms, sauna culture, padel — are resurging globally, creating the perfect distribution channel for Spark.
- **Gen Z and Millennial exhaustion** with swipe-based apps is at a measurable peak, creating an open door for a fundamentally different approach.

*[Team section to be completed with founding team profiles, relevant experience, and advisors.]*

---

## 10. Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Cold start / low density | Dual-value dashboard (standalone health insights); community seeding events; Spark onboards two users per session |
| HealthKit onboarding friction | Standalone health dashboard as immediate value before any match exists; granular consent |
| Privacy concerns (health data) | On-device aggregation; only derived metrics transmitted; GDPR Article 9 compliant architecture |
| Russia distribution friction | Telegram Mini App as primary product; RuStore for Android; Russian cloud data residency |
| Spark abuse (fake IRL claims) | Session requires simultaneous active devices in same location; GPS proximity check; WebSocket sync |
| Algorithm validation | Rapid feedback loop with first users; explicit Moment outcome tracking; iterative weight recalibration |
| Group feature complexity | Circles are additive — built on the same Spark and compatibility infrastructure from MVP; no re-architecture |

---

## 11. Roadmap

| Phase | Milestone | New capabilities |
|---|---|---|
| MVP (0–6 months) | Moscow, Bangkok, Dubai | HealthKit/Health Connect, declared preferences, visual preference game, Spark (duo), algorithm matching (Premium), Moments, Circles Duo, Telegram Mini App |
| v1 (6–18 months) | Seoul, Milan | Spotify + Yandex Music signals, travel behavior, Group Spark, Circle Small Group |
| v2 (18–30 months) | São Paulo, Mexico City | Circle Event (9–22), Group Activity Packs, B2B group venue co-branding, learning-to-rank on compatibility engine |
| v3 (30+ months) | Global | Third-party API for gyms and wellness platforms; anonymized lifestyle research publication |

---

## 12. The Ask

*[To be completed: funding amount, use of funds breakdown, pre-money valuation, equity offered, and investor terms.]*
