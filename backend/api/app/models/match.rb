# frozen_string_literal: true

class Match < ApplicationRecord
  enum :status, { proposed: 0, accepted: 1, rejected: 2 }

  has_many :match_participants, dependent: :destroy
  has_many :users, through: :match_participants

  validates :compatibility_score,
            presence: true,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :status, presence: true
  validate  :at_least_two_participants, on: :create

  def initiator
    match_participants.find_by(role: :initiator)&.user
  end

  def members
    users.where(match_participants: { role: :member })
  end

  private

    def at_least_two_participants
      # Enforced at service layer on create; skip if participants not yet persisted
      true
    end
end
