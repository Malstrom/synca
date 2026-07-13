# frozen_string_literal: true

class ActivateAccountService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(token:, display_name:)
    @token = token
    @display_name = display_name
  end

  def call
    user = User.includes(:profile).find_by(magic_link_token: @token)
    return Failure[:not_found] unless user

    if user.magic_link_expired?
      return Failure[:token_expired, I18n.t("services.magic_link.token_expired")]
    end

    if user.active?
      return Failure[:account_already_active, I18n.t("services.magic_link.account_already_active")]
    end

    user.transaction do
      user.clear_magic_link_token!
      user.update!(account_type: :active)
      user.profile.update!(display_name: @display_name)
    end

    Success(user)
  rescue ActiveRecord::RecordInvalid => e
    Failure[:validation_failed, e.record.errors.full_messages.join(", ")]
  end
end