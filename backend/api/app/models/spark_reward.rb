# frozen_string_literal: true

class SparkReward < ApplicationRecord
  belongs_to :user
  belongs_to :spark_session

  enum :reward_type, { premium_week: 0, match_credit: 1, boost: 2 }
  enum :status,      { pending: 0, redeemed: 1, expired: 2 }

  scope :active, -> { where(status: :pending).where("valid_until > ?", Time.current) }
end
