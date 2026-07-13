# frozen_string_literal: true

# Updates (or creates) the HealthSummary for the current user.
# Runs HealthSummaryContract internally — callers pass raw params.
class UpdateHealthSummaryService
  include Dry::Monads[:result]

  def self.call(**args) = new(**args).call

  def initialize(current_user:, params:)
    @current_user = current_user
    @params       = params
  end

  def call
    contract_result = HealthSummaryContract.new.call(
      @params.deep_symbolize_keys
    )
    return Failure[:contract_invalid, contract_result] if contract_result.failure?

    attrs = contract_result.to_h[:health_summary]
    summary = @current_user.health_summary || @current_user.build_health_summary

    if summary.update(attrs)
      Success[summary]
    else
      Failure[:validation_failed, summary.errors.full_messages.join(", ")]
    end
  end
end
