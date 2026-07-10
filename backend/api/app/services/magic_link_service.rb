# frozen_string_literal: true

# Handles magic link generation, validation, and expiration
class MagicLinkService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(user:)
    token = generate_token(user)
    user.update!(
      magic_link_token: token,
      magic_link_sent_at: Time.current
    )
    Success(token)
  end

  private

  def generate_token(user)
    JwtService.encode(
      user_id: user.id,
      purpose: 'activation',
      exp: 72.hours.from_now.to_i
    )
  end
end