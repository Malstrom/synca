# frozen_string_literal: true

# Resends a magic link to a guest user.
# Returns Success(message) or Failure([:reason, detail]).
class ResendMagicLinkService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(email:)
    user = User.find_by(email: email)
    return Success("If your email is registered, a new link has been sent.") unless user&.guest?

    if user.magic_link_sent_at && user.magic_link_sent_at > 5.minutes.ago
      return Failure([ :rate_limited, "Please wait before requesting another link" ])
    end

    token = JwtService.encode(user_id: user.id, purpose: "activation", exp: 72.hours.from_now.to_i)
    user.update!(magic_link_token: token, magic_link_sent_at: Time.current)

    # TODO: Send email with magic link
    Success("If your email is registered, a new link has been sent.")
  end
end