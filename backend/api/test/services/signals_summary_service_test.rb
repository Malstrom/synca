# frozen_string_literal: true

require "test_helper"

class SignalsSummaryServiceTest < ActiveSupport::TestCase
  # alice_health: chronotype=early_bird, routine_stability_index=0.82 (high),
  #               activity_level=medium, avg_sleep_duration_minutes=450
  #               peak_energy_start_local=nil, peak_energy_end_local=nil
  # alice_preferences: self_chronotype=morning -> maps to early_bird -> aligned=true

  setup do
    @user        = users(:alice)
    @health      = health_summaries(:alice_health)
    @prefs       = preference_profiles(:alice_prefs)
  end

  test "call with active health_summary returns Success with correct labels" do
    result = SignalsSummaryService.call(user: @user)

    assert result.success?
    record = result.value!

    assert_equal "Early bird", record.chronotype_label
    assert_equal "high",       record.routine_stability_tier
    assert_equal "medium",     record.activity_tier
    assert_equal 450,          record.avg_sleep_duration_minutes
    assert_nil record.peak_energy_window
  end

  test "call returns self_report_alignment aligned when self_chronotype matches" do
    # alice: self_chronotype=morning -> early_bird == early_bird -> aligned
    result = SignalsSummaryService.call(user: @user)
    alignment = result.value!.self_report_alignment

    assert_equal true, alignment[:aligned]
    assert_nil alignment[:note]
  end

  test "call returns self_report_alignment misaligned with note" do
    @prefs.update!(self_chronotype: :night)
    result = SignalsSummaryService.call(user: @user)
    alignment = result.value!.self_report_alignment

    assert_equal false, alignment[:aligned]
    assert_equal I18n.t("self_report_alignment.note", self_chronotype: "night", chronotype: "Early bird"),
                 alignment[:note]
  end

  test "call returns self_report_alignment nil when self_chronotype is nil" do
    @prefs.update!(self_chronotype: nil)
    result = SignalsSummaryService.call(user: @user)

    assert_nil result.value!.self_report_alignment
  end

  test "call returns self_report_alignment aligned when self_chronotype is depends" do
    @prefs.update!(self_chronotype: :depends)
    result = SignalsSummaryService.call(user: @user)
    alignment = result.value!.self_report_alignment

    assert_equal true, alignment[:aligned]
    assert_nil alignment[:note]
  end

  test "call returns peak_energy_window formatted as HH:MM when times present" do
    @health.update!(
      peak_energy_start_local: Time.zone.parse("2026-01-01 09:00"),
      peak_energy_end_local:   Time.zone.parse("2026-01-01 11:00")
    )
    result = SignalsSummaryService.call(user: @user)

    assert_equal "09:00\u201311:00", result.value!.peak_energy_window
  end

  test "call returns routine_stability_tier nil for out-of-range index" do
    @health.update!(routine_stability_index: 1.5)
    result = SignalsSummaryService.call(user: @user)

    assert_nil result.value!.routine_stability_tier
  end

  test "call without active health_summary returns Failure[:no_signals]" do
    @health.update!(effective_to: Time.current)
    result = SignalsSummaryService.call(user: @user)

    assert result.failure?
    assert_equal [:no_signals, I18n.t("signals_summary.no_signals")], result.failure
  end
end
