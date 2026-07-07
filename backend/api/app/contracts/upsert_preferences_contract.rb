# frozen_string_literal: true

class UpsertPreferencesContract < Dry::Validation::Contract
  params do
    required(:preferences).hash do
      optional(:sleep_together_importance).maybe(:integer)
      optional(:temperature_preference).maybe(:string, included_in?: PreferenceProfile.temperature_preferences.keys)
      optional(:movement_preference).maybe(:string, included_in?: PreferenceProfile.movement_preferences.keys)
      optional(:rhythm_importance).maybe(:integer)
      optional(:self_chronotype).maybe(:string, included_in?: PreferenceProfile.self_chronotypes.keys)
    end
  end

  rule(preferences: :sleep_together_importance) do
    next if schema_error?(:preferences)
    next unless value

    key.failure("must be between 1 and 5") unless value.between?(1, 5)
  end

  rule(preferences: :rhythm_importance) do
    next if schema_error?(:preferences)
    next unless value

    key.failure("must be between 1 and 5") unless value.between?(1, 5)
  end
end