# frozen_string_literal: true

module Signals
  class SummaryPresenter
    def initialize(health_summary:, preference_profile:)
      @health_summary = health_summary
      @preference_profile = preference_profile
    end

    def call
      {
        chronotype_label: chronotype_label,
        peak_energy_window: peak_energy_window,
        routine_stability_tier: routine_stability_tier,
        activity_tier: activity_tier,
        avg_sleep_duration_minutes: avg_sleep_duration_minutes,
        self_report_alignment: self_report_alignment
      }
    end

    private

      attr_reader :health_summary, :preference_profile

      def chronotype_label
        case health_summary.chronotype
        when "early_bird" then "Early bird"
        when "intermediate" then "Flexible"
        when "night_owl" then "Night owl"
        end
      end

      def peak_energy_window
        return nil if health_summary.peak_energy_start_local.nil? || health_summary.peak_energy_end_local.nil?

        "#{health_summary.peak_energy_start_local.strftime('%H:%M')}–#{health_summary.peak_energy_end_local.strftime('%H:%M')}"
      end

      def routine_stability_tier
        case health_summary.routine_stability_score
        when 0.0..0.4 then "low"
        when 0.4..0.7 then "medium"
        else "high"
        end
      end

      def activity_tier
        health_summary.activity_level
      end

      def avg_sleep_duration_minutes
        health_summary.avg_sleep_duration_minutes
      end

      def self_report_alignment
        return nil if preference_profile.nil?

        if preference_profile.self_chronotype == "depends"
          { aligned: true }
        else
          aligned = preference_profile.self_chronotype == chronotype_mapping[health_summary.chronotype]
          { aligned: aligned, note: note } unless aligned
        end
      end

      def chronotype_mapping
        {
          "early_bird" => "morning",
          "night_owl" => "night"
        }
      end

      def note
        "You declared #{preference_profile.self_chronotype} but your data shows #{health_summary.chronotype}."
      end
  end
end
