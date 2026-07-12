# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result]
  include Rails.application.routes.url_helpers

  TOKEN_TTL = 72.hours

  def self.call(...) = new.call(...)

  def call(user:)
    user = user.class.includes(:profile).find(user.id)

    return Failure([:account_already_active]) if user.active?

    user.update!(
      magic_link_token: SecureRandom.urlsafe_base64(32),
      magic_link_sent_at: Time.current
    )

    Success(user)
  end

  def self.activate(token:, display_name:)
    new.activate(token: token, display_name: display_name)
  end

  def activate(token:, display_name:)
    user = User.includes(:profile).find_by(magic_link_token: token)

    return Failure([:token_not_found]) unless user
    return Failure([:token_expired]) if user.magic_link_sent_at < TOKEN_TTL.ago
    return Failure([:token_already_used]) if user.magic_link_token.nil?
    return Failure([:account_already_active]) if user.active?

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