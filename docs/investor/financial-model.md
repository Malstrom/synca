# Synca — Financial Model
**Version 1.1 — May 2026**
**Confidential. For investor due diligence only.**

---

## 1. Model Overview & Assumptions

This model covers a 36-month horizon (Year 1–3) across three scenarios: **Conservative**, **Base**, and **Optimistic**. All figures are in **EUR** unless otherwise noted. The model is built bottom-up from unit economics, not top-down market share projections.

### 1.1 Seed Raise Assumption
- **Target raise:** €700,000 (midpoint of 600k–800k range)
- **Equity sold at seed:** ~20% (aligned with 2025 median of 19.5% at seed stage)
- **Implied post-money valuation:** €3.5M
- **Runway target:** 18–20 months post-close

### 1.2 Exchange Rate Assumptions
- EUR/RUB: 100 (conservative buffer; used for all salary calculations)
- EUR/USD: 1.08

### 1.3 Launch Strategy
- **Month 1–6:** Moscow only (iOS + Android MVP)
- **Month 7–12:** Moscow consolidation + Bangkok soft launch
- **Year 2:** Moscow full + Bangkok + Milano
- **Year 3:** 5–7 cities (add Berlin, Dubai, São Paulo, Seoul)

---

## 2. Team & Personnel Costs

Team of 4–5 people, primarily based in Moscow. Salaries reflect 2025–2026 Moscow market rates for startup context (below market, partially compensated with equity).

### 2.1 Core Team (post-seed, Month 1)

| Role | Seniority | Monthly Gross (RUB) | Monthly Gross (EUR) | Notes |
|---|---|---|---|---|
| Founder / CTO | — | 200,000 ₽ | €2,000 | Below-market; equity offset |
| Backend Engineer (Rails) | Mid-Senior | 250,000 ₽ | €2,500 | Market mid: 300k, discounted |
| Android Engineer (Kotlin) | Mid | 200,000 ₽ | €2,000 | Market: 165k/mo avg (PayScale) |
| iOS Engineer (Swift) | Mid | 200,000 ₽ | €2,000 | Shared with CTO initially |
| Product / UX + Growth | Junior-Mid | 120,000 ₽ | €1,200 | Part-time Month 1–6 |
| **Total payroll / month** | | **970,000 ₽** | **~€9,700** | Pre-tax |

### 2.2 Payroll Scaling

| Period | Monthly Payroll (EUR) | FTE Equivalent | Key Addition |
|---|---|---|---|
| Month 1–6 | €9,700 | 4.5 | Core team only |
| Month 7–12 | €13,500 | 5.5 | + Data/ML Engineer |
| Year 2 | €18,000–€22,000 | 7–8 | + Growth Lead, Customer Support |
| Year 3 | €28,000–€35,000 | 10–12 | + City managers, second backend |

---

## 3. Operating Cost Structure

### 3.1 Monthly Fixed & Variable Costs (Year 1)

| Cost Category | Monthly (EUR) | Annual (EUR) | Notes |
|---|---|---|---|
| **Payroll** | €9,700 | €116,400 | See Section 2 |
| **Cloud infra (AWS/GCP)** | €800 | €9,600 | MVP load; scales with MAU |
| **App Store fees** | — | — | 30% Apple/Google cut built into net revenue |
| **Legal & Compliance** | €500 | €6,000 | GDPR, 242-FZ data localization |
| **Tools & SaaS** | €300 | €3,600 | Figma, GitHub, Mixpanel, Sentry, etc. |
| **Community Events (GTM)** | €1,500 | €18,000 | Gyms, run clubs, sauna events in Moscow |
| **Synca Spark reward cost** | €300 | €3,600 | Est. 80–100 Spark sessions/mo Y1 × ~€3.50 avg |
| **Paid UA (organic-first)** | €500 | €6,000 | Minimal paid; mostly organic Y1 |
| **Miscellaneous / buffer** | €400 | €4,800 | |
| **Total Monthly OpEx** | **€14,000** | **€168,000** | |

> **Spark reward note:** The €3,600/year cost in Year 1 is more than offset by the dual-acquisition value of each session (two profiled users at ~€6 blended organic CAC each = ~€12 acquisition value per session). Net Spark economics are strongly positive from Month 1.

