# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password validations: false

  enum :auth_provider, {
    email:    0,
    apple:    1,
    google:   2,
    telegram: 3
  }

  enum :account_type, {
    guest: 0,
    active: 1
  }

  has_one  :profile,            dependent: :destroy
  has_one  :health_summary,     dependent: :destroy
  has_one  :preference_profile, dependent: :destroy
  has_many :match_participants,  dependent: :destroy
  has_many :matches,             through: :match_participants
  has_many :initiated_sparks, class_name: "Spark",
                               foreign_key: :initiator_id,
                               dependent: :destroy,
                               inverse_of: :initiator
  has_many :joined_sparks,    class_name: "Spark",
                               foreign_key: :partner_id,
                               dependent: :nullify,
                               inverse_of: :partner
  has_many :spark_rewards, dependent: :destroy

  # NOTE: no callbacks. Email normalization is the responsibility of the
  # calling service (e.g. CreateUserService, UpdateEmailService).
  # Convention: any service that writes User#email MUST call
  # email.downcase before persisting.

  # Uniqueness enforced at DB level (unique indexes on email and phone).
  # Kept here to surface RecordNotUnique as a structured 422 before hitting the DB.
  validates :email, uniqueness: { case_sensitive: false }, allow_nil: true
  validates :phone, uniqueness: true, allow_nil: true
end
