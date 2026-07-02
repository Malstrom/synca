# frozen_string_literal: true

class HealthSummarySerializer
  include Alba::Resource

  attributes :chronotype,
             :source,
             :effective_from,
             :effective_to,
             :avg_sleep_duration_minutes,
             :routine_stability_index,
             :activity_level,
             :recovery_score,
             :sleep_start_local,
             :sleep_end_local,
             :peak_energy_start_local,
             :peak_energy_end_local
end
