# frozen_string_literal: true

class SignalsSummarySerializer
  include Alba::Resource

  attribute(:chronotype_label) { |obj| obj.chronotype_label }
  attribute(:peak_energy_window) { |obj| obj.peak_energy_window }
  attribute(:routine_stability_tier) { |obj| obj.routine_stability_tier }
  attribute(:activity_tier) { |obj| obj.activity_tier }
  attribute(:avg_sleep_duration_minutes) { |obj| obj.avg_sleep_duration_minutes }
  attribute(:self_report_alignment) { |obj| obj.self_report_alignment }
end