### 3.2 One-Time Pre-Launch Costs (Month 0)

| Item | Cost (EUR) |
|---|---|
| App Store developer accounts (Apple + Google) | €125 |
| Legal setup (LLC/OOO Russia) | €800 |
| Brand & design sprint | €2,000 |
| Security audit (basic, pre-launch) | €1,500 |
| Initial event sponsorships (Moscow launch) | €3,000 |
| **Total pre-launch** | **€7,425** |

---

## 4. Revenue Model & Unit Economics

### 4.1 Monetization Structure

Synca uses a **freemium subscription** model with Synca Spark as a retention and acquisition accelerator.

| Tier | Price/month | Features | Target conversion |
|---|---|---|---|
| **Free** | €0 | Limited daily matches, basic profile, Spark access | 100% of users |
| **Premium** | €14.99/mo or €89/year (market-adjusted) | Unlimited matches, compatibility deep-dive, date proposals, Spark match credit | 4–7% of MAU |
| **Premium+** | €24.99/mo or €149/year | All above + event invitations, chronotype insights, profile boost, extra Spark credits | 1–2% of MAU |
| **Boosts (IAP)** | €2.99–€9.99 | Visibility boost, re-match, extra Spark credits | Occasional |

**Market-adjusted pricing:**

| City | Premium/month | Premium/year |
|---|---|---|
| Moscow | €7.99 (~800 ₽) | €49.99 |
| Bangkok | $8.99 | $54.99 |
| Milan / Berlin | €14.99–€16.99 | €89.99–€99.99 |
| Dubai | $17.99 | $109.99 |

### 4.2 Synca Spark Revenue Impact

| Metric | Value | Notes |
|---|---|---|
| Spark reward cost (7-day trial) | ~€3.50 | At blended daily ARPU |
| Trial → paid conversion (re-engagement) | 20–35% | RevenueCat 2025 re-engagement data |
| Net LTV per Spark session (converted) | ~€7–15 | After reward cost, 3-month avg retention |
| Spark sessions/event (est.) | 20–50 | Based on 100–200 attendees |
| New profiled users per event via Spark | 40–100 | 2 users per session |

### 4.3 Key Unit Economics Assumptions

| Metric | Conservative | Base | Optimistic | Source / Rationale |
|---|---|---|---|---|
| Free-to-paid conversion | 3% | 5% | 7% | Dating apps: 3–8% (DedicatedDev 2025) |
| Blended ARPU (paying users/mo) | €15 | €18 | €22 | Below Hinge ($25–40) due to Moscow/Bangkok pricing |
| Monthly churn (paying users) | 8% | 6% | 4% | Dating apps: 25–40% annual = 6–8% monthly |
| Organic install share | 60% | 70% | 80% | Community-first + Spark dual-acquisition |
| Blended CAC (incl. Spark channel) | €22 | €15 | €11 | Spark lowers blended CAC vs. pure paid UA |
| LTV (paying user) | €56 | €90 | €165 | ARPU / churn |
| LTV:CAC ratio | 2.5x | 6.0x | 15.0x | Spark improves CAC; LTV:CAC improves Y2+ |

---

## 5. MAU & Revenue Projections

### 5.1 MAU Growth Assumptions

| Period | City | Total MAU | Paying Users (Base 5%) | Notes |
|---|---|---|---|---|
| Month 1–3 | Moscow | 500 | 25 | Closed beta, invite-only |
| Month 4–6 | Moscow | 2,000 | 100 | Public launch + Spark at events |
| Month 7–9 | Moscow + Bangkok | 5,000 | 250 | Bangkok soft launch |
| Month 10–12 | Moscow + Bangkok | 9,000 | 450 | Word of mouth + Spark viral loop |
| Year 2 End | 3 cities | 28,000 | 1,400 | + Milano |
| Year 3 End | 5–7 cities | 90,000 | 5,400 | + Berlin, Dubai, SP, Seoul |

### 5.2 Three-Scenario Revenue Model

#### YEAR 1

