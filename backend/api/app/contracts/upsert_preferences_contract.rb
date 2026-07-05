# frozen_string_literal: true

class UpsertPreferencesContract < Dry::Validation::Contract
  params do
    required(:preferences).hash do
      optional(:sleep_together_importance).value(included_in?: 1..5)
      optional(:temperature_preference).value(included_in?: PreferenceProfile.temperature_preferences.keys)
      optional(:movement_preference).value(included_in?: PreferenceProfile.movement_preferences.keys)
      optional(:rhythm_importance).value(included_in?: 1..5)
      optional(:self_chronotype).value(included_in?: PreferenceProfile.self_chronotypes.keys)
    end
  end

  rule(:preferences) do
    key.failure('must contain at least one preference') if values[:preferences].empty?
  end
end
