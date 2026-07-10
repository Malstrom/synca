# frozen_string_literal: true

# Generates a new magic link token and sends it via email.
# Returns Success(true) or Failure([:rate_limited, message]).
class ResendMagicLinkService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(user:)
    if user.magic_link_sent_at && user.magic_link_sent_at > 5.minutes.ago
      return Failure([ :rate_limited, "Please wait 5 minutes before requesting a new link" ])
    end

    result = MagicLinkService.call(user: user)
    return result unless result.success?

    GuestMailer.magic_link(user, result.value!).deliver_later
    Success(true)
  end
end