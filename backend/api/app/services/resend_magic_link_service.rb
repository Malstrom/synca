# frozen_string_literal: true

# Resends a magic link to a guest user if the rate limit allows it.
# Returns Success(token) or Failure([:rate_limited, message]).
class ResendMagicLinkService
  include Dry::Monads[:result]

  RATE_LIMIT = 5.minutes

  def self.call(...) = new.call(...)

  def call(user:)
    if user.magic_link_sent_at && user.magic_link_sent_at > RATE_LIMIT.ago
      Failure([ :rate_limited, I18n.t("services.resend_magic_link.rate_limited") ])
    else
      MagicLinkService.call(user: user).bind do |token|
        GuestMailer.magic_link(user, token).deliver_later
        Success(token)
      end
    end
  end
end