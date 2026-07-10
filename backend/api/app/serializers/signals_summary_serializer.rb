# frozen_string_literal: true

class SignalsSummarySerializer
  include Alba::Resource

  attributes :chronotype_label,
             :peak_energy_window,
             :routine_stability_tier,
             :activity_tier,
             :avg_sleep_duration_minutes,
             :self_report_alignment
end
