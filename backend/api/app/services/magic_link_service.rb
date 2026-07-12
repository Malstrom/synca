# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(user:)
    user.update!(
      magic_link_token: generate_token,
      magic_link_sent_at: Time.current
    )

    Success(user)
  end

  private

  def generate_token
    SecureRandom.urlsafe_base64(32)
  end
end