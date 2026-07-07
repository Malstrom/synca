# frozen_string_literal: true

class SignalsSummaryService
  include Dry::Monads[:result]

  def self.call(user:)
    new(user: user).call
  end

  def initialize(user:)
    @user = user
  end

  def call
    health_summary = user.health_summary
    return Failure[:no_signals, I18n.t("signals_summary.no_signals")] unless health_summary

    Success(
      OpenStruct.new(
        chronotype_label: chronotype_label(health_summary.chronotype),
        peak_energy_window: peak_energy_window(health_summary),
        routine_stability_tier: routine_stability_tier(health_summary.routine_stability_index),
        activity_tier: health_summary.activity_level,
        avg_sleep_duration_minutes: health_summary.avg_sleep_duration_minutes,
        self_report_alignment: self_report_alignment(health_summary)
      )
    )
  end

  private

    attr_reader :user

    def chronotype_label(chronotype)
      case chronotype
      when "early_bird" then "Early bird"
      when "intermediate" then "Flexible"
      when "night_owl" then "Night owl"
      end
    end

    def peak_energy_window(health_summary)
      return nil unless health_summary.peak_energy_start_local && health_summary.peak_energy_end_local

      "#{health_summary.peak_energy_start_local}–#{health_summary.peak_energy_end_local}"
    end

    def routine_stability_tier(routine_stability_index)
      case routine_stability_index
      when 0.0...0.4 then "low"
      when 0.4...0.7 then "medium"
      when 0.7..1.0 then "high"
      end
    end

    def self_report_alignment(health_summary)
      return nil unless health_summary.preference_profile&.self_chronotype

      self_chronotype = health_summary.preference_profile.self_chronotype
      aligned = self_chronotype == "depends" || chronotype_mapping(self_chronotype) == health_summary.chronotype

      {
        aligned: aligned,
        note: aligned ? nil : I18n.t("self_report_alignment.note",
          self_chronotype: self_chronotype_label(self_chronotype),
          chronotype: chronotype_label(health_summary.chronotype))
      }
    end

    def chronotype_mapping(self_chronotype)
      case self_chronotype
      when "morning" then "early_bird"
      when "night" then "night_owl"
      end
    end

    def self_chronotype_label(self_chronotype)
      case self_chronotype
      when "morning" then "morning"
      when "night" then "night"
      when "depends" then "depends"
      end
    end
end