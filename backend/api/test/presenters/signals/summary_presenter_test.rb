# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::SummaryPresenterTest < ActiveSupport::TestCase
  setup do
    @health_summary = health_summaries(:alice_summary)
    @preference_profile = preference_profiles(:alice_prefs)
  end

  test "chronotype labels" do
    # early_bird
    presenter = Api::V1::Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: @preference_profile
    )
    result = presenter.call
    assert_pattern { result => Success }
    assert_equal "Early bird", result.value![:summary][:chronotype_label]

    # intermediate
    @health_summary.update!(chronotype: "intermediate")
    presenter = Api::V1::Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: @preference_profile
    )
    result = presenter.call
    assert_pattern { result => Success }
    assert_equal "Flexible", result.value![:summary][:chronotype_label]

    # night_owl
    @health_summary.update!(chronotype: "night_owl")
    presenter = Api::V1::Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: @preference_profile
    )
    result = presenter.call
    assert_pattern { result => Success }
    assert_equal "Night owl", result.value![:summary][:chronotype_label]
  end

  test "routine stability tiers" do
    # low
    @health_summary.update!(routine_stability_score: 0.3)
    presenter = Api::V1::Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: @preference_profile
    )
    result = presenter.call
    assert_pattern { result => Success }
    assert_equal "low", result.value![:summary][:routine_stability_tier]

    # medium (boundary)
    @health_summary.update!(routine_stability_score: 0.4)
    presenter = Api::V1::Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: @preference_profile
    )
    result = presenter.call
    assert_pattern { result => Success }
    assert_equal "medium", result.value![:summary][:routine_stability_tier]

    # medium
    @health_summary.update!(routine_stability_score: 0.5)
    presenter = Api::V1::Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: @preference_profile
    )
    result = presenter.call
    assert_pattern { result => Success }
    assert_equal "medium", result.value![:summary][:routine_stability_tier]

    # high (boundary)
    @health_summary.update!(routine_stability_score: 0.7)
    presenter = Api::V1::Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: @preference_profile
    )
    result = presenter.call
    assert_pattern { result => Success }
    assert_equal "medium", result.value![:summary][:routine_stability_tier]

    # high
    @health_summary.update!(routine_stability_score: 0.8)
    presenter = Api::V1::Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: @preference_profile
    )
    result = presenter.call
    assert_pattern { result => Success }
    assert_equal "high", result.value![:summary][:routine_stability_tier]
  end

  test "peak energy window nil" do
    @health_summary.update!(peak_energy_start_local: nil)
    presenter = Api::V1::Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: @preference_profile
    )
    result = presenter.call
    assert_pattern { result => Success }
    assert_nil result.value![:summary][:peak_energy_window]
  end

  test "self report alignment nil" do
    presenter = Api::V1::Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: nil
    )
    result = presenter.call
    assert_pattern { result => Success }
    assert_nil result.value![:summary][:self_report_alignment]
  end

  test "self report alignment mismatch" do
    presenter = Api::V1::Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: @preference_profile
    )
    result = presenter.call
    assert_pattern { result => Success }
    assert_equal false, result.value![:summary][:self_report_alignment][:aligned]
    assert result.value![:summary][:self_report_alignment][:note].present?
  end

  test "self report alignment depends" do
    @preference_profile.update!(self_chronotype: "depends")
    presenter = Api::V1::Signals::SummaryPresenter.new(
      health_summary: @health_summary,
      preference_profile: @preference_profile
    )
    result = presenter.call
    assert_pattern { result => Success }
    assert_equal true, result.value![:summary][:self_report_alignment][:aligned]
    assert_nil result.value![:summary][:self_report_alignment][:note]
  end
end