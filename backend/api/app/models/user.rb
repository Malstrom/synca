# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_one :profile, dependent: :destroy
  has_one :health_summary, dependent: :destroy
  has_one :preference_profile, dependent: :destroy
  has_many :spark_participants, dependent: :destroy
  has_many :sparks, through: :spark_participants
  has_many :spark_rewards, dependent: :destroy
  has_many :matches, through: :match_participants

  enum :account_type, { guest: 0, active: 1 }, validate: true
  enum :auth_provider, { email: 0, google: 1 }, validate: true

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  def active?
    account_type == "active"
  end

  def guest?
    account_type == "guest"
  end

  def magic_link_expired?
    magic_link_sent_at && magic_link_sent_at < Settings.magic_link.ttl_hours.hours.ago
  end

  def magic_link_used?
    magic_link_token.nil?
  end
end
