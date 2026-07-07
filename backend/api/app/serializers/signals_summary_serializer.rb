# frozen_string_literal: true

class SignalsSummarySerializer
  include Alba::Resource

  attribute(:summary) { |obj| {
    chronotype_label: obj.chronotype_label,
    peak_energy_window: obj.peak_energy_window,
    routine_stability_tier: obj.routine_stability_tier,
    activity_tier: obj.activity_tier,
    avg_sleep_duration_minutes: obj.avg_sleep_duration_minutes,
    self_report_alignment: obj.self_report_alignment
  } }
end
