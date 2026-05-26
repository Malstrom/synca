# Synca — Executive Summary

**Confidential — For Investor Use Only**
*May 2026*

***

## The Problem

Dating apps are broken — not because there are too few people on them, but because they surface the wrong ones. The dominant swipe model generates volume, not quality. Nearly 79% of Gen Z users report burnout from endless swiping, 27% of social mentions about dating apps are negative, and the post-match experience — deciding what to do, where to go, when to meet — fails almost as often as the match itself.[^1][^2]

Beneath the UX problem lies a deeper structural flaw. Current matching relies entirely on self-reported data: photos, bios, stated preferences. These capture how people want to be seen, not how they actually live. Two people can share interests on paper but run on completely different biological clocks, travel with opposite philosophies, and listen to music that signals entirely different emotional profiles — incompatibilities discovered only after meeting. Compounding this, fake profiles, escort accounts, and inauthentic users pollute every major platform with no effective systemic solution.[^3][^4]

***

## The Solution

Synca is a precision matchmaking platform that builds a **multi-signal lifestyle compatibility profile** for each user from passive, continuous, objective data sources — and proposes **one highly curated match at a time**, already paired with a pre-organized date.

### The Signal Stack

Synca progressively combines five categories of lifestyle signals:

**1. Health biometrics** *(core, MVP)*
Sleep patterns, activity rhythms, peak energy windows, routine consistency, and recovery behavior — read from Apple Health (iOS) and Health Connect (Android). Passive, continuous, and structurally difficult to fake.

**2. Visual preference inference** *(core, MVP)*
An onboarding game powered by AI-generated archetypes builds a personal preference embedding from each user's spontaneous visual choices. The system learns aesthetic and lifestyle affinities implicitly — without requiring users to declare explicit filter preferences.

**3. Photo context analysis** *(core, MVP)*
AI analysis of uploaded photos evaluates contextual signals — setting, style, activity type, lifestyle cues — rather than physical attributes. This feeds both the compatibility engine and the trust scoring system.

**4. Travel behavior** *(post-MVP v1)*
Integration with travel services (Polarsteps, Google Maps Timeline, onboarding travel preference game) reveals how often someone travels, how far, and whether they seek new experiences or return to familiar places. One of the strongest predictors of long-term lifestyle compatibility.

**5. Music listening profile** *(post-MVP v1)*
Spotify API integration exposes audio features — energy, valence, diversity, tempo — and listening time patterns. Music correlates deeply with personality and emotional profile, and listening time patterns independently validate and reinforce health data signals (e.g., relaxing music at 22:00 confirms the HealthKit-derived sleep onset time).

Each new signal layer deepens the compatibility model, increases trust score accuracy, and strengthens the defensibility of the matching engine over time.

***

## Key Product Features

**One Match at a Time**
Synca does not present an infinite feed. The algorithm works in the background and surfaces a match only when conditions — health compatibility, visual preference alignment, geographic overlap, authenticity score — are genuinely met. Users receive a small curated batch (ideally one person) rather than hundreds of profiles to evaluate.

**Pre-Organized Date Proposals**
After a match, Synca eliminates the most common post-match failure point: decision paralysis. The system generates 1–3 concrete date proposals based on both users' energy peaks, sleep schedules, geographic proximity, and activity preferences. Users choose from options rather than negotiating from zero.

**Selective Ghosting System**
Profiles showing patterns consistent with inauthenticity — escort behavior, fake health data, photo contexts strongly correlated with transactional intent — receive progressively reduced visibility without notification. A multi-layer Trust Score (liveness detection, photo forensics, behavioral signals, health data quality, music and travel data consistency) maintains community quality automatically.[^4][^5][^3]

**Onboarding Preference Game**
A short visual game using AI-generated person archetypes builds each user's preference embedding implicitly. No explicit category filters. The system infers genuine attraction patterns from spontaneous choices — patterns that users themselves may not have consciously articulated.

**Live In-Person Game**
Two people who meet physically — at a gym, sauna, or social event — can open Synca and start a shared live session. In under three minutes they complete a synchronized compatibility mini-test, see an instant compatibility snapshot, and receive a first date proposal. Every live session produces two fully onboarded users simultaneously, turning physical presence into an organic acquisition channel.

***

## Architecture

```
iOS App (HealthKit)           ──┐
Android App (Health Connect)  ──┤──→  Rails API Backend  ←──→  Telegram Bot / Mini App
Spotify / Travel APIs         ──┘          ↕
                                     Web Payment Page
```

