# frozen_string_literal: true

SignalsSummary = Data.define(
  :chronotype_label,
  :peak_energy_window,
  :routine_stability_tier,
  :activity_tier,
  :avg_sleep_duration_minutes,
  :self_report_alignment
)

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
      SignalsSummary.new(
        chronotype_label:           Chronotype.label(health_summary.chronotype),
        peak_energy_window:         peak_energy_window(health_summary),
        routine_stability_tier:     Chronotype.routine_stability_tier(health_summary.routine_stability_index),
        activity_tier:              health_summary.activity_level,
        avg_sleep_duration_minutes: health_summary.avg_sleep_duration_minutes,
        self_report_alignment:      self_report_alignment(health_summary)
      )
    )
  end

  private

    attr_reader :user

    def peak_energy_window(health_summary)
      start_time = health_summary.peak_energy_start_local
      end_time   = health_summary.peak_energy_end_local
      return nil unless start_time && end_time

      "#{start_time.strftime('%H:%M')}\u2013#{end_time.strftime('%H:%M')}"
    end

    def self_report_alignment(health_summary)
      return nil unless user.preference_profile&.self_chronotype

      self_chronotype = user.preference_profile.self_chronotype
      aligned = self_chronotype == "depends" ||
                Chronotype.observed_from_self(self_chronotype) == health_summary.chronotype

      {
        aligned: aligned,
        note: aligned ? nil : I18n.t(
          "self_report_alignment.note",
          self_chronotype: self_chronotype,
          chronotype:      Chronotype.label(health_summary.chronotype)
        )
      }
    end
end
