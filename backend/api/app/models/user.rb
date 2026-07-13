# frozen_string_literal: true

class User < ApplicationRecord
  # validations: false because non-email providers (apple, google, telegram)
  # never set a password. Presence/length validation for the :email provider
  # is handled by Dry::Validation contracts (e.g. RegisterContract).
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
  has_one  :health_summary,     -> { where(effective_to: nil) }, dependent: :destroy
  has_one  :preference_profile, dependent: :destroy
  has_many :match_participants,  dependent: :destroy
  has_many :matches,             through: :match_participants
  has_many :initiated_sparks, class_name: "Spark",
                               foreign_key: :initiator_id,
                               dependent: :destroy,
                               inverse_of: :initiator
  # dependent: :nullify is intentional: when a User is deleted as a partner,
  # the Spark record is preserved with partner_id = nil.
  # ExpireStaleSparkJob is responsible for cleaning up orphaned sparks
  # in pending/active state.
  has_many :joined_sparks,    class_name: "Spark",
                               foreign_key: :partner_id,
                               dependent: :nullify,
                               inverse_of: :partner
  has_many :spark_rewards, dependent: :destroy

  # NOTE: no callbacks. Email normalization is the responsibility of the
  # calling service (e.g. CreateUserService, UpdateEmailService).
  # Convention: any service that writes User#email MUST call
  # email.downcase before persisting.

  # NOTE: no AR uniqueness validations. Uniqueness is enforced at DB level
  # (unique indexes on email and phone). The writing service (CreateUserService,
  # UpdateEmailService) is responsible for rescuing ActiveRecord::RecordNotUnique
  # and returning a structured Failure.

  def generate_magic_link_token!
    update!(
      magic_link_token: SecureRandom.urlsafe_base64(32),
      magic_link_sent_at: Time.current
    )
  end

  def magic_link_expired?
    magic_link_sent_at.nil? || magic_link_sent_at < Settings.magic_link.ttl_hours.hours.ago
  end

  def magic_link_used?
    magic_link_token.nil?
  end
end