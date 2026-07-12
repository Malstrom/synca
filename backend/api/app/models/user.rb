# frozen_string_literal: true

class User < ApplicationRecord
  has_many :initiated_sparks, class_name: "Spark", foreign_key: :initiator_id, dependent: :destroy, inverse_of: :initiator
  has_many :spark_participants, dependent: :destroy, inverse_of: :user
  has_many :sparks, through: :spark_participants
  has_many :matches, dependent: :destroy, inverse_of: :user
  has_many :match_participants, dependent: :destroy, inverse_of: :user
  has_many :preference_profiles, dependent: :destroy, inverse_of: :user
  has_one  :profile, dependent: :destroy, inverse_of: :user
  has_one  :health_summary, dependent: :destroy, inverse_of: :user

  has_secure_password

  enum :auth_provider, { email: 0, google: 1, apple: 2 }, prefix: true
  enum :account_type, { guest: 0, active: 1 }, prefix: true

  def generate_magic_link_token!
    update!(
      magic_link_token: SecureRandom.urlsafe_base64(32),
      magic_link_sent_at: Time.current
    )
  end

  def magic_link_expired?
    magic_link_sent_at.nil? || magic_link_sent_at < Settings.magic_link.ttl_hours.hours.ago
  end

  def activate!(display_name:)
    transaction do
      update!(account_type: :active, magic_link_token: nil)
      profile.update!(display_name: display_name)
    end
  end
end
