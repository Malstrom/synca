# frozen_string_literal: true

class PreferencesSerializer
  include JSONAPI::Serializer

  attributes :sleep_together_importance,
             :temperature_preference,
             :movement_preference,
             :rhythm_importance,
             :self_chronotype
end