| Metric | Conservative | Base | Optimistic |
|---|---|---|---|
| MAU end of year | 6,000 | 9,000 | 14,000 |
| Paying users end of year | 180 | 450 | 980 |
| Avg paying users (annual) | 80 | 180 | 350 |
| Avg ARPU/mo | €15 | €18 | €22 |
| **Gross Revenue** | **€14,400** | **€38,880** | **€92,400** |
| App Store fees (30%) | -€4,320 | -€11,664 | -€27,720 |
| **Net Revenue** | **€10,080** | **€27,216** | **€64,680** |
| Total OpEx | €168,000 | €168,000 | €168,000 |
| **Net Burn Y1** | **-€157,920** | **-€140,784** | **-€103,320** |

#### YEAR 2

| Metric | Conservative | Base | Optimistic |
|---|---|---|---|
| MAU end of year | 18,000 | 28,000 | 45,000 |
| Paying users end of year | 540 | 1,400 | 3,150 |
| Avg paying users (annual) | 360 | 950 | 2,000 |
| Avg ARPU/mo | €16 | €18 | €23 |
| **Gross Revenue** | **€69,120** | **€205,200** | **€552,000** |
| App Store fees (30%) | -€20,736 | -€61,560 | -€165,600 |
| **Net Revenue** | **€48,384** | **€143,640** | **€386,400** |
| Total OpEx (scaled) | €258,000 | €270,000 | €294,000 |
| **Net Burn Y2** | **-€209,616** | **-€126,360** | **+€92,400** |

#### YEAR 3

| Metric | Conservative | Base | Optimistic |
|---|---|---|---|
| MAU end of year | 50,000 | 90,000 | 160,000 |
| Paying users end of year | 1,500 | 5,400 | 12,800 |
| Avg paying users (annual) | 1,100 | 3,500 | 8,500 |
| Avg ARPU/mo | €17 | €19 | €24 |
| **Gross Revenue** | **€224,400** | **€798,000** | **€2,448,000** |
| App Store fees (30%) | -€67,320 | -€239,400 | -€734,400 |
| **Net Revenue** | **€157,080** | **€558,600** | **€1,713,600** |
| Total OpEx (scaled) | €402,000 | €438,000 | €510,000 |
| **Net Profit / (Loss) Y3** | **-€244,920** | **+€120,600** | **+€1,203,600** |

---

## 6. Burn Rate & Runway Analysis

### 6.1 Seed Capital Deployment (€700,000)

| Period | Monthly Burn (EUR) | Cumulative Spend | Remaining Capital |
|---|---|---|---|
| Pre-launch (Month 0) | €7,425 one-time | €7,425 | €692,575 |
| Month 1–6 | €14,000/mo | €84,000 | €608,575 |
| Month 7–12 | €16,500/mo | €99,000 | €509,575 |
| **End of Year 1** | | **€190,425** | **€509,575** |
| Year 2 (Base) | €22,500/mo avg | €270,000 | €239,575 |
| **End of Year 2** | | **€460,425** | **€239,575** |

> **Runway (Base scenario):** ~**18–19 months** post-seed close. Sufficient to reach Series A trigger conditions.

### 6.2 Break-Even Analysis (Base Scenario)

- Monthly break-even requires ~€22,500 net revenue/month (Year 2 opex level)
- At €18 ARPU net (~€12.60 post-store-fee): requires **~1,786 paying users simultaneously**
- Base scenario reaches this in **Month 26–28** (Q1 Year 3)

### 6.3 Burn Multiple

| Year | Net Revenue | Net Burn | Burn Multiple |
|---|---|---|---|
| Y1 (Base) | €27,216 | €140,784 | 5.2x |
| Y2 (Base) | €143,640 | €126,360 | 0.88x |
| Y3 (Base) | €558,600 | n/a (profit) | — |

---

## 7. Funding Roadmap

### 7.1 Seed Round (Current)
- **Amount:** €600k–€800k
- **Use of funds:** Product 40%, Team 35%, GTM Moscow (events + Spark) 15%, Legal/ops 10%
- **Milestone:** 10,000 MAU, 500 paying users, 3 cities soft-launched, Synca Spark live

