# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::SummaryPresenterTest < ActiveSupport::TestCase
  setup do
    @health_summary = health_summaries(:alice_summary)
    @preference_profile = preference_profiles(:alice_prefs)
  end

  test "chronotype labels" do
    @health_summary.update!(chronotype: "early_bird")
    assert_equal "Early bird", presenter.call[:summary][:chronotype_label]

    @health_summary.update!(chronotype: "intermediate")
    assert_equal "Flexible", presenter.call[:summary][:chronotype_label]

    @health_summary.update!(chronotype: "night_owl")
    assert_equal "Night owl", presenter.call[:summary][:chronotype_label]
  end

  test "routine stability tiers" do
    @health_summary.update!(routine_stability_score: 0.3)
    assert_equal "low", presenter.call[:summary][:routine_stability_tier]

    @health_summary.update!(routine_stability_score: 0.4)
    assert_equal "medium", presenter.call[:summary][:routine_stability_tier]

    @health_summary.update!(routine_stability_score: 0.7)
    assert_equal "medium", presenter.call[:summary][:routine_stability_tier]

    @health_summary.update!(routine_stability_score: 0.8)
    assert_equal "high", presenter.call[:summary][:routine_stability_tier]
  end

  test "peak energy window nil" do
    @health_summary.update!(peak_energy_start_local: nil, peak_energy_end_local: nil)
    assert_nil presenter.call[:summary][:peak_energy_window]

    @health_summary.update!(peak_energy_start_local: Time.zone.parse("06:00"), peak_energy_end_local: nil)
    assert_nil presenter.call[:summary][:peak_energy_window]

    @health_summary.update!(peak_energy_start_local: nil, peak_energy_end_local: Time.zone.parse("08:00"))
    assert_nil presenter.call[:summary][:peak_energy_window]
  end

  test "self report alignment nil" do
    assert_not_nil presenter.call[:summary][:self_report_alignment]

    @preference_profile.destroy
    assert_nil presenter.call[:summary][:self_report_alignment]
  end

  test "self report alignment mismatch" do
    @health_summary.update!(chronotype: "night_owl")
    @preference_profile.update!(self_chronotype: "morning")

    result = presenter.call[:summary][:self_report_alignment]
    assert_equal false, result[:aligned]
    assert_equal "You declared morning but your data shows night_owl.", result[:note]
  end

  test "self report alignment depends" do
    @preference_profile.update!(self_chronotype: "depends")

    result = presenter.call[:summary][:self_report_alignment]
    assert_equal true, result[:aligned]
    assert_nil result[:note]
  end

  private

  def presenter
    Api::V1::Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: @preference_profile
    )
  end
end

---