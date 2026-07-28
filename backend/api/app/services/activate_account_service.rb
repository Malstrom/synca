# frozen_string_literal: true

# Upgrades a guest account to `active`: sets the profile display name and
# issues a permanent (non-guest) access + refresh token pair.
#
# @example
#   case ActivateAccountService.call(user: current_user, params: params.to_unsafe_h)
#   in Success(user)                  then render_success(auth_response(user))
#   in Failure[:validation_failed, r] then render_contract_errors(r)
#   end
class ActivateAccountService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(user:, params:)
    @user = user
    @params = params
  end

  def call
    result = ActivationContract.new.call(@params)
    return Failure[:validation_failed, result] if result.failure?

    profile = @user.profile || @user.build_profile
    profile.update!(display_name: result[:profile][:display_name])
    @user.update!(account_type: :active)

    Success(@user)
  end
end
