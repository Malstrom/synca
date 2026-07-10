# frozen_string_literal: true

# Activates a guest account using a magic link token
class ActivateGuestService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(token:, display_name:)
    payload = decode_token(token)
    return payload if payload.failure?

    case payload.value!
    in { user_id:, purpose: 'activation' }
      user = User.includes(:profile).find(user_id)

      if user.account_type != 'guest'
        Failure([:account_already_active, I18n.t('contracts.errors.account_type.already_active')])
      elsif user.magic_link_token.nil?
        Failure([:token_already_used, I18n.t('contracts.errors.magic_link_token.already_used')])
      else
        activate_user(user, display_name)
      end
    else
      Failure([:invalid_token, I18n.t('contracts.errors.magic_link_token.invalid')])
    end
  end

  private

  def decode_token(token)
    raw = JwtService.decode_with_status(token)
    case raw
    in { status: :expired, payload: _ }
      Failure([:token_expired, I18n.t('contracts.errors.magic_link_token.expired')])
    in { status: :invalid }
      Failure([:invalid_token, I18n.t('contracts.errors.magic_link_token.invalid')])
    in { status: :ok, payload: payload }
      Success(payload)
    end
  end

  def activate_user(user, display_name)
    user.transaction do
      user.update!(
        account_type: 'active',
        magic_link_token: nil
      )

      user.profile.update!(display_name: display_name)

      tokens = JwtService.access_token(user)
      Success(tokens.merge(account_type: 'active'))
    end
  rescue ActiveRecord::RecordInvalid => e
    Failure([:validation_failed, e.message])
  end
end