### 7.2 Series A (Projected Month 18–22)
- **Amount:** €2.5M–€4M
- **Trigger:** €100k+ MRR, LTV:CAC > 3x, 3 cities active, Spark sessions >500/month
- **Use of funds:** City expansion (5–7 cities), ML matching improvement, team scaling, paid UA

### 7.3 Series B (Projected Year 4–5)
- **Amount:** €10M–€20M
- **Trigger:** €3M+ ARR, 100k+ MAU, >30% EBITDA margin trajectory
- **Use of funds:** International expansion, potential acquisition of complementary apps

---

## 8. Sensitivity Analysis

### Revenue sensitivity to conversion rate (Base ARPU €18, 9,000 MAU)

| Conversion Rate | Paying Users | Monthly Net Revenue | Annual Net Revenue |
|---|---|---|---|
| 2% | 180 | €2,268 | €27,216 |
| 3% | 270 | €3,402 | €40,824 |
| 5% | 450 | €5,670 | €68,040 |
| 7% | 630 | €7,938 | €95,256 |
| 10% | 900 | €11,340 | €136,080 |

### Synca Spark acquisition sensitivity (per event)

| Attendees per event | Spark sessions | New users acquired | CAC via Spark |
|---|---|---|---|
| 50 | 10 | 20 | ~€7.50/user (event cost only) |
| 100 | 25 | 50 | ~€3.00/user |
| 200 | 50 | 100 | ~€1.50/user |

> At 200-person events (realistic for Moscow gym or sauna nights), Spark acquisition cost drops to ~€1.50/user — roughly 4x cheaper than the best paid UA channel.

---

## 9. Comparable Exits & M&A Context

| Company | Niche | Funding | Outcome |
|---|---|---|---|
| Hinge | Relationship-focused | ~$8M before Match | Acquired by Match Group for ~$51M (2018), now $689M revenue (2025) |
| Coffee Meets Bagel | Curated matches | ~$23M | Rumored acquisition talks; $30M+ valuation |
| The League | Vetted/elite | ~$3M | Acquired by Match Group for ~$30M (2022) |
| Keeper | Compatibility AI | ~$4M raised | Active, Series A in progress |
| Thursday | IRL dating | ~$3M raised | Profitable in London, expanding |

---

## 10. Key Risks & Mitigants

| Risk | Impact | Probability | Mitigant |
|---|---|---|---|
| Cold start — insufficient MAU | High | High | Invite-only beta; Spark onboards 2 users/session |
| Low HealthKit adoption | High | Medium | Progressive onboarding; health data optional for basic access |
| Android dominance in Moscow | Medium | Certain | Android MVP parallel to iOS from Day 1 |
| Regulatory (242-FZ) | Medium | Certain | Russian data on Russian servers from Month 0 |
| Low conversion (< 3%) | High | Medium | A/B test paywall; Spark 7-day trial re-engagement |
| Spark abuse (fake sessions) | Medium | Low | GPS proximity check + WebSocket sync required |
| Competitor copies health-matching | Medium | Low (Y1–2) | 12–18 months to replicate depth; network effects compound |
| Burn exceeds runway | High | Low | 18-month base runway; clear Series A triggers at Month 18 |

---

## 11. Model Assumptions Summary

| Parameter | Value | Source |
|---|---|---|
| Seed raise | €700,000 | Target midpoint |
| Equity sold | 20% | 2025 seed median (AngelList data) |
| Average dev salary Moscow | 200–250k RUB/mo | Reddit/HH.ru/TAdviser 2024–2025 |
| Blended ARPU (gross) | €18/mo | RevenueCat 2026 comparable |
| Free-to-paid conversion (base) | 5% | Dating apps range: 3–8% |
| Monthly churn (paying, base) | 6% | Dating apps annual 25–40% |
| Organic acquisition share | 70% | Community-first + Spark channel |
| Spark reward cost | ~€3.50/session | 7-day trial at blended daily ARPU |
| Spark → paid re-conversion | 20–35% | RevenueCat 2025 re-engagement trials |
| App Store fee | 30% | Standard Apple/Google rate |
| Gross margin (variable costs) | 84% | FinancialModelsLab niche dating 2025 |
| Target EBITDA margin Y3 | >30% | Industry benchmark for niche dating |
