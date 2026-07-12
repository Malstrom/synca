# frozen_string_literal: true

class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_one :health_summary, dependent: :destroy
  has_one :preference_profile, dependent: :destroy
  has_many :spark_participants, dependent: :destroy
  has_many :sparks, through: :spark_participants
  has_many :spark_rewards, dependent: :destroy
  has_many :matches, dependent: :destroy

  enum account_type: { guest: 0, active: 1 }

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
    magic_link_sent_at && magic_link_sent_at < 72.hours.ago
  end

  def magic_link_used?
    magic_link_token.nil?
  end
end
