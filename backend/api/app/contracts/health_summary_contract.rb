# frozen_string_literal: true

class HealthSummaryContract < Dry::Validation::Contract
  params do
    required(:health_summary).hash do
      required(:effective_from).filled(:date)
      optional(:chronotype).maybe(
        :string,
        included_in?: HealthSummary.chronotypes.keys
      )
      optional(:source).maybe(
        :string,
        included_in?: HealthSummary.sources.keys
      )
      optional(:effective_to).maybe(:date)
      optional(:avg_sleep_duration_minutes).maybe(
        :integer,
        gt?: Settings.health_summary.avg_sleep_duration_minutes.min
      )
      optional(:routine_stability_index).maybe(
        :float,
        gteq?: Settings.health_summary.routine_stability_index.min,
        lteq?: Settings.health_summary.routine_stability_index.max
      )
      optional(:activity_level).maybe(
        :string,
        included_in?: HealthSummary.activity_levels.keys
      )
      optional(:recovery_score).maybe(
        :string,
        included_in?: HealthSummary.recovery_scores.keys
      )
      optional(:sleep_start_local).maybe(:string)
      optional(:sleep_end_local).maybe(:string)
      optional(:peak_energy_start_local).maybe(:string)
      optional(:peak_energy_end_local).maybe(:string)
    end
  end

  rule(:health_summary) do
    hs = value
    next unless hs[:effective_to] && hs[:effective_from]

    if hs[:effective_to] < hs[:effective_from]
      key([:health_summary, :effective_to]).failure("must be after effective_from")
    end
  end
end
