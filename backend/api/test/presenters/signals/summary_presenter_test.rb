# frozen_string_literal: true

require "test_helper"

class Signals::SummaryPresenterTest < ActiveSupport::TestCase
  setup do
    @health_summary = health_summaries(:alice_summary)
    @preference_profile = preference_profiles(:alice_prefs)
  end

  test "chronotype labels" do
    presenter = Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: @preference_profile
    )

    assert_equal "Early bird", presenter.call[:summary][:chronotype_label]

    @health_summary.chronotype = "intermediate"
    assert_equal "Flexible", presenter.call[:summary][:chronotype_label]

    @health_summary.chronotype = "night_owl"
    assert_equal "Night owl", presenter.call[:summary][:chronotype_label]
  end

  test "routine stability tiers" do
    presenter = Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: @preference_profile
    )

    @health_summary.routine_stability_score = 0.3
    assert_equal "low", presenter.call[:summary][:routine_stability_tier]

    @health_summary.routine_stability_score = 0.4
    assert_equal "medium", presenter.call[:summary][:routine_stability_tier]

    @health_summary.routine_stability_score = 0.5
    assert_equal "medium", presenter.call[:summary][:routine_stability_tier]

    @health_summary.routine_stability_score = 0.7
    assert_equal "medium", presenter.call[:summary][:routine_stability_tier]

    @health_summary.routine_stability_score = 0.8
    assert_equal "high", presenter.call[:summary][:routine_stability_tier]
  end

  test "peak energy window" do
    presenter = Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: @preference_profile
    )

    assert_equal "06:00–08:00", presenter.call[:summary][:peak_energy_window]

    @health_summary.peak_energy_start_local = nil
    assert_nil presenter.call[:summary][:peak_energy_window]

    @health_summary.peak_energy_start_local = Time.zone.parse("06:00")
    @health_summary.peak_energy_end_local = nil
    assert_nil presenter.call[:summary][:peak_energy_window]
  end

  test "self report alignment" do
    presenter = Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: @preference_profile
    )

    assert_equal false, presenter.call[:summary][:self_report_alignment][:aligned]

    @preference_profile.self_chronotype = "morning"
    assert_equal false, presenter.call[:summary][:self_report_alignment][:aligned]
    assert_equal "You declared morning but your data shows early_bird.", presenter.call[:summary][:self_report_alignment][:note]

    @preference_profile.self_chronotype = "depends"
    assert_equal true, presenter.call[:summary][:self_report_alignment][:aligned]
    assert_nil presenter.call[:summary][:self_report_alignment][:note]

    presenter = Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: nil
    )
    assert_nil presenter.call[:summary][:self_report_alignment]
  end
end
