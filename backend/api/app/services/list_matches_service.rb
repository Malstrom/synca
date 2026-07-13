# frozen_string_literal: true

class ListMatchesService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(current_user:)
    @current_user = current_user
  end

  def call
    matches = @current_user.matches
                           .includes(match_participants: { user: :profile })
                           .order(created_at: :desc)
    Success[matches]
  end
end
