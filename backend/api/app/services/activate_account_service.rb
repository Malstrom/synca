# frozen_string_literal: true

class ActivateAccountService
  include Dry::Monads[:result]

  TOKEN_TTL = Settings.magic_link.ttl_hours.hours

  def self.call(...) = new.call(...)

  def call(token:, display_name:)
    user = User.includes(:profile).find_by(magic_link_token: token)

    case
    when user.nil?
      Failure([:token_not_found, I18n.t("services.activate_account.token_not_found")])
    when user.active?
      Failure([:account_already_active, I18n.t("services.activate_account.account_already_active")])
    when user.magic_link_expired?
      Failure([:token_expired, I18n.t("services.activate_account.token_expired")])
    when user.magic_link_used?
      Failure([:token_already_used, I18n.t("services.activate_account.token_already_used")])
    else
      activate_user(user, display_name)
    end
  end

  private

  def activate_user(user, display_name)
    user.transaction do
      user.update!(
        account_type: :active,
        magic_link_token: nil,
        magic_link_sent_at: nil
      )

      user.profile.update!(display_name: display_name)
    end

    Success(user)
  rescue ActiveRecord::RecordInvalid => e
    Failure([:validation_failed, e.message])
  end
end