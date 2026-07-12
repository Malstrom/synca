# frozen_string_literal: true

class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_one :health_summary, dependent: :destroy
  has_one :preference_profile, dependent: :destroy
  has_many :initiated_sparks, class_name: "Spark", foreign_key: :initiator_id, dependent: :destroy, inverse_of: :initiator
  has_many :participated_sparks, class_name: "Spark", foreign_key: :participant_id, dependent: :destroy, inverse_of: :participant
  has_many :matches, dependent: :destroy
  has_many :spark_rewards, dependent: :destroy

  enum account_type: { guest: 0, active: 1 }

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