# Rails Testing — Minitest Conventions

Synca uses **Minitest** (Rails default) for all backend tests. No RSpec.

---

## Directory Structure

```text
test/
├── models/
│   ├── user_test.rb
│   ├── health_summary_test.rb
│   ├── match_test.rb
│   ├── spark_session_test.rb
│   └── sync_room_test.rb
├── services/
│   ├── matching/
│   │   ├── matching_service_test.rb
│   │   └── compatibility_score_service_test.rb
│   └── trust/
│       └── trust_score_service_test.rb
├── jobs/
│   ├── matching_job_test.rb
│   └── spark_scoring_job_test.rb
├── controllers/
│   └── api/
│       └── v1/
│           ├── auth_controller_test.rb
│           ├── profiles_controller_test.rb
│           ├── health_summaries_controller_test.rb
│           ├── matches_controller_test.rb
│           ├── spark_sessions_controller_test.rb
│           └── sync_rooms_controller_test.rb
├── fixtures/
│   ├── users.yml
│   ├── health_summaries.yml
│   ├── preference_profiles.yml
│   ├── matches.yml
│   ├── spark_sessions.yml
│   └── sync_rooms.yml
└── test_helper.rb
```

---

## test_helper.rb

```ruby
require "simplecov"
SimpleCov.start "rails" do
  add_filter "/config/"
  add_filter "/test/"
  minimum_coverage 90
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  fixtures :all

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end
end
```

> **Coverage target: ≥ 90% globally.** Core domain (matching, Spark, TrustScore,
> SyncRoom admission) must reach 100%.

---

## Model Test Example — Match origin

File: `test/models/match_test.rb`

```ruby
require "test_helper"

class MatchTest < ActiveSupport::TestCase
  test "defaults origin to spark" do
    match = Match.new(compatibility_score: 80.0, status: :proposed)
    assert match.spark?
  end

  test "algorithm origin stores confidence" do
    match = Match.new(
      compatibility_score: 70.0,
      status: :proposed,
      origin: :algorithm,
      algorithm_confidence: 0.85
    )
    assert match.algorithm?
    assert_in_delta 0.85, match.algorithm_confidence
  end

  test "spark origin has nil algorithm_confidence" do
    match = matches(:alice_bob_spark)
    assert match.spark?
    assert_nil match.algorithm_confidence
  end
end
```

---

## Service Test Example — CompatibilityScoreService

File: `test/services/matching/compatibility_score_service_test.rb`

```ruby
require "test_helper"

class CompatibilityScoreServiceTest < ActiveSupport::TestCase
  setup do
    @user_health = HealthSummary.new(
      sleep_duration_avg: 7.5,
      chronotype: "morning",
      activity_minutes: 200
    )
    @candidate_health = HealthSummary.new(
      sleep_duration_avg: 7.2,
      chronotype: "morning",
      activity_minutes: 220
    )
  end

  test "returns score between 0 and 100" do
    score = Matching::CompatibilityScoreService.call(@user_health, @candidate_health)
    assert_includes 0..100, score.total
  end

  test "two identical profiles score above 90" do
    score = Matching::CompatibilityScoreService.call(@user_health, @user_health)
    assert score.total >= 90
  end

  test "mismatched chronotypes lower sleep score" do
    evening = HealthSummary.new(
      sleep_duration_avg: 7.5,
      chronotype: "evening",
      activity_minutes: 200
    )
    score = Matching::CompatibilityScoreService.call(@user_health, evening)
    assert score.breakdown[:sleep] < 60
  end
end
```

---

## Job Test Example — MatchingJob (algorithm origin)

File: `test/jobs/matching_job_test.rb`

```ruby
require "test_helper"

class MatchingJobTest < ActiveJob::TestCase
  test "creates algorithm-origin match when score is above threshold" do
    user = users(:alex)
    candidate = users(:maria)

    # Both users need a complete health summary
    assert user.health_summary.present?
    assert candidate.health_summary.present?

    assert_difference "Match.algorithm.count", 1 do
      MatchingJob.perform_now
    end

    match = Match.algorithm.last
    assert match.algorithm?
    assert_not_nil match.algorithm_confidence
    assert match.compatibility_score >= 65
  end

  test "does not create match when score is below threshold" do
    # Fixture with incompatible health summaries
    users(:night_owl)   # chronotype: night_owl
    users(:early_bird)  # chronotype: early_bird, opposite schedule

    assert_no_difference "Match.count" do
      MatchingJob.perform_now
    end
  end
end
```

---

## Controller Test Example — Matches

File: `test/controllers/api/v1/matches_controller_test.rb`

```ruby
require "test_helper"

class Api::V1::MatchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alex)
    @token = generate_token_for(@user)
  end

  test "GET /api/v1/matches returns match list with origin" do
    get api_v1_matches_url,
        headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :success
    body = json_response
    assert body.key?(:matches)
    first_match = body[:matches].first
    assert_includes %w[spark algorithm], first_match[:origin]
  end

  test "GET /api/v1/matches returns 401 without token" do
    get api_v1_matches_url
    assert_response :unauthorized
  end
end
```

---

## Conventions

- One test file per model, service, job, or controller.
- Test method names in English, describe the exact behavior under test.
- Use `setup` for shared state within a test class.
- Prefer real objects and fixtures over mocks; use mocks only for external HTTP calls
  and third-party services.
- Each test asserts one thing. Split complex scenarios into multiple small tests.
- Keep fixtures minimal: only the fields needed for the test.
- Never use `require "minitest/mock"` — `Minitest::Mock` is already available via
  `test_helper`. Requiring it explicitly breaks Bootsnap on Ruby 3.3.
- Never place test files inside `app/` — Zeitwerk will attempt to autoload them.
- Gems with `require: false` (e.g. `aws-sdk-s3`) must be explicitly required in
  any test file that references their constants.

---

## Running Tests

```bash
# All tests (runs SimpleCov, fails if coverage < 90%)
bundle exec rails test

# Single file
bundle exec rails test test/models/match_test.rb

# Single test by name
bundle exec rails test test/models/match_test.rb -n "test_defaults_origin_to_spark"

# Only model tests
bundle exec rails test test/models

# Only job tests
bundle exec rails test test/jobs
```
