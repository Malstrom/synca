# frozen_string_literal: true

# Value object returned by SignalsSummaryService.
# Immutable by convention: all attributes are read-only.
class SignalsSummary
  attr_reader :chronotype_label,
              :peak_energy_window,
              :routine_stability_tier,
              :activity_tier,
              :avg_sleep_duration_minutes,
              :self_report_alignment

  def initialize(
    chronotype_label:,
    peak_energy_window:,
    routine_stability_tier:,
    activity_tier:,
    avg_sleep_duration_minutes:,
    self_report_alignment:
  )
    @chronotype_label           = chronotype_label
    @peak_energy_window         = peak_energy_window
    @routine_stability_tier     = routine_stability_tier
    @activity_tier              = activity_tier
    @avg_sleep_duration_minutes = avg_sleep_duration_minutes
    @self_report_alignment      = self_report_alignment
  end
end
