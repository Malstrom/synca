# frozen_string_literal: true

class UpsertPreferencesContract < Dry::Validation::Contract
  params do
    required(:preferences).hash do
      optional(:sleep_together_importance).maybe(:integer)
      optional(:temperature_preference).maybe(:string)
      optional(:movement_preference).maybe(:string)
      optional(:rhythm_importance).maybe(:integer)
      optional(:self_chronotype).maybe(:string)
    end
  end

  VALID_TEMPERATURE_PREFERENCES = %w[cool warm no_preference].freeze
  VALID_MOVEMENT_PREFERENCES = %w[very_little moderate a_lot as_much_as_possible].freeze
  VALID_SELF_CHRONOTYPES = %w[morning night depends].freeze

  rule(preferences: :temperature_preference) do
    next unless value
    key.failure("must be cool, warm or no_preference") unless
      VALID_TEMPERATURE_PREFERENCES.include?(value)
  end

  rule(preferences: :movement_preference) do
    next unless value
    key.failure("must be very_little, moderate, a_lot or as_much_as_possible") unless
      VALID_MOVEMENT_PREFERENCES.include?(value)
  end

  rule(preferences: :self_chronotype) do
    next unless value
    key.failure("must be morning, night or depends") unless
      VALID_SELF_CHRONOTYPES.include?(value)
  end

  rule(preferences: :sleep_together_importance) do
    next unless value
    key.failure("must be between 1 and 5") unless value >= 1 && value <= 5
  end

  rule(preferences: :rhythm_importance) do
    next unless value
    key.failure("must be between 1 and 5") unless value >= 1 && value <= 5
  end
end
