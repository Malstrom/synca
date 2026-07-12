# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result]
  include Rails.application.routes.url_helpers

  TOKEN_TTL = Settings.magic_link.ttl_hours.hours

  def self.call(...) = new.call(...)

  def call(user:)
    user = user.class.includes(:profile).find(user.id)

    case
    when user.active?
      Failure([:account_already_active, I18n.t("services.magic_link.account_already_active")])
    when user.magic_link_sent_at&.> 5.minutes.ago
      Failure([:rate_limited, I18n.t("services.magic_link.rate_limited")])
    else
      generate_and_send_magic_link(user)
    end
  end

  private

  def generate_and_send_magic_link(user)
    user.update!(
      magic_link_token: SecureRandom.urlsafe_base64(32),
      magic_link_sent_at: Time.current
    )

    GuestMailer.magic_link(user, activate_url(token: user.magic_link_token)).deliver_later
    Success(user)
  rescue StandardError => e
    Rails.logger.error("Failed to send magic link: #{e.message}")
    Failure([:email_delivery_failed, I18n.t("services.magic_link.email_delivery_failed")])
  end
end