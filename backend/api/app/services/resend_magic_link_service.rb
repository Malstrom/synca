# frozen_string_literal: true

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
    return Success(nil) unless user

    if user.magic_link_sent_at && user.magic_link_sent_at > 5.minutes.ago
      return Failure[:rate_limited]
    end

    user.update!(
      magic_link_token: SecureRandom.urlsafe_base64(32),
      magic_link_sent_at: Time.current
    )

    GuestMailer.magic_link(user).deliver_later
    Success(nil)
  end
end