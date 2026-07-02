# frozen_string_literal: true

class Match < ApplicationRecord
  enum :status, { proposed: 0, accepted: 1, rejected: 2 }

  has_many :match_participants, dependent: :destroy
  has_many :users, through: :match_participants

  def initiator
    match_participants.find_by(role: :initiator)&.user
  end

  def members
    users.where(match_participants: { role: :member })
  end
end
