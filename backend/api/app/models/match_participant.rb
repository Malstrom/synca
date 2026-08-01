# frozen_string_literal: true

class MatchParticipant < ApplicationRecord
  belongs_to :match
  belongs_to :user

  enum :role, { initiator: 0, member: 1 }

  validates :user_id, uniqueness: { scope: :match_id, message: "already a participant in this match" }
end