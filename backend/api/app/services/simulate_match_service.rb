# frozen_string_literal: true

class SimulateMatchService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(params:)
    @params = params
  end

  def call
    contract_result = SimulateMatchContract.new.call(@params.deep_symbolize_keys)
    return Failure[:contract_invalid, contract_result] if contract_result.failure?

    user_id       = contract_result.to_h[:user_id]
    other_user_id = contract_result.to_h[:other_user_id]

    first_user  = User.find_by(id: user_id)
    second_user = User.find_by(id: other_user_id)

    unless first_user && second_user
      return Failure[:not_found, I18n.t("errors.matches.not_found", default: "Match not found")]
    end

    first_health  = first_user.health_summary
    second_health = second_user.health_summary

    result = if first_health && second_health
      CompatibilityService.call(first_health, second_health)
    else
      CompatibilityService::Result.new(total: 0.0, sleep: 0.0, activity: 0.0, lifestyle: 0.0, preferences: 0.0)
    end

    Success(result)
  end
end
