# frozen_string_literal: true

# Activates a guest account using a magic link token.
# Returns Success(user) or Failure([:reason, message]).
class ActivateAccountService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(user:, token:, display_name:)
    return Failure([ :invalid_user, "User must be a guest" ]) unless user.account_type == "guest"
    return Failure([ :token_expired, "Token has expired" ]) if user.magic_link_sent_at < 72.hours.ago
    return Failure([ :token_already_used, "Token has already been used" ]) unless user.magic_link_token == token

    user.transaction do
      user.update!(
        account_type: "active",
        magic_link_token: nil,
        magic_link_sent_at: nil
      )

      user.profile.update!(display_name: display_name)
    end

    Success(user)
  end
end