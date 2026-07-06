# frozen_string_literal: true

class HealthSummaryContract < Dry::Validation::Contract
  params do
    required(:health_summary).hash do
      required(:effective_from).filled(:date)
      optional(:chronotype).maybe(:string)
      optional(:source).maybe(:string)
      optional(:effective_to).maybe(:date)
      optional(:avg_sleep_duration_minutes).maybe(:integer)
      optional(:routine_stability_index).maybe(:float)
      optional(:activity_level).maybe(:string)
      optional(:recovery_score).maybe(:string)
      optional(:sleep_start_local).maybe(:string)
      optional(:sleep_end_local).maybe(:string)
      optional(:peak_energy_start_local).maybe(:string)
      optional(:peak_energy_end_local).maybe(:string)
    end
  end

  rule(:health_summary) do
    next if schema_error?(:health_summary)

    hs = values.to_h[:health_summary]
    next unless hs.is_a?(Hash) && hs[:effective_to] && hs[:effective_from]

    key([:health_summary, :effective_to]).failure("must be after effective_from") if hs[:effective_to] < hs[:effective_from]
  end

  rule(health_summary: :chronotype) do
    next if schema_error?(:health_summary)
    next unless value
    key.failure("is not included in the list") unless HealthSummary.chronotypes.key?(value)
  end

  rule(health_summary: :source) do
    next if schema_error?(:health_summary)
    next unless value
    key.failure("is not included in the list") unless HealthSummary.sources.key?(value)
  end

  rule(health_summary: :activity_level) do
    next if schema_error?(:health_summary)
    next unless value
    key.failure("is not included in the list") unless HealthSummary.activity_levels.key?(value)
  end

  rule(health_summary: :recovery_score) do
    next if schema_error?(:health_summary)
    next unless value
    key.failure("is not included in the list") unless HealthSummary.recovery_scores.key?(value)
  end

  rule(health_summary: :avg_sleep_duration_minutes) do
    next if schema_error?(:health_summary)
    next unless value

    min = Settings.health_summary.avg_sleep_duration_minutes.min
    key.failure("must be greater than #{min}") unless value > min
  end

  rule(health_summary: :routine_stability_index) do
    next if schema_error?(:health_summary)
    next unless value

    min = Settings.health_summary.routine_stability_index.min
    max = Settings.health_summary.routine_stability_index.max
    key.failure("must be between #{min} and #{max}") unless value >= min && value <= max
  end
end
