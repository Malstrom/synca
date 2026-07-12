# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(user:)
    return Failure([ :account_already_active, I18n.t("errors.account_already_active") ]) if user.active?

    user.update!(
      magic_link_token: SecureRandom.urlsafe_base64(32),
      magic_link_sent_at: Time.current
    )

    Success(user)
  end
end