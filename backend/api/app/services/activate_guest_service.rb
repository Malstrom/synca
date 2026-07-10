# frozen_string_literal: true

# Activates a guest account using a magic link token.
# Returns Success({ access_token:, refresh_token:, account_type: }) or Failure([:reason, detail]).
class ActivateGuestService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(token:, display_name:)
    payload = JwtService.decode(token)
    return Failure([ :invalid_token, "Invalid or expired token" ]) unless payload

    user = User.includes(:profile).find_by(id: payload[:user_id])
    return Failure([ :user_not_found, "User not found" ]) unless user

    case payload[:purpose]
    when "activation"
      activate_user(user, display_name)
    else
      Failure([ :invalid_purpose, "Invalid token purpose" ])
    end
  end

  private

  def activate_user(user, display_name)
    return Failure([ :account_already_active, "Account is already active" ]) if user.active?

    unless user.magic_link_token.present?
      return Failure([ :token_already_used, "Token has already been used" ])
    end

    user.transaction do
      user.update!(
        account_type: :active,
        magic_link_token: nil
      )

      user.profile.update!(display_name: display_name)

      tokens = JwtService.generate_tokens(user)
      Success(tokens.merge(account_type: "active"))
    end
  rescue ActiveRecord::RecordInvalid => e
    Failure([ :validation_failed, e.message ])
  end
end

---