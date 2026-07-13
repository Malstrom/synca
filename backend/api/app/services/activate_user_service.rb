# frozen_string_literal: true

class ActivateUserService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(user:, display_name:)
    user = user.class.includes(:profile).find(user.id)

    return Failure([:token_expired, I18n.t("services.magic_link.token_expired")]) if user.magic_link_expired?
    return Failure([:token_already_used, I18n.t("services.magic_link.token_already_used")]) if user.magic_link_token.nil?
    return Failure([:account_already_active, I18n.t("services.magic_link.account_already_active")]) if user.active?

    profile = user.profile || user.build_profile
    profile.display_name = display_name

    if profile.save
      user.clear_magic_link_token!
      user.update!(account_type: :active)
      Success(user)
    else
      Failure([:validation_failed, profile.errors.full_messages.first])
    end
  end
end