# frozen_string_literal: true

class ActivateService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(token:, display_name:)
    user = User.includes(:profile).find_by(magic_link_token: token)

    return Failure([:not_found, I18n.t("services.activate.not_found")]) unless user

    if user.account_type_active?
      Failure([:account_already_active, I18n.t("services.activate.account_already_active")])
    elsif user.magic_link_expired?
      Failure([:token_expired, I18n.t("services.activate.token_expired")])
    elsif user.magic_link_token.nil?
      Failure([:token_already_used, I18n.t("services.activate.token_already_used")])
    else
      user.activate!(display_name: display_name)
      Success(user)
    end
  end
end