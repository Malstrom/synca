# frozen_string_literal: true

class HealthSummarySerializer
  include Alba::Resource

  attributes :chronotype,
             :source,
             :effective_from,
             :effective_to,
             :sleep_start_local,
             :sleep_end_local,
             :avg_sleep_duration_minutes,
             :routine_stability_index,
             :activity_level,
             :peak_energy_start_local,
             :peak_energy_end_local,
             :recovery_score
end
