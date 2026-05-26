# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password validations: false

  enum :auth_provider, {
    email:    0,
    apple:    1,
    google:   2,
    telegram: 3
  }

  has_one  :profile,            dependent: :destroy
  has_one  :health_summary,     dependent: :destroy
  has_one  :preference_profile, dependent: :destroy
  has_many :match_participants,  dependent: :destroy
  has_many :matches,             through: :match_participants
  has_many :initiated_spark_sessions, class_name: "SparkSession",
                                       foreign_key: :initiator_id,
                                       dependent: :destroy,
                                       inverse_of: :initiator
  has_many :joined_spark_sessions,    class_name: "SparkSession",
                                       foreign_key: :partner_id,
                                       dependent: :nullify,
                                       inverse_of: :partner
  has_many :spark_rewards, dependent: :destroy

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false },
                    allow_nil: true
  validates :phone, uniqueness: true, allow_nil: true
  validates :auth_provider, presence: true
  validates :password, length: { minimum: 8 }, allow_nil: true
  validate  :email_or_phone_present

  private

    def email_or_phone_present
      return if self.email.present? || phone.present? || !email?

      errors.add(:base, "email or phone is required for email auth")
    end
end
