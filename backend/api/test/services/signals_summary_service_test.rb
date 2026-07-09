# frozen_string_literal: true

require "test_helper"

class SignalsSummaryServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @user   = users(:alice)
    @health = health_summaries(:alice_health)
  end

  test "call returns Success with correct SignalsSummary" do
    result = SignalsSummaryService.call(user: @user)

    assert_pattern { result => Success }
    summary = result.value!

    assert_equal Chronotype.label(@health.chronotype),                               summary.chronotype_label
    assert_equal Chronotype.routine_stability_tier(@health.routine_stability_index), summary.routine_stability_tier
    assert_equal @health.activity_level,                                             summary.activity_tier
    assert_equal @health.avg_sleep_duration_minutes,                                 summary.avg_sleep_duration_minutes
    assert_nil   summary.peak_energy_window
  end

  test "call returns self_report_alignment aligned when self_chronotype matches" do
    result    = SignalsSummaryService.call(user: @user)
    alignment = result.value!.self_report_alignment

    assert_equal true, alignment[:aligned]
    assert_nil alignment[:note]
  end

  test "call returns Failure[:no_signals] when no active health_summary" do
    @health.update!(effective_to: Time.current)

    result = SignalsSummaryService.call(user: @user)
    assert_pattern { result => Failure[:no_signals, _] }
  end

  test "call returns Failure[:no_signals] when chronotype is nil" do
    @health.update!(chronotype: nil)

    result = SignalsSummaryService.call(user: @user)
    assert_pattern { result => Failure[:no_signals, _] }
  end
end
