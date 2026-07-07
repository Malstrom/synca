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

    assert_equal "Early bird", presenter.call[:chronotype_label]
  end

  test "routine stability tiers" do
    presenter = Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: @preference_profile
    )

    assert_equal "high", presenter.call[:routine_stability_tier]
  end

  test "peak energy window nil" do
    health_summary = HealthSummary.new(
      peak_energy_start_local: nil,
      peak_energy_end_local: nil
    )

    presenter = Signals::SummaryPresenter.new(
      health_summary: health_summary,
      preference_profile: @preference_profile
    )

    assert_nil presenter.call[:peak_energy_window]
  end

  test "self report alignment nil" do
    presenter = Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: nil
    )

    assert_nil presenter.call[:self_report_alignment]
  end

  test "self report alignment mismatch" do
    presenter = Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: @preference_profile
    )

    assert_equal false, presenter.call[:self_report_alignment][:aligned]
    assert presenter.call[:self_report_alignment][:note].present?
  end
end