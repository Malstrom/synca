# Synca — Test Strategy & Conventions

**Version 1.1 — May 2026**

---

## Philosophy

All new code follows **Test-Driven Development (TDD)**:

1. Write the test first — it must fail (red).
2. Write the minimal code to make it pass (green).
3. Refactor if needed, keeping tests green.

Never write a model, service, controller, or job without writing the test first.

---

## Coverage Requirement

**Minimum 90% line coverage**, enforced by SimpleCov on every CI run.
The build fails if coverage drops below 90%.

```ruby
# test/test_helper.rb
require "simplecov"
SimpleCov.start "rails" do
  minimum_coverage 90
end
```

Every new file must have a corresponding test file. No exceptions.

---

## Rails Test Conventions

### Framework

- **Minitest** — the default Rails test framework. No RSpec.
- `test_helper.rb` loads the full environment including `Minitest::Mock`.
  **Never** `require "minitest/mock"` explicitly — it breaks Bootsnap on Ruby 3.3.

### File Location

- Test files live **only in `test/`**. Never place tests in `app/` — Zeitwerk
  autoloads everything in `app/` and will crash on test class definitions.

```
test/
  models/
  controllers/
  services/
  jobs/
  channels/
  fixtures/
```

### Naming Conventions

- Test class: mirrors the class under test — `class CompatibilityScoreServiceTest < ActiveSupport::TestCase`
- Test method names: descriptive English — `test_returns_high_score_for_aligned_sleep_schedules`
- No single-letter or abbreviated variable names inside tests.
  Use full domain names: `signal`, `spark`, `user`, `profile`, `match`, `circle`, `moment`.

### Fixtures

- Use YAML fixtures in `test/fixtures/` for database records.
- If a test requires a fixture that does not exist, create it as part of the same step.
- Do not rely on `FactoryBot` for MVP — fixtures are sufficient and faster.

---

## Stubbing External Services

### Rule: never call `.stub` on external gem classes

`Minitest::Mock` stub is not available on classes loaded after `test_helper`.
Instead, use `define_singleton_method` on the job or service **instance**:

```ruby
# WRONG — will raise NoMethodError or silently fail
AwsS3Client.stub(:upload, true) do
  ...
end

# CORRECT — stub on the instance
job = UploadPhotoJob.new
job.define_singleton_method(:upload_to_s3) { |_file| "https://cdn.synca.app/photo.jpg" }
job.perform(photo_id)
```

### Gems with `require: false`

Gems declared with `require: false` in `Gemfile` (e.g. `aws-sdk-s3`) must be
explicitly required in any test file that references their constants:

```ruby
# test/jobs/upload_photo_job_test.rb
require "aws-sdk-s3"
require "test_helper"
```

---

## What to Test

Every test file must cover at minimum:

| Case | Description |
|---|---|
| Happy path | Normal input → expected output |
| Edge case | Boundary values, empty collections, nil inputs |
| Error case | Invalid input, missing associations, service failures |

### Models

- Validations (presence, uniqueness, format)
- Scopes
- Enum values
- Custom methods

### Services

- Core computation logic (e.g. `CompatibilityScoreService` with known inputs → known score)
- Correct DB side-effects (records created/updated)
- Error handling when dependencies are missing

### Controllers (Request tests)

- HTTP status codes (200, 201, 401, 422, 404)
- Response JSON structure
- Auth enforcement (`401` when token missing or invalid)

### Jobs

- Job performs without error on valid data
- Job skips gracefully on missing/stale data
- Correct records created/updated as side effects

### Channels

- Subscription accepted for authorized members
- Subscription rejected for non-members

---

## CI Pipeline

`bin/rails ci` runs in order:

```bash
bundle exec rubocop --autocorrect
bundle exec bundle-audit check --update
bundle exec brakeman --no-pager
bundle exec rails test
# SimpleCov enforces ≥ 90% — rails test fails if threshold not met
git push origin HEAD
```

All PRs target `main`. Squash and merge only.
Branch protection: CI must pass before merge is allowed.

---

## iOS Testing (XCTest)

- Unit tests for all Services and ViewModels.
- `SignalAggregatorService` is tested via a `HealthKitProtocol` mock —
  never hits the real `HKHealthStore`.
- Network layer tested via `MockURLProtocol` injected into `URLSession`.
- No UI tests (XCUITest) for MVP — add in Phase 2 for critical flows
  (Spark session, match creation).
