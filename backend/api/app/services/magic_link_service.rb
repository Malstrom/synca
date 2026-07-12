# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result]
  include Rails.application.routes.url_helpers

  TOKEN_TTL = 72.hours

  def self.call(...) = new.call(...)

  def call(user:)
    user = user.class.includes(:profile).find(user.id)

    return Failure([:account_already_active, I18n.t("errors.account_already_active")]) if user.active?

    user.update!(
      magic_link_token: SecureRandom.urlsafe_base64(32),
      magic_link_sent_at: Time.current
    )

    Success(user)
  end

  def self.validate_token(token:)
    user = User.find_by(magic_link_token: token)

    return Failure([:token_not_found, I18n.t("errors.token_not_found")]) unless user
    return Failure([:token_expired, I18n.t("errors.token_expired")]) if token_expired?(user)
    return Failure([:token_already_used, I18n.t("errors.token_already_used")]) if user.active?

    Success(user)
  end

  def self.token_expired?(user)
    user.magic_link_sent_at < TOKEN_TTL.ago
  end

  private_class_method :token_expired?
end