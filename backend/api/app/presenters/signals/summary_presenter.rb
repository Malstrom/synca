# frozen_string_literal: true

module Signals
  class SummaryPresenter
    CHRONOTYPE_LABELS = {
      "early_bird" => "Early bird",
      "intermediate" => "Flexible",
      "night_owl" => "Night owl"
    }.freeze

    ROUTINE_STABILITY_TIERS = {
      0..0.39 => "low",
      0.4..0.7 => "medium",
      0.71..1.0 => "high"
    }.freeze

    def initialize(health_summary:, user:)
      @health_summary = health_summary
      @user = user
    end

    def as_json
      {
        chronotype_label: chronotype_label,
        peak_energy_window: peak_energy_window,
        routine_stability_tier: routine_stability_tier,
        activity_tier: activity_tier,
        avg_sleep_duration_minutes: health_summary.avg_sleep_duration_minutes,
        self_report_alignment: self_report_alignment
      }
    end

    private

      attr_reader :health_summary, :user

      def chronotype_label
        CHRONOTYPE_LABELS[health_summary.chronotype]
      end

      def peak_energy_window
        return nil if health_summary.peak_energy_start_local.nil? || health_summary.peak_energy_end_local.nil?

        "#{format_time(health_summary.peak_energy_start_local)}–#{format_time(health_summary.peak_energy_end_local)}"
      end

      def routine_stability_tier
        ROUTINE_STABILITY_TIERS.find { |range, _| range.include?(health_summary.routine_stability_index) }&.last
      end

      def activity_tier
        health_summary.activity_level
      end

      def self_report_alignment
        return nil unless user.preference_profile

        if user.preference_profile.self_chronotype == health_summary.chronotype
          { aligned: true }
        else
          {
            aligned: false,
            note: "You declared \"#{user.preference_profile.self_chronotype.humanize}\" but your data shows an average wake time of #{format_time(health_summary.sleep_start_local)}."
          }
        end
      end

      def format_time(time)
        time.strftime("%H:%M")
      end
  end
end
