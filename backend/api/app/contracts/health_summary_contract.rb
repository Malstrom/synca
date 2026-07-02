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

  VALID_CHRONOTYPES     = %w[early_bird intermediate night_owl].freeze
  VALID_ACTIVITY_LEVELS = %w[low medium high].freeze
  VALID_RECOVERY_SCORES = %w[low medium high].freeze
  VALID_SOURCES         = %w[apple_health health_connect].freeze

  rule(health_summary: :chronotype) do
    next unless value
    key.failure("must be early_bird, intermediate or night_owl") unless
      VALID_CHRONOTYPES.include?(value)
  end

  rule(health_summary: :activity_level) do
    next unless value
    key.failure("must be low, medium or high") unless
      VALID_ACTIVITY_LEVELS.include?(value)
  end

  rule(health_summary: :recovery_score) do
    next unless value
    key.failure("must be low, medium or high") unless
      VALID_RECOVERY_SCORES.include?(value)
  end

  rule(health_summary: :source) do
    next unless value
    key.failure("must be apple_health or health_connect") unless
      VALID_SOURCES.include?(value)
  end

  rule(health_summary: :routine_stability_index) do
    next unless value
    key.failure("must be between 0 and 1") unless value >= 0.0 && value <= 1.0
  end

  rule(health_summary: :avg_sleep_duration_minutes) do
    next unless value
    key.failure("must be greater than 0") unless value > 0
  end

  rule(:health_summary) do
    hs = value
    next unless hs[:effective_to] && hs[:effective_from]
    if hs[:effective_to] < hs[:effective_from]
      key([:health_summary, :effective_to]).failure("must be after effective_from")
    end
  end
end
