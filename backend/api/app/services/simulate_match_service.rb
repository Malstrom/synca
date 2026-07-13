# frozen_string_literal: true

# Simulates a compatibility match between two users.
# Runs SimulateMatchContract internally — callers pass raw params.
class SimulateMatchService
  include Dry::Monads[:result]

  def self.call(**args) = new(**args).call

  def initialize(params:)
    @params = params
  end

  def call
    contract_result = SimulateMatchContract.new.call(@params.to_unsafe_h rescue @params)
    return Failure[:contract_invalid, contract_result] if contract_result.failure?

    user_a = User.find_by(id: contract_result.to_h[:user_a_id])
    user_b = User.find_by(id: contract_result.to_h[:user_b_id])

    return Failure[:not_found, I18n.t("errors.matches.not_found")] unless user_a && user_b

    result = CompatibilityService.call(user_a: user_a, user_b: user_b)
    Success[result]
  end
end
