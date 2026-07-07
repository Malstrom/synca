# frozen_string_literal: true

require "test_helper"

module Signals
  class SummaryPresenterTest < ActiveSupport::TestCase
    setup do
      @health_summary = health_summaries(:one)
      @preference_profile = preference_profiles(:one)
    end

    test "chronotype_label returns correct labels" do
      @health_summary.chronotype = "early_bird"
      assert_equal "Early bird", SummaryPresenter.new(@health_summary, nil).call.dig(:summary, :chronotype_label)

      @health_summary.chronotype = "intermediate"
      assert_equal "Flexible", SummaryPresenter.new(@health_summary, nil).call.dig(:summary, :chronotype_label)

      @health_summary.chronotype = "night_owl"
      assert_equal "Night owl", SummaryPresenter.new(@health_summary, nil).call.dig(:summary, :chronotype_label)
    end

    test "peak_energy_window returns nil when either time is nil" do
      @health_summary.peak_energy_start_local = nil
      assert_nil SummaryPresenter.new(@health_summary, nil).call.dig(:summary, :peak_energy_window)

      @health_summary.peak_energy_start_local = Time.zone.parse("07:00")
      @health_summary.peak_energy_end_local = nil
      assert_nil SummaryPresenter.new(@health_summary, nil).call.dig(:summary, :peak_energy_window)
    end

    test "routine_stability_tier returns correct tiers" do
      @health_summary.routine_stability_index = 0.3
      assert_equal "low", SummaryPresenter.new(@health_summary, nil).call.dig(:summary, :routine_stability_tier)

      @health_summary.routine_stability_index = 0.4
      assert_equal "medium", SummaryPresenter.new(@health_summary, nil).call.dig(:summary, :routine_stability_tier)

      @health_summary.routine_stability_index = 0.5
      assert_equal "medium", SummaryPresenter.new(@health_summary, nil).call.dig(:summary, :routine_stability_tier)

      @health_summary.routine_stability_index = 0.7
      assert_equal "medium", SummaryPresenter.new(@health_summary, nil).call.dig(:summary, :routine_stability_tier)

      @health_summary.routine_stability_index = 0.8
      assert_equal "high", SummaryPresenter.new(@health_summary, nil).call.dig(:summary, :routine_stability_tier)
    end

    test "self_report_alignment returns nil when preference_profile is nil" do
      assert_nil SummaryPresenter.new(@health_summary, nil).call.dig(:summary, :self_report_alignment)
    end

    test "self_report_alignment returns correct alignment" do
      @preference_profile.self_chronotype = "morning"
      @health_summary.chronotype = "early_bird"
      assert SummaryPresenter.new(@health_summary, @preference_profile).call.dig(:summary, :self_report_alignment, :aligned)

      @preference_profile.self_chronotype = "morning"
      @health_summary.chronotype = "night_owl"
      refute SummaryPresenter.new(@health_summary, @preference_profile).call.dig(:summary, :self_report_alignment, :aligned)

      @preference_profile.self_chronotype = "night"
      @health_summary.chronotype = "night_owl"
      assert SummaryPresenter.new(@health_summary, @preference_profile).call.dig(:summary, :self_report_alignment, :aligned)

      @preference_profile.self_chronotype = "night"
      @health_summary.chronotype = "early_bird"
      refute SummaryPresenter.new(@health_summary, @preference_profile).call.dig(:summary, :self_report_alignment, :aligned)

      @preference_profile.self_chronotype = "depends"
      @health_summary.chronotype = "early_bird"
      assert SummaryPresenter.new(@health_summary, @preference_profile).call.dig(:summary, :self_report_alignment, :aligned)
    end
  end
end
