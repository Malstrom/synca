# frozen_string_literal: true

# Activates a guest user account using a magic link token
#
# Returns:
#   Success(user)                              — activation successful
#   Failure[:validation_failed, contract]      — contract validation failed (dry-validation result)
#   Failure[:token_not_found]                 — magic link token not found
#   Failure[:token_expired]                   — magic link token has expired
#   Failure[:token_already_used]              — magic link token has already been used
#   Failure[:account_already_active]          — account is already active
class ActivateUserService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(params:)
    @params = params
  end

  def call
    contract = ActivateUserContract.new.call(@params)
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

    user.transaction do
      user.update!(
        magic_link_token: nil,
        account_type: :active
      )

      user.profile.update!(
        display_name: contract[:profile][:display_name]
      )
    end

    Success(user)
  end
end