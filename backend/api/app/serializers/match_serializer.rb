# frozen_string_literal: true

class MatchSerializer
  include Alba::Resource

  attributes :id, :status, :compatibility_score, :accepted_at

  many :match_participants, key: :participants, serializer: MatchParticipantSerializer
end
