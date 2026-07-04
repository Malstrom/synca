# frozen_string_literal: true

class PreferencesSerializer
  include Alba::Resource

  attributes :sleep_together_importance,
             :rhythm_importance,
             :temperature_preference,
             :movement_preference,
             :self_chronotype
end
