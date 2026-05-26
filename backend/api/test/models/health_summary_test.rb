require "test_helper"

class HealthSummaryTest < ActiveSupport::TestCase
  test "valid health summary" do
    assert health_summaries(:alice_health).valid?
  end

  test "invalid without chronotype" do
    hs = health_summaries(:alice_health)
    hs.chronotype = nil
    assert_not hs.valid?
  end

  test "invalid without source" do
    hs = health_summaries(:alice_health)
    hs.source = nil
    assert_not hs.valid?
  end

  test "invalid without effective_from" do
    hs = health_summaries(:alice_health)
    hs.effective_from = nil
    assert_not hs.valid?
  end

  test "routine_stability_index must be between 0 and 1" do
    hs = health_summaries(:alice_health)
    hs.routine_stability_index = 1.5
    assert_not hs.valid?

    hs.routine_stability_index = -0.1
    assert_not hs.valid?

    hs.routine_stability_index = 0.5
    assert hs.valid?
  end

  test "effective_to must be after effective_from" do
    hs = health_summaries(:alice_health)
    hs.effective_to = hs.effective_from - 1.day
    assert_not hs.valid?
    assert hs.errors[:effective_to].any?
  end

  test "active scope returns records without effective_to" do
    assert_includes HealthSummary.active, health_summaries(:alice_health)
  end
end
