# frozen_string_literal: true

module Signals
  class SummaryPresenter
    include ActionView::Helpers::NumberHelper

    CHRONOTYPE_LABELS = {
      "morning" => "Morning",
      "evening" => "Evening",
      "intermediate" => "Intermediate"
    }.freeze

    ROUTINE_STABILITY_TIERS = [
      (0..25).freeze => "Low",
      (26..50).freeze => "Medium",
      (51..75).freeze => "High",
      (76..100).freeze => "Very High"
    ].freeze

    attr_reader :health_summary, :user

    def initialize(health_summary:, user:)
      @health_summary = health_summary
      @user = user
    end

    def as_json
      {
        chronotype: chronotype,
        chronotype_label: chronotype_label,
        peak_energy_window: peak_energy_window,
        routine_stability_tier: routine_stability_tier,
        activity_tier: activity_tier,
        self_report_alignment: self_report_alignment
      }
    end

    def chronotype
      health_summary.chronotype
    end

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

      if user.preference_profile.chronotype == health_summary.chronotype
        { aligned: true }
      else
        {
          aligned: false,
          note: "You declared \"#{user.preference_profile.chronotype.humanize}\" but your data shows an average wake time of #{format_time(health_summary.sleep_start_local)}."
        }
      end
    end

    def format_time(time)
      time.strftime("%H:%M")
    end
  end
end
