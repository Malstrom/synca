# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result]
  include Rails.application.routes.url_helpers

  TOKEN_TTL = 72.hours

  def self.call(...) = new.call(...)

  def call(user:)
    user = user.class.includes(:profile).find(user.id)

    case
    when user.account_type_active?
      Failure([:account_already_active, I18n.t("services.magic_link.account_already_active")])
    when user.magic_link_sent_at&.> 5.minutes.ago
      Failure([:rate_limited, I18n.t("services.magic_link.rate_limited")])
    else
      user.generate_magic_link_token!
      Success(user)
    end
  end

  def activate(token:, display_name:)
    user = User.includes(:profile).find_by(magic_link_token: token)

    case
    when user.nil?
      Failure([:token_not_found, I18n.t("services.magic_link.token_not_found")])
    when user.magic_link_sent_at.nil? || user.magic_link_sent_at < TOKEN_TTL.ago
      Failure([:token_expired, I18n.t("services.magic_link.token_expired")])
    when user.account_type_active?
      Failure([:account_already_active, I18n.t("services.magic_link.account_already_active")])
    else
      user.activate!(display_name: display_name)
      Success(user)
    end
  end
end