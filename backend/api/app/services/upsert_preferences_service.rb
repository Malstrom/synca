# frozen_string_literal: true

class UpsertPreferencesService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(current_user:, params:)
    @current_user = current_user
    @params       = params
  end

  def call
    contract_result = UpsertPreferencesContract.new.call(
      preferences: @params.dig("preferences") || @params.dig(:preferences) || {}
    )
    return Failure[:contract_invalid, contract_result] if contract_result.failure?

    preference_profile = @current_user.preference_profile || @current_user.build_preference_profile

    if preference_profile.update(contract_result.to_h[:preferences])
      Success(preference_profile)
    else
      Failure[:validation_failed, preference_profile.errors.full_messages.join(", ")]
    end
  end
end
