# frozen_string_literal: true

# Activates a guest account by setting the display_name and upgrading to active.
# Returns Success({ access_token:, refresh_token:, account_type: }) or Failure([:reason, detail]).
class ActivateGuestService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(user:, token:, display_name:)
    return Failure([ :account_already_active, "Account is already active" ]) if user.active?

    decoded_token = JwtService.decode(token)
    return Failure([ :invalid_token, "Invalid token" ]) unless decoded_token.success?

    payload = decoded_token.value!
    return Failure([ :invalid_purpose, "Token purpose must be 'activation'" ]) unless payload[:purpose] == "activation"
    return Failure([ :token_expired, "Token has expired" ]) if payload[:exp] < Time.current.to_i
    return Failure([ :token_mismatch, "Token does not match user" ]) unless payload[:user_id] == user.id

    unless user.magic_link_token == token
      return Failure([ :token_already_used, "Token has already been used" ]) if user.magic_link_token.nil?
      return Failure([ :invalid_token, "Invalid token" ])
    end

    user.transaction do
      user.update!(account_type: :active, magic_link_token: nil)
      user.profile.update!(display_name: display_name)

      tokens = JwtService.access_token(user)
      Success({ access_token: tokens[:access_token], refresh_token: tokens[:refresh_token], account_type: "active" })
    end
  rescue ActiveRecord::RecordInvalid => e
    Failure([ :validation_failed, e.message ])
  end
end