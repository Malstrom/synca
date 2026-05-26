class HealthSummary < ApplicationRecord
  belongs_to :user

  enum :chronotype, { early_bird: 0, intermediate: 1, night_owl: 2 }
  enum :activity_level, { low: 0, medium: 1, high: 2 }
  enum :recovery_score, { low: 0, medium: 1, high: 2 }, prefix: :recovery
  enum :source, { apple_health: 0, health_connect: 1 }

  validates :chronotype,     presence: true
  validates :source,         presence: true
  validates :effective_from, presence: true
  validates :routine_stability_index,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 },
            allow_nil: true
  validates :avg_sleep_duration_minutes,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true
  validate  :effective_range_valid

  scope :active, -> { where(effective_to: nil) }

  private

  def effective_range_valid
    return unless effective_to && effective_from

    errors.add(:effective_to, "must be after effective_from") if effective_to < effective_from
  end
end
