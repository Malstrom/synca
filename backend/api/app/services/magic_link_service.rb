# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result]
  include Rails.application.routes.url_helpers

  TOKEN_TTL = Settings.magic_link.ttl_hours.hours

  def self.call(...) = new.call(...)

  def call(user:)
    user = user.class.includes(:profile).find(user.id)

    return Failure([:account_already_active, I18n.t("services.magic_link.account_already_active")]) if user.active?
    return Failure([:rate_limited, I18n.t("services.magic_link.rate_limited")]) if user.magic_link_sent_at&.> 5.minutes.ago

    user.generate_magic_link_token

    Success(user)
  end

  def self.activate(token:, display_name:)
    new.activate(token: token, display_name: display_name)
  end

  def activate(token:, display_name:)
    user = User.find_by(magic_link_token: token)

    return Failure([:not_found, I18n.t("services.magic_link.not_found")]) unless user
    return Failure([:token_expired, I18n.t("services.magic_link.token_expired")]) if user.magic_link_expired?
    return Failure([:account_already_active, I18n.t("services.magic_link.account_already_active")]) if user.active?

    user.activate!(display_name: display_name)

    Success(user)
  end
end