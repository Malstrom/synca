# Rails Testing — Minitest Conventions

Synca uses **Minitest** (Rails default) for all backend tests. No RSpec.

## Directory Structure

```text
backend/api/test/
├── models/
│   ├── user_test.rb
│   ├── health_summary_test.rb
│   ├── trust_score_test.rb
│   ├── match_test.rb
│   └── date_proposal_test.rb
├── services/
│   ├── matching/
│   │   ├── matching_service_test.rb
│   │   └── compatibility_score_service_test.rb
│   └── trust/
│       └── trust_score_service_test.rb
├── controllers/
│   └── api/
│       └── v1/
│           ├── auth_controller_test.rb
│           ├── profiles_controller_test.rb
│           ├── health_summaries_controller_test.rb
│           ├── matches_controller_test.rb
│           └── date_proposals_controller_test.rb
├── fixtures/
│   ├── users.yml
│   ├── health_summaries.yml
│   └── preference_profiles.yml
└── test_helper.rb
```

## test_helper.rb

```ruby
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  fixtures :all

  # Helper to parse JSON response body in controller tests.
  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end
end
```

## Model Test Example

File: `test/models/user_test.rb`

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "is valid with required fields" do
    user = User.new(name: "Alex", age: 28, gender: "male", city: "Moscow",
                    email: "alex@example.com")
    assert user.valid?
  end

  test "is invalid without name" do
    user = User.new(age: 28, gender: "male", city: "Moscow")
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "age must be between 18 and 80" do
    user = User.new(name: "Alex", age: 15, gender: "male", city: "Moscow")
    assert_not user.valid?
  end
end
```

## Service Test Example

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

## Controller Test Example

File: `test/controllers/api/v1/matches_controller_test.rb`

```ruby
require "test_helper"

class Api::V1::MatchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alex)
    @token = generate_token_for(@user) # helper defined in test_helper.rb
  end

  test "GET /api/v1/matches returns match list" do
    get api_v1_matches_url,
        headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :success
    body = json_response
    assert body.key?(:matches)
    assert_kind_of Array, body[:matches]
  end

  test "GET /api/v1/matches returns 401 without token" do
    get api_v1_matches_url
    assert_response :unauthorized
  end
end
```

## Fixture Example

File: `test/fixtures/users.yml`

```yaml
alex:
  name: Alex
  age: 28
  gender: male
  city: Moscow
  email: alex@example.com

maria:
  name: Maria
  age: 27
  gender: female
  city: Moscow
  email: maria@example.com
```

## Running Tests

```bash
# All tests
cd backend/api
bundle exec rails test

# Single file
bundle exec rails test test/models/user_test.rb

# Single test by name
bundle exec rails test test/models/user_test.rb -n "test_is_valid_with_required_fields"

# Only model tests
bundle exec rails test test/models

# Only service tests
bundle exec rails test test/services
```

## Conventions

- One test file per model, service, or controller.
- Test method names start with `test_` and describe the exact behavior under test.
- Use `setup` for shared fixtures within a test class.
- Prefer real objects over mocks; use mocks only for external HTTP calls.
- Each test asserts one thing. Split complex scenarios into multiple small tests.
- Keep fixtures minimal: only the fields needed for the test.
