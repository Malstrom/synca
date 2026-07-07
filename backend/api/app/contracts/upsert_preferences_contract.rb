# frozen_string_literal: true

class UpsertPreferencesContract < Dry::Validation::Contract
  params do
    required(:preferences).hash do
      optional(:sleep_together_importance).maybe(:integer, included_in?: 1..5)
      optional(:temperature_preference).maybe(:string, included_in?: PreferenceProfile.temperature_preferences.keys)
      optional(:movement_preference).maybe(:string, included_in?: PreferenceProfile.movement_preferences.keys)
      optional(:rhythm_importance).maybe(:integer, included_in?: 1..5)
      optional(:self_chronotype).maybe(:string, included_in?: PreferenceProfile.self_chronotypes.keys)
    end
  end
end