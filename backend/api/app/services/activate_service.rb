# frozen_string_literal: true

class ActivateService
  include Dry::Monads[:result]

  TOKEN_TTL = 72.hours

  def self.call(...) = new.call(...)

  def call(attrs)
    user = User.includes(:profile).find_by(magic_link_token: attrs[:token])

    return Failure([:not_found, I18n.t("contracts.errors.token.not_found")]) unless user

    if user.account_type != "guest"
      return Failure([:account_already_active, I18n.t("contracts.errors.token.account_already_active")])
    end

    if user.magic_link_sent_at.nil? || user.magic_link_sent_at < TOKEN_TTL.ago
      return Failure([:token_expired, I18n.t("contracts.errors.token.token_expired")])
    end

    if user.magic_link_token.nil?
      return Failure([:token_already_used, I18n.t("contracts.errors.token.token_already_used")])
    end

    user.transaction do
      user.update!(
        account_type: "active",
        magic_link_token: nil,
        magic_link_sent_at: nil
      )

      user.profile.update!(display_name: attrs.dig(:profile, :display_name))
    end

    Success(user)
  end
end