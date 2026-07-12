# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(user:)
    user = user.class.includes(:profile).find(user.id)

    return Failure([:account_already_active, I18n.t("services.magic_link.account_already_active")]) if user.active?

    return Failure([:rate_limited, I18n.t("services.magic_link.rate_limited")]) if user.magic_link_sent_at&.> Settings.magic_link.rate_limit_minutes.minutes.ago

    user.generate_magic_link_token!

    Success(user)
  end
end