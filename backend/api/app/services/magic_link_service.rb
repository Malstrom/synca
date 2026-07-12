# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)
  def self.activate(...) = new.activate(...)
  def self.resend(...) = new.resend(...)

  def call(user:)
    user.generate_magic_link_token!

    GuestMailer.magic_link(user).deliver_later
    Success(user)
  rescue StandardError => e
    Failure([:email_failed, e.message])
  end

  def activate(token:, display_name:)
    user = User.includes(:profile).find_by(magic_link_token: token)

    return Failure([:not_found, I18n.t("services.magic_link.not_found")]) unless user
    return Failure([:token_expired, I18n.t("services.magic_link.token_expired")]) if user.magic_link_expired?
    return Failure([:token_already_used, I18n.t("services.magic_link.token_already_used")]) if user.magic_link_used?
    return Failure([:account_already_active, I18n.t("services.magic_link.account_already_active")]) if user.active?

    user.transaction do
      user.update!(
        magic_link_token: nil,
        account_type: :active
      )

      user.profile.update!(display_name: display_name)
    end

    Success(user)
  rescue ActiveRecord::RecordInvalid => e
    Failure([:validation_failed, e.message])
  end

  def resend(email:)
    user = User.find_by(email: email)

    if user&.guest? && user.magic_link_sent_at&.> Settings.magic_link.rate_limit_minutes.minutes.ago
      return Failure([:rate_limited, I18n.t("services.magic_link.rate_limited")])
    end

    return Success(nil) unless user&.guest?

    call(user: user)
  end
end