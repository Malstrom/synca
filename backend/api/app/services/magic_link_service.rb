# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result]

  def self.activate(...) = new(...).activate
  def self.resend(...) = new(...).resend

  def initialize(params:)
    @params = params
  end

  def activate
    contract = MagicLinkContract.new.call(@params)
    return Failure[:validation_failed, contract] if contract.failure?

    user = User.find_by(magic_link_token: contract[:token])
    return Failure[:token_not_found] unless user

    if user.magic_link_expired?
      return Failure[:token_expired]
    elsif user.magic_link_used?
      return Failure[:token_already_used]
    elsif user.active?
      return Failure[:account_already_active]
    end

    user.update!(
      magic_link_token: nil,
      account_type: :active
    )

    user.profile.update!(display_name: contract[:profile][:display_name])

    Success(user)
  end

  def resend
    contract = MagicLinkResendContract.new.call(@params)
    return Failure[:validation_failed, contract] if contract.failure?

    user = User.find_by(email: contract[:email].downcase)
    return Success if user.nil? || user.magic_link_sent_at && user.magic_link_sent_at > 5.minutes.ago

    user.generate_magic_link_token
    GuestMailer.magic_link(user).deliver_later

    Success
  end
end