# frozen_string_literal: true

class MatchParticipantSerializer
  include Alba::Resource

  attributes :user_id, :role

  attribute :profile do |participant|
    profile = participant.user.profile
    profile ? { display_name: profile.display_name } : nil
  end
end
