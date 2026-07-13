# frozen_string_literal: true

# Creates or updates the PreferenceProfile for the current user.
# Runs UpsertPreferencesContract internally — callers pass raw params.
class UpsertPreferencesService
  include Dry::Monads[:result]

  def self.call(**args) = new(**args).call

  def initialize(current_user:, params:)
    @current_user = current_user
    @params       = params
  end

  def call
    contract_result = UpsertPreferencesContract.new.call(
      preferences: @params.dig("preferences") || @params.dig(:preferences) || {}
    )
    return Failure[:contract_invalid, contract_result] if contract_result.failure?

    result = UpsertPreferencesService.upsert!(
      current_user: @current_user,
      attrs: contract_result.to_h[:preferences]
    )

    Success[result]
  rescue ActiveRecord::RecordInvalid => e
    Failure[:validation_failed, e.message]
  end
end
