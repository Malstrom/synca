# frozen_string_literal: true

class UpsertPreferencesContract < ApplicationContract
  params do
    required(:preferences).schema do
      optional(:sleep_together_importance).maybe(:integer)
      optional(:temperature_preference).maybe(:string)
      optional(:movement_preference).maybe(:string)
      optional(:rhythm_importance).maybe(:integer)
      optional(:self_chronotype).maybe(:string)
    end
  end

  rule(:preferences) do
    if values[:preferences][:sleep_together_importance] &&
       (values[:preferences][:sleep_together_importance] < 1 || values[:preferences][:sleep_together_importance] > 5)
      key.failure('must be between 1 and 5')
    end

    if values[:preferences][:temperature_preference] &&
       !PreferenceProfile.temperature_preferences.keys.include?(values[:preferences][:temperature_preference])
      key.failure("must be one of: #{PreferenceProfile.temperature_preferences.keys.join(', ')}")
    end

    if values[:preferences][:movement_preference] &&
       !PreferenceProfile.movement_preferences.keys.include?(values[:preferences][:movement_preference])
      key.failure("must be one of: #{PreferenceProfile.movement_preferences.keys.join(', ')}")
    end

    if values[:preferences][:rhythm_importance] &&
       (values[:preferences][:rhythm_importance] < 1 || values[:preferences][:rhythm_importance] > 5)
      key.failure('must be between 1 and 5')
    end

    if values[:preferences][:self_chronotype] &&
       !PreferenceProfile.self_chronotypes.keys.include?(values[:preferences][:self_chronotype])
      key.failure("must be one of: #{PreferenceProfile.self_chronotypes.keys.join(', ')}")
    end
  end
end
