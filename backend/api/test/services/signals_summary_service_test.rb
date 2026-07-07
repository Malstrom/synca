# frozen_string_literal: true

require "test_helper"

class SignalsSummaryServiceTest < ActiveSupport::TestCase
  setup do
    @health_summary = health_summaries(:alice_health)
  end

  test "returns success with health summary" do
    result = SignalsSummaryService.call(health_summary: @health_summary)

    assert result.success?
    assert_equal @health_summary, result.value!
  end
end