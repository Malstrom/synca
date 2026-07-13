# frozen_string_literal: true

# Updates (or creates) the Profile for the current user.
# Runs ProfileContract internally — callers pass raw params.
class UpdateProfileService
  include Dry::Monads[:result]

  def self.call(**args) = new(**args).call

  def initialize(current_user:, params:)
    @current_user = current_user
    @params       = params
  end

  def call
    contract_result = ProfileContract.new.call(
      profile: @params.dig("profile") || @params.dig(:profile) || {}
    )
    return Failure[:contract_invalid, contract_result] if contract_result.failure?

    profile = @current_user.profile || @current_user.build_profile

    if profile.update(contract_result.to_h[:profile])
      Success[profile]
    else
      Failure[:validation_failed, profile.errors.full_messages.join(", ")]
    end
  end
end
