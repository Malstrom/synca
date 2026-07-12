# frozen_string_literal: true

class ActivateAccountService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(token:, display_name:)
    user = User.find_by(magic_link_token: token)

    return Failure([:token_not_found, "Token not found"]) unless user
    return Failure([:account_already_active, "Account already active"]) if user.active?
    return Failure([:token_expired, "Token expired"]) if token_expired?(user)

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

  private

  def token_expired?(user)
    user.magic_link_sent_at && user.magic_link_sent_at < 72.hours.ago
  end
end