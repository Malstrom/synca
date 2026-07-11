# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(user:)
    user.update!(
      magic_link_token: SecureRandom.urlsafe_base64(32),
      magic_link_sent_at: Time.current
    )

    Success(user.magic_link_token)
  end
end