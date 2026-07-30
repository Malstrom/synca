# frozen_string_literal: true

# Resends a magic link to a guest user
#
# Returns:
#   Success                                  — magic link resent (or would have been)
#   Failure[:validation_failed, contract]    — contract validation failed (dry-validation result)
#   Failure[:rate_limited]                  — resend attempted too soon
class ResendMagicLinkService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(params:)
    @params = params
  end

  def call
    contract = ResendMagicLinkContract.new.call(@params)
    return Failure[:validation_failed, contract] if contract.failure?

    user = User.find_by(email: contract[:email].downcase)
    return Success if user.nil? || !user.guest?

    if user.magic_link_sent_at && user.magic_link_sent_at > 5.minutes.ago
      return Failure[:rate_limited]
    end

    user.generate_magic_link_token
    GuestMailer.magic_link(user).deliver_later

    Success
  end
end