# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result]
  include Rails.application.routes.url_helpers

  TOKEN_TTL = 72.hours

  def self.call(...) = new.call(...)

  def call(user:)
    return Failure([:account_already_active, I18n.t("services.magic_link.account_already_active")]) if user.active?

    return Failure([:rate_limited, I18n.t("services.magic_link.rate_limited")]) if user.magic_link_sent_at&.> 5.minutes.ago

    user.generate_magic_link_token!

    GuestMailer.magic_link(user, activate_url(token: user.magic_link_token)).deliver_later
    Success(user)
  rescue StandardError => e
    Failure([:error, e.message])
  end

  def self.validate_token(token:)
    user = User.includes(:profile).find_by(magic_link_token: token)
    return Failure([:token_not_found, I18n.t("services.magic_link.token_not_found")]) unless user

    return Failure([:token_expired, I18n.t("services.magic_link.token_expired")]) if user.magic_link_sent_at&.< TOKEN_TTL.ago

    Success(user)
  end

  def self.activate(user:, display_name:)
    return Failure([:account_already_active, I18n.t("services.magic_link.account_already_active")]) if user.active?

    user.activate!(display_name: display_name)
    Success(user)
  rescue StandardError => e
    Failure([:error, e.message])
  end
end