- **Native apps** aggregate health data on-device. Raw samples never reach the server — only anonymized summaries.
- **Rails API** runs all matching logic, trust scoring, date proposal generation, signal enrichment, and premium access management. Single backend serving all client surfaces.
- **Telegram Bot / Mini App** serves as the primary acquisition funnel, notification layer, and payment interface — critical for Russia where Telegram penetration reaches 64.4%.[^6]
- **External payment page** processes all transactions outside App Store / Google Play, eliminating the 30% platform commission. Legally permissible under EU Digital Markets Act (2024); standard practice in Russia, Thailand, and UAE.

***

## Market Opportunity

The global dating app market is valued at **$11.61 billion in 2025**, projected to reach **$24.85 billion by 2035** (CAGR 7.91%). The AI-curated matchmaking segment is the fastest-growing subsector, with $30M+ invested in 18 months across comparable startups — all without health data, all US-only.[^7][^8][^9][^10][^11]

| Competitor | Model | Funding | Gap vs Synca |
|---|---|---|---|
| Keeper | AI + human matchmaker | $4M[^8] | No health/travel/music data, US only |
| Known | AI + in-person dates | $9.7M[^10] | No health/travel/music data, US only |
| Sitch | Pay-per-match | $6.7M[^11] | No health/travel/music data, US only |
| Ditto | AI, no swipe | $9.2M[^9] | No health/travel/music data |
| Hinge | Curated mainstream | $550M+ revenue[^12] | No objective data, swipe model |

**No existing competitor combines objective health biometrics, travel behavior, music profile, visual preference inference, and pre-organized dates in a single platform — across international markets.**

### Seven-City Launch Map

| City | Key Driver | Wave |
|---|---|---|
| **Moscow** 🇷🇺 | Post-Tinder vacuum[^13], +25.3% dating audience 2024[^14], Telegram 64.4%[^6] | 1 |
| **Bangkok** 🇹🇭 | Extreme fake/escort problem[^15], expat community, 20%+ daily users 25–34[^16] | 1 |
| **Dubai** 🇦🇪 | Smartwatch penetration 33.4% globally highest[^17], premium fitness culture[^18] | 1 |
| **Seoul** 🇰🇷 | Premium niche app culture[^19], demographic crisis driving demand[^20] | 2 |
| **Milan** 🇮🇹 | iOS-dominant premium users, fitness culture, GDPR-native | 2 |
| **São Paulo** 🇧🇷 | Largest Latin America dating market $420M[^21] | 3 |
| **Mexico City** 🇲🇽 | #1 city globally for Tinder Passport usage[^22] | 3 |

***

## Business Model

**Premium Subscription** — €12–15/month. Free tier: health dashboard, onboarding games, limited match visibility. Premium: full match access, complete compatibility breakdown, date proposals, signal enrichment (Spotify, travel). All payments via Telegram or external web page — zero App Store commission.

**Pay-per-Match / Date Pack** — Curated match or ready-made date experience purchased individually. Validated by Sitch's $30–90 per pack model.[^11]

**B2B Venue Partnerships** — Gyms, saunas, padel courts, and cafés integrated into the date proposal system. Synca drives structured traffic; venues offer preferential rates packaged as "date packs." Venues also serve as offline acquisition channels.

**Commission-Free Payment Infrastructure** — Telegram Stars, YooMoney, SBP (Russia), Stripe via external link. Zero platform commissions across all markets.

***

## Go-To-Market

Community-first, city-by-city. Each city treated as an independent laboratory:

1. Identify 2–3 micro-communities (run clubs, gyms, saunas) with high wearable penetration
2. Partner with community organizers as local ambassadors
3. Host invite-only seeding events — entry requires completing onboarding. One event = 50–150 fully profiled users
4. Physical manifests in gyms, saunas, and fitness spaces with city-specific QR codes linking to Telegram Bot
5. Activate match engine only after reaching minimum density (~300–500 active users per city)
6. Launch B2B venue partnerships within 8 weeks of city activation

In Russia, the Telegram Bot is the primary acquisition channel — organic and viral within existing Telegram communities.

“Every live in-person session between an existing user and a new user automatically grants both a free curated match credit once the new user completes onboarding. This turns the live game into a viral referral loop: acquisition and reward are naturally embedded in the core product experience.”

***

## Why Now

Three macro trends converge at this precise moment:

- **Swipe fatigue is peaking**: 79% of Gen Z reports dating app burnout; Bumble lost 19% of downloads in 2024; the market is actively searching for alternatives.[^23][^1]
- **Health and lifestyle data infrastructure is mature**: Apple HealthKit has 89M active users; Health Connect replaces Google Fit as Android standard in 2026; smartwatch penetration growing at 17.2% CAGR globally; Spotify has 675M+ users with a developer API ready for integration.[^24][^25][^26]
- **AI-curated matchmaking is being funded internationally**: $30M+ in the segment in 18 months — all US-only, all without health or lifestyle data signals. The international opportunity with a full lifestyle signal stack is entirely open.

