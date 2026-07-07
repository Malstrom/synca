# frozen_string_literal: true

class SignalsSummaryService
  include Dry::Monads[:result]

  def self.call(health_summary:)
    new(health_summary: health_summary).call
  end

  def initialize(health_summary:)
    @health_summary = health_summary
  end

  def call
    summary = {
      chronotype_label: chronotype_label,
      peak_energy_window: peak_energy_window,
      routine_stability_tier: routine_stability_tier,
      activity_tier: activity_tier,
      avg_sleep_duration_minutes: avg_sleep_duration_minutes,
      self_report_alignment: self_report_alignment
    }

    Success(summary)
  end

  private

    attr_reader :health_summary

    def chronotype_label
      case health_summary.chronotype
      when "early_bird" then "Early bird"
      when "intermediate" then "Flexible"
      when "night_owl" then "Night owl"
      end
    end

    def peak_energy_window
      return nil if health_summary.peak_energy_start_local.nil? || health_summary.peak_energy_end_local.nil?

      "#{health_summary.peak_energy_start_local.strftime("%H:%M")}–#{health_summary.peak_energy_end_local.strftime("%H:%M")}"
    end

    def routine_stability_tier
      case health_summary.routine_stability_index
      when 0.0..0.4 then "low"
      when 0.4..0.7 then "medium"
      when 0.7..1.0 then "high"
      end
    end

    def activity_tier
      health_summary.activity_level
    end

    def avg_sleep_duration_minutes
      (health_summary.sleep_duration_avg * 60).to_i
    end

    def self_report_alignment
      return nil if health_summary.user.preference_profile.nil? || health_summary.user.preference_profile.self_chronotype.nil?

      self_chronotype = health_summary.user.preference_profile.self_chronotype
      chronotype = health_summary.chronotype

      if self_chronotype == "depends"
        { aligned: true }
      elsif chronotype == "early_bird" && self_chronotype == "morning" ||
            chronotype == "night_owl" && self_chronotype == "night"
        { aligned: true }
      else
        { aligned: false, note: I18n.t("signals.summary.alignment_note", chronotype: chronotype) }
      end
    end
end
