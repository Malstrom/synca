# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_one :profile, dependent: :destroy
  has_one :health_summary, dependent: :destroy
  has_one :preference_profile, dependent: :destroy
  has_many :sparks, dependent: :destroy
  has_many :spark_rewards, dependent: :destroy
  has_many :match_participants, dependent: :destroy
  has_many :matches, through: :match_participants

  enum :account_type, { guest: 0, active: 1 }, validate: true
  enum :auth_provider, { email: 0, google: 1 }, validate: true

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }, if: -> { password_digest.present? }

  def active?
    account_type == "active"
  end

  def guest?
    account_type == "guest"
  end

  def generate_magic_link_token
    update!(
      magic_link_token: SecureRandom.urlsafe_base64(32),
      magic_link_sent_at: Time.current
    )
  end

  def magic_link_expired?
    magic_link_sent_at && magic_link_sent_at < Settings.magic_link.ttl_hours.hours.ago
  end

  def activate!(display_name:)
    transaction do
      update!(account_type: :active, magic_link_token: nil)
      profile.update!(display_name: display_name)
    end
  end
end