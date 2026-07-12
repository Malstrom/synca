# frozen_string_literal: true

class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_one :health_summary, dependent: :destroy
  has_one :preference_profile, dependent: :destroy
  has_many :match_participants, dependent: :destroy
  has_many :matches, through: :match_participants
  has_many :sparks, dependent: :destroy
  has_many :spark_rewards, through: :sparks

  enum account_type: { guest: 0, active: 1 }

  def active?
    account_type == "active"
  end

  def guest?
    account_type == "guest"
  end

  def magic_link_expired?
    magic_link_sent_at && magic_link_sent_at < 72.hours.ago
  end
end
