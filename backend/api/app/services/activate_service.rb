# frozen_string_literal: true

class ActivateService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(token:, display_name:)
    @token        = token
    @display_name = display_name
  end

  def call
    user = User.find_by(magic_link_token: @token)
    return Failure([:not_found, I18n.t("services.activate.user_not_found")]) unless user

    return Failure([:token_expired, I18n.t("services.activate.token_expired")]) if user.magic_link_expired?
    return Failure([:token_already_used, I18n.t("services.activate.token_already_used")]) if user.magic_link_token.nil?
    return Failure([:account_already_active, I18n.t("services.activate.account_already_active")]) if user.active?

    user.clear_magic_link_token!
    user.update!(account_type: :active)
    user.create_profile!(display_name: @display_name)

    Success(user)
  rescue StandardError => e
    Failure([:error, e.message])
  end
end