***

## Signal Expansion Roadmap

```
MVP                    Post-MVP v1              Post-MVP v2             v3
─────────────────────  ──────────────────────   ─────────────────────   ──────────────────
✓ Sleep & activity     + Spotify integration    + Google Maps Timeline  + Cross-signal
  health data          + Travel preference        (travel behavior)       validation
✓ Visual preference      game                  + Deep audio features     (health ↔ music
  game (AI archetypes) + Basic travel signals    (Spotify)               ↔ travel fusion)
✓ Photo context AI     + Apple Music support   + Multi-source trust    + Predictive
✓ Geolocation                                    scoring upgrade         compatibility
✓ Telegram Bot +                                                          modeling
  payment infra
```

***

## Traction & Status

- Product architecture fully defined across all layers (iOS, Android, Rails backend, Telegram Bot, payment infrastructure)
- Repository initialized as monorepo (iOS app, backend API, documentation)
- iOS MVP in active development: HealthKit integration, sleep/steps aggregation, local compatibility engine, preference onboarding game, mock matching deck
- Matching model defined: weighted scoring across 8 dimensions (sleep, peak activity, routine stability, activity level, personal space, recovery, travel style, music profile)
- Market analysis completed across 7 cities with competitive landscape and city-specific go-to-market
- Telegram architecture and payment infrastructure scoped for Russian market launch
- Yandex AI integration scoped for photo context analysis (Moscow Wave 1)

***

## The Ask

*[To be completed: funding amount, use of funds, valuation, and terms.]*

Priority use of seed capital: engineering team (Android developer + backend engineer), Moscow community seeding events and venue partnerships, Yandex AI and Spotify API integrations, and 6-month runway to first-city product-market fit validation.

***

*Full documentation package available upon request: Litepaper, Technical Whitepaper, Detailed Market Analysis (7 cities), Financial Projections.*

*Contact: [founding team contact to be added]*

---

## References

