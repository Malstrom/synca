# frozen_string_literal: true

class Spark < ApplicationRecord
  belongs_to :initiator, class_name: "User", inverse_of: :initiated_sparks
  belongs_to :partner,   class_name: "User", optional: true, inverse_of: :joined_sparks

  has_many :spark_rewards, dependent: :destroy

  enum :status, { pending: 0, active: 1, completed: 2, expired: 3 }

  # Uniqueness enforced at DB level (unique indexes).
  # Kept here to surface RecordNotUnique as a structured 422 before hitting the DB.
  validates :session_code, uniqueness: true
  validates :qr_token,     uniqueness: true

  # Valid state transitions — see config/settings/spark.yml for the canonical list.
  # NEVER call spark.update!(status: ...) outside of the responsible service.
  # NOTE: no AR callbacks, no business-rule validations.
  # Token generation  → CreateSparkService
  # Duplicate guard   → partial UNIQUE index idx_one_active_spark_per_initiator

  scope :stale, -> {
    where(status: [ :pending, :active ])
      .where("created_at < ?", expiry_minutes.minutes.ago)
  }

  def both_answered?
    initiator_answers.present? && partner_answers.present?
  end

  # TODO(phase-1): return per-dimension breakdown of the compatibility score
  # once the scoring engine exposes dimension weights.
  # Shape: { sleep: Float, activity: Float, rhythm: Float }
  def dimensions
    raise NotImplementedError, "#{self.class}#dimensions is not implemented yet (phase 1)"
  end

  def self.expiry_minutes
    @expiry_minutes ||= Settings.spark.expiry_minutes
  end
end
