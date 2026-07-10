# frozen_string_literal: true

# Value object returned by SignalsSummaryService.
# Immutable by design (Data.define — Ruby 3.2+).
SignalsSummary = Data.define(
  :chronotype_label,
  :peak_energy_window,
  :routine_stability_tier,
  :activity_tier,
  :avg_sleep_duration_minutes,
  :self_report_alignment
)
