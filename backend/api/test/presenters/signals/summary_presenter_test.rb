# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Signals
      class SummaryPresenterTest < ActiveSupport::TestCase
        setup do
          @health_summary = health_summaries(:alice_summary)
          @preference_profile = preference_profiles(:alice_prefs)
        end

        test "chronotype_label mapping" do
          @health_summary.update!(chronotype: "early_bird")
          assert_equal "Early bird", presenter.call[:summary][:chronotype_label]

          @health_summary.update!(chronotype: "intermediate")
          assert_equal "Flexible", presenter.call[:summary][:chronotype_label]

          @health_summary.update!(chronotype: "night_owl")
          assert_equal "Night owl", presenter.call[:summary][:chronotype_label]
        end

        test "routine_stability_tier mapping" do
          @health_summary.update!(routine_stability_score: 0.3)
          assert_equal "low", presenter.call[:summary][:routine_stability_tier]

          @health_summary.update!(routine_stability_score: 0.4)
          assert_equal "medium", presenter.call[:summary][:routine_stability_tier]

          @health_summary.update!(routine_stability_score: 0.7)
          assert_equal "medium", presenter.call[:summary][:routine_stability_tier]

          @health_summary.update!(routine_stability_score: 0.8)
          assert_equal "high", presenter.call[:summary][:routine_stability_tier]
        end

        test "peak_energy_window with nil values" do
          @health_summary.update!(peak_energy_start_local: nil, peak_energy_end_local: nil)
          assert_nil presenter.call[:summary][:peak_energy_window]
        end

        test "self_report_alignment with nil preference_profile" do
          assert_nil presenter.call(:summary, preference_profile: nil)[:self_report_alignment]
        end

        test "self_report_alignment with depends chronotype" do
          @preference_profile.update!(self_chronotype: "depends")
          assert_equal true, presenter.call[:summary][:self_report_alignment][:aligned]
        end

        test "self_report_alignment mismatch" do
          @health_summary.update!(chronotype: "night_owl")
          @preference_profile.update!(self_chronotype: "morning")
          result = presenter.call[:summary][:self_report_alignment]
          assert_equal false, result[:aligned]
          assert_equal "You declared morning but your data shows night_owl.", result[:note]
        end

        private

        def presenter
          SummaryPresenter.new(@health_summary, @preference_profile)
        end
      end
    end
  end
end

---