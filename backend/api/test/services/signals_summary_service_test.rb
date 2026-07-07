# frozen_string_literal: true

require "test_helper"

class SignalsSummaryServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @health_summary = health_summaries(:alice_health)
    @preference_profile = preference_profiles(:alice_preferences)
  end

  test "call with active health_summary → Success" do
    result = SignalsSummaryService.call(user: @user)

    assert result.success?
    record = result.value!

    case @health_summary.chronotype
    when "early_bird" then expected_label = "Early bird"
    when "intermediate" then expected_label = "Flexible"
    when "night_owl" then expected_label = "Night owl"
    end
    assert_equal expected_label, record.chronotype_label

    expected_window = "#{@health_summary.peak_energy_start_local}–#{@health_summary.peak_energy_end_local}"
    assert_equal expected_window, record.peak_energy_window

    case @health_summary.routine_stability_index
    when 0.0...0.4 then expected_tier = "low"
    when 0.4...0.7 then expected_tier = "medium"
    when 0.7..1.0 then expected_tier = "high"
    end
    assert_equal expected_tier, record.routine_stability_tier

    assert_equal @health_summary.activity_level, record.activity_tier
    assert_equal @health_summary.avg_sleep_duration_minutes, record.avg_sleep_duration_minutes

    if @preference_profile.self_chronotype.present?
      expected_aligned = @preference_profile.self_chronotype == "depends" ||
                         chronotype_mapping(@preference_profile.self_chronotype) == @health_summary.chronotype
      assert_equal expected_aligned, record.self_report_alignment[:aligned]

      unless expected_aligned
        assert_equal I18n.t("self_report_alignment.note",
          self_chronotype: self_chronotype_label(@preference_profile.self_chronotype),
          chronotype: expected_label),
          record.self_report_alignment[:note]
      end
    else
      assert_nil record.self_report_alignment
    end
  end

  test "call without active health_summary → Failure[:no_signals]" do
    @health_summary.update!(effective_to: Time.current)
    result = SignalsSummaryService.call(user: @user)

    assert result.failure?
    assert_equal [:no_signals, I18n.t("signals_summary.no_signals")], result.failure
  end

  private

    def chronotype_mapping(self_chronotype)
      case self_chronotype
      when "morning" then "early_bird"
      when "night" then "night_owl"
      end
    end

    def self_chronotype_label(self_chronotype)
      case self_chronotype
      when "morning" then "morning"
      when "night" then "night"
      when "depends" then "depends"
      end
    end
end
