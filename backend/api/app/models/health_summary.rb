# frozen_string_literal: true

class HealthSummary < ApplicationRecord
  belongs_to :user

  enum :chronotype,     { early_bird: 0, intermediate: 1, night_owl: 2 }
  enum :activity_level, { low: 0, medium: 1, high: 2 }
  enum :recovery_score, { low: 0, medium: 1, high: 2 }, prefix: :recovery
  enum :source,         { apple_health: 0, health_connect: 1 }

  scope :active, -> { where(effective_to: nil) }
end