1. [Bumble results: Will an improved user experience save it from dating ...](https://www.mindtheproduct.com/bumble-financial-results-improved-user-experience/) - More evidence that consumers are falling out of love with dating apps as Bumble this week reported d...

2. [How Brands Are Responding to Dating App Fatigue - Meltwater](https://www.meltwater.com/en/blog/dating-app-fatigue) - The overall volume has held mostly steady, with a slight 8% uptick from October 15, 2024 to April 14...

3. [Proven Ways to Detect Fake Profiles on Dating Apps in 2025 - vaarhaft](https://www.vaarhaft.com/blog/detect-fake-profiles-online-dating) - Vaarhaft explains how automated fake profile detection blends pixel forensics and live recapture to ...

4. [Real users verified, fake accounts blocked, rebuilding trust! - Authme](https://authme.com/case-study/dating-platforms/) - Rebuilding Trust in Dating Platforms: Verifying Real Users and Preventing Fake Accounts and Scams, w...

5. [Safer Swipes: How Identity Verification Is Transforming Dating Apps](https://www.forbes.com/sites/quora/2025/04/13/safer-swipes-how-identity-verification-is-transforming-dating-apps/) - Look for apps that employ multi-layered verification, such as photo validation, video verification, ...

6. [The Telegram Mini Apps Revolution - Earlybird](https://earlybird.so/the-telegram-mini-apps-revolution/) - Telegram's fastest growth in 2025 is marked by achieving 1 billion MAUs and developing monetization ...

7. [Dating App Market Size and Share Analysis | 2026-2035](https://www.nextmsc.com/report/dating-app-market-ic4017) - Dating App Market was valued at USD 11.61 billion in 2025, and it is projected to increase to USD 24...

8. [Startup Keeper Says AI Can Find Your Soulmate, Raises $4M](https://www.businessinsider.com/ai-dating-app-keeper-raised-four-million-pitch-deck-2025-12) - Keeper, an AI matchmaking startup, thinks it can help deliver your "soulmate" to you. And if it can'...

9. [AI dating startup Ditto has successfully raised $9.2 ... - Instagram](https://www.instagram.com/p/DUWZTvpEWoW/?hl=it) - AI dating startup Ditto has successfully raised $9.2 million in seed funding to disrupt the traditio...

10. [Known uses voice AI to help you go on more in-person dates](https://techcrunch.com/2025/12/19/known-uses-voice-ai-to-help-you-go-on-more-in-person-dates/) - Buoyed by these signals, the startup has raised $9.7 million from investors, including Forerunner an...

11. [30-year-old founder is using AI to help singles find love - CNBC](https://www.cnbc.com/2025/08/07/30-year-old-founder-is-using-ai-to-help-singles-find-love.html) - As of July 2025, Sitch has raised $6.7 million in pre-seed and seed funding and boasts "tens of thou...

12. [Dating Apps Market Size and Outlook 2031 - TechSci Research](https://www.techsciresearch.com/report/dating-apps-market/4221.html) - The Dating Apps Market will grow from USD 10.97 Billion in 2025 to USD 17.58 Billion by 2031 at a 8....

13. [Tinder to Exit Russia More Than 1 Year Into Ukraine War](https://www.themoscowtimes.com/2023/05/02/tinder-to-exit-russia-more-than-1-year-into-ukraine-war-a81006) - The popular dating app Tinder will leave Russia on June 30, more than a year into a mass foreign bus...

14. [Russians became more diligent in seeking love last year](https://www1.ru/en/news/2025/01/04/bes-v-rebro-rossiiane-v-proslom-godu-stali-userdnee-iskat-svoiu-liubov.html) - By the end of 2024, the growth rate of the audience of Russian dating services increased by 25.3% co...

15. [A Comprehensive Review of Dating App Performance 2024 Across ...](https://www.bangkokmatching.com/en/blog/dating-apps-performance-2024-across-the-global/) - As 2024 comes to an end, Bangkok Matching has conducted a comprehensive review of dating app perform...

16. [Online dating in Thailand - statistics & facts - Statista](https://www.statista.com/topics/12569/online-dating-in-thailand/) - Thailand's online dating market has seen a remarkable expansion in recent years in tandem with the c...

17. [Smartwatch Statistics By Brands, Revenue and Facts (2025)](https://electroiq.com/stats/smartwatch-statistics/) - Japan: Despite high internet penetration, only 8.6% of internet users own a smartwatch. Morocco: 6.4...

18. [Dubai fitness industry set for more growth as the UAE promotes ...](https://www.consultancy-me.com/news/12331/dubai-fitness-industry-set-for-more-growth-as-the-uae-promotes-healthy-lifestyles) - The fitness industry is seeing steady growth in the UAE, where government action has been part of a ...

19. [Values take priority in dating for Koreans, and rising polarization ...](https://koreajoongangdaily.joins.com/news/2025-05-27/culture/lifeStyle/Values-take-priority-in-dating-for-Koreans-and-rising-polarization-cleaves-new-crevasse/2314433) - Gold Spoon, launched in 2018, is a dating app that requires users to verify their financial standing...

20. [South Korea's 'shocking' fall in marriages is a dating-app opportunity ...](https://fortune.com/asia/2025/04/25/match-group-asia-ceo-south-korea-japan-india-dating-app/) - “Korea has an acute challenge” when it comes to long-term relationships, with a “pretty shocking” 40...

21. [South America Online Dating Services Market Outlook, 2031](https://www.bonafideresearch.com/product/230749835/south-america-online-dating-services-market) - South America Online Dating Services Market was USD 420 Million in 2025 with growth from global and ...

22. [The Best City for Expats to Win at Online Dating in 2025 - YouTube](https://www.youtube.com/watch?v=WJyZ_tgW4_o) - Not a travel vlog — we help high-performing men build a real life in Mexico City. If you want to rel...

23. [The most downloaded dating apps in 2025: Tinder still leads, but ...](https://www.reddit.com/r/AppBusiness/comments/1sytgt4/the_most_downloaded_dating_apps_in_2025_tinder/) - Tinder is dominant, but Hinge is growing faster in absolute terms. Tinder's 63.7M app downloads are ...

24. [Consumer Wearables Generate 2.8 Petabytes of Health Data Annually](https://chay.ai/news/wearable-consumer-data-ehr-integration/) - Industry report reveals that consumer wearable devices generate 2.8 petabytes of health data annuall...

25. [Smartwatch Market Size, Growth & Analysis, 2033](https://www.marketdataforecast.com/market-reports/smartwatch-market) - South Korea, with one of the world's highest smartphone penetration rates at 94%, as noted by the Ko...

26. [Migrating Users from Google Fit SDK to Health Connect](https://helpdocs.validic.com/docs/native-android-mobile-inform-sdk-migrating-users-from-google-fit-sdk-to-health-connect) - Health Connect has replaced Google Fit as the main app for sharing data between Android health apps....
