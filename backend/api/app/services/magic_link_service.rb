# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result]

  TOKEN_TTL = 72.hours

  def self.call(...) = new.call(...)

  def call(user:)
    user = user.class.includes(:profile).find(user.id)

    if user.account_type != "guest"
      return Failure([:account_already_active, I18n.t("contracts.errors.token.account_already_active")])
    end

    user.update!(
      magic_link_token: SecureRandom.urlsafe_base64(32),
      magic_link_sent_at: Time.current
    )

    Success(user)
  end
end