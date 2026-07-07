# frozen_string_literal: true

class PreferencesSerializer
  include Alba::Resource

  attributes :sleep_together_importance, :temperature_preference, :movement_preference, :rhythm_importance, :self_chronotype

  def temperature_preference
    resource.temperature_preference&.to_sym
  end

  def movement_preference
    resource.movement_preference&.to_sym
  end

  def self_chronotype
    resource.self_chronotype&.to_sym
  end
end
