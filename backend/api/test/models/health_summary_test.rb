# frozen_string_literal: true

require "test_helper"

# HealthSummary model is intentionally thin: enums, association, scope only.
# Validation rules live in HealthSummaryContract — see test/contracts/health_summary_contract_test.rb
class HealthSummaryTest < ActiveSupport::TestCase
  test "valid health summary" do
    assert health_summaries(:alice_health).valid?
  end

  test "active scope returns records without effective_to" do
    assert_includes HealthSummary.active, health_summaries(:alice_health)
  end

  test "chronotype enum maps correctly" do
    hs = health_summaries(:alice_health)
    assert hs.early_bird?
  end

  test "activity_level enum maps correctly" do
    hs = health_summaries(:alice_health)
    assert_includes HealthSummary.activity_levels.keys, hs.activity_level
  end
end
