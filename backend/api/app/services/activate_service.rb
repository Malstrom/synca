# frozen_string_literal: true

class ActivateService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(attrs:)
    user = User.find_by(magic_link_token: attrs[:token])

    return Failure([:token_not_found, I18n.t("activate.errors.token_not_found")]) unless user
    return Failure([:token_expired, I18n.t("activate.errors.token_expired")]) if user.magic_link_expired?
    return Failure([:token_already_used, I18n.t("activate.errors.token_already_used")]) if user.magic_link_used?
    return Failure([:account_already_active, I18n.t("activate.errors.account_already_active")]) if user.active?

    user.transaction do
      user.update!(
        account_type: :active,
        magic_link_token: nil,
        magic_link_sent_at: nil
      )

      user.profile.update!(display_name: attrs.dig(:profile, :display_name))
    end

    Success(user)
  rescue ActiveRecord::RecordInvalid => e
    Failure([:validation_failed, e.message])
  end
end