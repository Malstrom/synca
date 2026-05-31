# Phase 1 — iOS MVP
**Timeline:** Month 3–9
**Goal:** Working iOS app with real users, health data flowing, first compatibility scores, first IRL Sparks, anti-fake baseline, and a chat channel for every match.
**Success metric:** 500 active users, 100 completed Spark sessions, 30% of matched users open a Circle within 48h of match creation.
**Platform:** iOS only. Android deferred to Phase 2.

---

## US-05 — Create a real account
As a user who activated from a guest account or is registering fresh,
I want to complete my profile with name, photo, and preferences,
so that I can appear in matches and use the full app.

### UF-05 — Full registration + onboarding wizard
→ See [profile-v1.md — Step 1.0](../../features/profile-v1.md#step-10--full-registration--onboarding)

#### UC-12 — User upgrades from guest account
- Arrives via magic link — account already `:active` after activation.
- Prompted to complete remaining onboarding steps (photos, bio, extended preferences) at own pace — not gated.

#### UC-13 — User registers fresh (no prior guest account)
- Enters email + password.
- Redirected to 4-step onboarding wizard; none of the steps are skippable.
- Progress saved locally — app resumes from last completed step if quit mid-flow.

#### UC-14 — User quits mid-wizard
- App resumes from the last completed step on next open.
- `onboarding_completed` remains `false` until all 4 steps are done.

#### UC-15 — Photo rejected by moderation
- Photo is stored but not shown to other users until approved.
- User is notified and prompted to upload a different photo.

---

## US-06 — Recover access to my account
As a user who forgot their password or never received the activation link,
I want to reset my credentials via email,
so that I don't lose my data.

### UF-06 — Password recovery
→ See [profile-v1.md — Step 1.1](../../features/profile-v1.md#step-11--password-recovery-and-credential-management)

#### UC-16 — User requests reset for unknown email
- Always returns HTTP 200 — no email enumeration.

#### UC-17 — Reset token expired (1h)
- User must request a new reset link.
- Old token is invalidated on use or expiry.

#### UC-18 — User changes password while logged in
- Current sessions remain active except others are revoked.
- Ref: profile-v1.md § Step 1.1 Change Password Flow.

---

## US-07 — Connect my health data
As a user who wants to appear in matches,
I want to connect Apple Health so Synca can compute my compatibility profile,
so that I receive meaningful matches instead of random suggestions.

### UF-07 — Apple Health connection + signals sync
→ See [signals-v1.md — Step 1.0](../../features/signals-v1.md#step-10--apple-health--health-connect)

#### UC-19 — User denies HealthKit permissions
- App shows a plain-language explanation of why health data is needed.
- User can proceed but cannot receive algorithm-origin matches until connected.
- Spark-origin matching still works.

#### UC-20 — User has less than 7 days of health data
- `signals` record is created but user does not enter the algorithm matching pool.
- App informs the user: "We need a few more days of data before suggesting matches."

#### UC-21 — User revokes HealthKit permissions after syncing
- Existing `signals` record is retained until the user explicitly deletes their account.
- No new sync runs until permissions are re-granted.

---

## US-08 — Receive my first match
As a user with health data connected,
I want to receive a compatibility match from the algorithm,
so that I can meet someone I'm genuinely compatible with without needing to be in the same place at the same time.

### UF-08 — Algorithm match (nightly job)
→ See [matching-v1.md — Step 1.0](../../features/matching-v1.md#step-10--compatibility-score-health-signals)

#### UC-22 — No candidates above threshold
- MatchingJob runs but finds no user above the algorithm minimum threshold (65).
- No match is created. User is not notified.
- Job retries the next nightly run.

#### UC-23 — Match already exists between the same pair
- `UNIQUE (user_a_id, user_b_id)` constraint prevents duplicate.
- Job silently skips the pair.

#### UC-24 — User's signals are stale (> 30 days)
- User is excluded from the candidate pool until signals are refreshed.
- A `signals_stale` notification is sent after 7 days without sync.

---

## US-09 — Talk to my match
As a user who just received a match,
I want a private space to message them,
so that we can get to know each other before meeting in person.

### UF-09 — Duo Circle creation and messaging
→ See [circles-v1.md — Step 1.0](../../features/circles-v1.md#step-10--duo-circle)

#### UC-25 — Match is algorithm-origin (no prior Spark)
- Circle is created with `spark_id: nil` in `circle_memberships`.
- Both users are encouraged (not required) to complete a Spark to strengthen the trust signal.

#### UC-26 — User sends message while offline
- Message is delivered via push notification when the other user is not in the Circle.
- Push suppressed if the receiver has an active Action Cable subscription open for that Circle.

#### UC-27 — User is a guest account
- Cannot send messages in a Circle — requires an active account.
- App prompts activation via magic link.

---

## US-10 — Verify my identity
As a user who wants to appear higher in match lists,
I want to verify my phone number,
so that other users can trust my profile is real.

### UF-10 — Phone verification
→ See [trust-v1.md — Step 1.0](../../features/trust-v1.md#step-10--trustscore-v0)

#### UC-28 — OTP expired or incorrect
- User must request a new OTP via `POST /api/v1/trust/phone/request`.
- No limit on retries at this stage.

#### UC-29 — Phone number already verified by another account
- Returns 422. User must contact support.

---

## Out of Scope in Phase 1
- Android → Phase 2
- Social login → Phase 2
- Premium gating → Phase 2
- Moments (date proposals) → Phase 2 (basic), Phase 3 (full)
- Liveness check + image moderation → Phase 3
- Music and travel signals → Phase 5
- Small Group and Event Circles → Phase 4
