# frozen_string_literal: true

# Generates a single-use magic link token for a guest user.
# Returns Success(token) or Failure([:error, message]).
class MagicLinkService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(user:)
    token = SecureRandom.urlsafe_base64(32)
    user.update!(magic_link_token: token, magic_link_sent_at: Time.current)
    Success(token)
  end
end