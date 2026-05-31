# Phase 2 — Android + Payments
**Timeline:** Month 9–12
**Goal:** Android parity, first revenue, premium gating live.
**Success metric:** Android DAU reaches 30% of total DAU within 60 days of launch. First 100 paying subscribers.
**Platform:** iOS + Android.

---

## US-11 — Sign in with a social account
As a user who doesn't want to manage a password,
I want to log in with Apple, Google, or VK,
so that account creation is faster and I don't risk losing access.

### UF-11 — Social login
→ See [profile-v1.md — Step 2.0](../../features/profile-v1.md#step-20--social-login)

#### UC-30 — Provider email matches an existing Synca account
- Accounts are linked automatically via `identity_providers`.
- No duplicate account is created.

#### UC-31 — Provider token invalid or expired
- Returns 401. User must retry the social login flow from the beginning.

#### UC-32 — User revokes app access from the provider
- Existing Synca session remains valid until the refresh token expires (90 days).
- On next login attempt via that provider: returns 401, user must use email/password or re-authorize.

---

## US-12 — Connect my health data on Android
As an Android user,
I want to connect Health Connect so Synca can compute my compatibility profile,
so that I receive the same quality of matches as iOS users.

### UF-12 — Health Connect connection + signals sync
→ See [signals-v1.md — Step 1.0](../../features/signals-v1.md#step-10--apple-health--health-connect)
_(same flow as UF-07, different SDK — Health Connect replaces HealthKit on Android)_

#### UC-33 — User denies Health Connect permissions
- Same behavior as UC-19 (iOS). Spark-origin matching still works.

#### UC-34 — Health Connect not installed on device
- App links to Play Store to install Health Connect before prompting for permissions.

---

## US-13 — Propose a meeting with my match
As a user with an active match,
I want to suggest a place and time to meet,
so that the connection moves from the app to real life.

### UF-13 — Moment proposal (basic: propose, accept, decline)
→ See [moments-v1.md — Step 1.0](../../features/moments-v1.md#step-10--moment-proposal)

#### UC-35 — Receiver declines the proposal
- `status` becomes `declined`. No further action required.
- Proposer is notified via push + in-app.

#### UC-36 — Receiver does not respond within 48h
- No automatic expiry in Phase 2 — proposal stays `pending`.
- A reminder notification is sent to the receiver after 24h.

#### UC-37 — Match is in `drifted` status
- User can still propose a Moment from the match history.
- A confirmed Moment or a new Spark will move the match back to `reconnected`.

> **Phase 2 scope:** proposal, accept, decline only.
> Counter-proposal, completion, and no-show reporting are introduced in Phase 3.

---

## US-14 — Unlock premium features
As a user who wants more from Synca,
I want to subscribe to a premium plan,
so that I can access algorithm-origin matches and advanced features.

### UF-14 — Premium subscription
> Subscription flow spec is not yet written. This US will be linked to the relevant
> feature doc once the payments feature is documented.

#### UC-38 — Subscription lapses (payment failure)
- Premium features are disabled immediately on expiry.
- User is notified and prompted to update payment details.
- Existing matches and Circles remain accessible.

#### UC-39 — User cancels subscription
- Premium access continues until the end of the current billing period.
- No data is deleted on cancellation.

---

## Out of Scope in Phase 2
- Counter-proposals, completion, no-show reporting → Phase 3 (full Moments)
- Liveness check + image moderation → Phase 3
- Small Group and Event Circles → Phase 4
- Music and travel signals → Phase 5
