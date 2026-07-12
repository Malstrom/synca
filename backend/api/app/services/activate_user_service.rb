# frozen_string_literal: true

class ActivateUserService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(user:, display_name:)
    user = user.class.includes(:profile).find(user.id)

    return Failure([:token_expired, I18n.t("services.activate_user.token_expired")]) if user.magic_link_expired?
    return Failure([:token_already_used, I18n.t("services.activate_user.token_already_used")]) if user.magic_link_already_used?
    return Failure([:account_already_active, I18n.t("services.activate_user.account_already_active")]) if user.active?

    user.transaction do
      user.update!(
        magic_link_token: nil,
        account_type: :active
      )

      user.profile.update!(display_name: display_name)
    end

    Success(user)
  end
end