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
      optional(:recovery_score).maybe(:integer)
      optional(:sleep_start_local).maybe(:string)
      optional(:sleep_end_local).maybe(:string)
      optional(:peak_energy_start_local).maybe(:string)
      optional(:peak_energy_end_local).maybe(:string)
    end
  end

  VALID_CHRONOTYPES    = %w[morning intermediate evening].freeze
  VALID_ACTIVITY_LEVELS = %w[low medium high].freeze

  rule(health_summary: :chronotype) do
    next unless value
    key.failure("must be morning, intermediate or evening") unless
      VALID_CHRONOTYPES.include?(value)
  end

  rule(health_summary: :activity_level) do
    next unless value
    key.failure("must be low, medium or high") unless
      VALID_ACTIVITY_LEVELS.include?(value)
  end
end
