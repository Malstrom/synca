# frozen_string_literal: true

class UpsertPreferencesContract < Dry::Validation::Contract
  params do
    required(:preferences).hash do
      optional(:sleep_together_importance).maybe(:integer)
      optional(:rhythm_importance).maybe(:integer)
      optional(:temperature_preference).maybe(:string)
      optional(:movement_preference).maybe(:string)
      optional(:self_chronotype).maybe(:string)
    end
  end

  rule(preferences: :sleep_together_importance) do
    next unless value
    key.failure("must be between 1 and 5") unless (1..5).cover?(value)
  end

  rule(preferences: :rhythm_importance) do
    next unless value
    key.failure("must be between 1 and 5") unless (1..5).cover?(value)
  end

  rule(preferences: :temperature_preference) do
    next unless value
    key.failure("must be cool, warm, or no_preference") unless
      PreferenceProfile.temperature_preferences.keys.include?(value)
  end

  rule(preferences: :movement_preference) do
    next unless value
    key.failure("must be very_little, moderate, a_lot, or as_much_as_possible") unless
      PreferenceProfile.movement_preferences.keys.include?(value)
  end

  rule(preferences: :self_chronotype) do
    next unless value
    key.failure("must be morning, night, or depends") unless
      PreferenceProfile.self_chronotypes.keys.include?(value)
  end
end
