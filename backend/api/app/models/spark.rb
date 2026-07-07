# frozen_string_literal: true

class Spark < ApplicationRecord
  belongs_to :initiator, class_name: "User", inverse_of: :initiated_sparks
  belongs_to :partner,   class_name: "User", optional: true, inverse_of: :joined_sparks

  has_many :spark_rewards, dependent: :destroy

  enum :status, { pending: 0, active: 1, completed: 2, expired: 3 }

  # No AR validations for uniqueness: session_code uniqueness is guaranteed
  # by the loop in CreateSparkService before save. qr_token is SecureRandom.uuid.
  # No AR callbacks. No business-rule validations.
  # Token generation → CreateSparkService
  # Valid state transitions → see config/settings/spark.yml

  scope :stale, -> {
    where(status: [ :pending, :active ])
      .where("created_at < ?", expiry_minutes.minutes.ago)
  }

  def both_answered?
    initiator_answers.present? && partner_answers.present?
  end

  def self.expiry_minutes
    @expiry_minutes ||= Settings.spark.expiry_minutes
  end
end
