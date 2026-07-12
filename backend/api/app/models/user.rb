# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password
  has_many :sparks, dependent: :destroy
  has_many :spark_rewards, dependent: :destroy
  has_many :matches, dependent: :destroy
  has_many :match_participants, dependent: :destroy
  has_one  :profile, dependent: :destroy
  has_one  :health_summary, dependent: :destroy
  has_one  :preference_profile, dependent: :destroy

  enum :account_type, { guest: 0, active: 1 }, validate: true

  def activate!(display_name:)
    transaction do
      update!(account_type: :active, magic_link_token: nil, magic_link_sent_at: nil)
      profile.update!(display_name: display_name)
    end
  end

  def generate_magic_link_token!
    update!(
      magic_link_token: SecureRandom.urlsafe_base64(32),
      magic_link_sent_at: Time.current
    )
  end
end