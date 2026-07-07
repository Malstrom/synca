# frozen_string_literal: true

require "test_helper"

class SignalsSummaryServiceTest < ActiveSupport::TestCase
  setup do
    @health_summary = health_summaries(:alice_health)
    @preference_profile = preference_profiles(:alice_preferences)
  end

  test "call with early_bird chronotype" do
    @health_summary.update!(chronotype: "early_bird")
    @preference_profile.update!(self_chronotype: "morning")

    result = SignalsSummaryService.call(health_summary: @health_summary)

    assert result.success?
    assert_equal "Early bird", result.value![:chronotype_label]
    assert_equal "06:00–08:00", result.value![:peak_energy_window]
    assert_equal "high", result.value![:routine_stability_tier]
    assert_equal "moderate", result.value![:activity_tier]
    assert_equal 437, result.value![:avg_sleep_duration_minutes]
    assert_equal true, result.value![:self_report_alignment][:aligned]
  end

  test "call with intermediate chronotype" do
    @health_summary.update!(chronotype: "intermediate")
    @preference_profile.update!(self_chronotype: "depends")

    result = SignalsSummaryService.call(health_summary: @health_summary)

    assert result.success?
    assert_equal "Flexible", result.value![:chronotype_label]
    assert_equal true, result.value![:self_report_alignment][:aligned]
  end

  test "call with night_owl chronotype" do
    @health_summary.update!(chronotype: "night_owl")
    @preference_profile.update!(self_chronotype: "night")

    result = SignalsSummaryService.call(health_summary: @health_summary)

    assert result.success?
    assert_equal "Night owl", result.value![:chronotype_label]
    assert_equal true, result.value![:self_report_alignment][:aligned]
  end

  test "call with mismatched chronotype" do
    @health_summary.update!(chronotype: "early_bird")
    @preference_profile.update!(self_chronotype: "night")

    result = SignalsSummaryService.call(health_summary: @health_summary)

    assert result.success?
    assert_equal false, result.value![:self_report_alignment][:aligned]
    assert_equal I18n.t("signals.summary.alignment_note", chronotype: "early_bird"), result.value![:self_report_alignment][:note]
  end

  test "call with nil peak_energy_window" do
    @health_summary.update!(peak_energy_start_local: nil, peak_energy_end_local: nil)

    result = SignalsSummaryService.call(health_summary: @health_summary)

    assert result.success?
    assert_nil result.value![:peak_energy_window]
  end

  test "call with nil self_report_alignment" do
    @preference_profile.update!(self_chronotype: nil)

    result = SignalsSummaryService.call(health_summary: @health_summary)

    assert result.success?
    assert_nil result.value![:self_report_alignment]
  end
end