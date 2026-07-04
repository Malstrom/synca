# frozen_string_literal: true

class UpsertPreferencesContract < ApplicationContract
  params do
    required(:preferences).schema do
      optional(:sleep_together_importance).filled(:integer, included_in?: 1..5)
      optional(:temperature_preference).filled(:string, included_in?: PreferenceProfile.temperature_preferences.keys)
      optional(:movement_preference).filled(:string, included_in?: PreferenceProfile.movement_preferences.keys)
      optional(:rhythm_importance).filled(:integer, included_in?: 1..5)
      optional(:self_chronotype).filled(:string, included_in?: PreferenceProfile.self_chronotypes.keys)
    end
  end

  rule(:preferences) do
    key.failure('must contain at least one preference') if values[:preferences].blank?
  end
end
