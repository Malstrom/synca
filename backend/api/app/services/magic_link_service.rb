# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result]
  include Rails.application.routes.url_helpers

  def self.call(...) = new(...).call
  def self.resend(...) = new(...).resend

  def initialize(user: nil, email: nil)
    @user  = user
    @email = email
  end

  def call
    return Failure([:rate_limited, I18n.t("services.magic_link.rate_limited")]) if rate_limited?

    user = find_user
    return Failure([:not_found, I18n.t("services.magic_link.user_not_found")]) unless user

    user.generate_magic_link_token!
    GuestMailer.magic_link(user, activate_url(token: user.magic_link_token)).deliver_later
    Success(user)
  rescue StandardError => e
    Failure([:error, e.message])
  end

  def resend
    return Failure([:rate_limited, I18n.t("services.magic_link.rate_limited")]) if rate_limited?

    user = find_user
    return Success(nil) unless user

    user.generate_magic_link_token!
    GuestMailer.magic_link(user, activate_url(token: user.magic_link_token)).deliver_later
    Success(user)
  rescue StandardError => e
    Failure([:error, e.message])
  end

  private

  def find_user
    @user || User.find_by(email: @email.downcase)
  end

  def rate_limited?
    user = find_user
    user&.magic_link_sent_at&.> Settings.magic_link.rate_limit_minutes.minutes.ago
  end
end