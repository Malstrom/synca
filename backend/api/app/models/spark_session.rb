# frozen_string_literal: true

class SparkSession < ApplicationRecord
  belongs_to :initiator, class_name: "User", inverse_of: :initiated_spark_sessions
  belongs_to :partner,   class_name: "User", optional: true, inverse_of: :joined_spark_sessions

  has_many :spark_rewards, dependent: :destroy

  enum :status, { pending: 0, active: 1, completed: 2, expired: 3 }

  validates :session_code, uniqueness: true
  validates :qr_token,     uniqueness: true
  validate  :one_active_session_per_initiator, on: :create

  before_validation :generate_tokens, on: :create

  scope :stale, -> {
    where(status: [ :pending, :active ])
      .where("created_at < ?", expiry_minutes.minutes.ago)
  }

  def expired?
    created_at < self.class.expiry_minutes.minutes.ago || status == "expired"
  end

  def both_answered?
    initiator_answers.present? && partner_answers.present?
  end

  def dimensions
    {}
  end

  def self.expiry_minutes
    @expiry_minutes ||= Settings.spark.expiry_minutes
  end

  private

    def generate_tokens
      self.session_code ||= SecureRandom.random_number(10**6).to_s.rjust(6, "0")
      self.qr_token     ||= SecureRandom.uuid
    end

    def one_active_session_per_initiator
      return unless SparkSession.where(initiator_id: initiator_id, status: [ :pending, :active ]).exists?

      errors.add(:base, "initiator already has an active Spark session")
    end
end
