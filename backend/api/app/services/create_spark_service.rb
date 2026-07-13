# frozen_string_literal: true

# Creates a new Spark for the current user.
# Runs CreateSparkContract internally — callers pass raw params.
class CreateSparkService
  include Dry::Monads[:result]

  def self.call(**args) = new(**args).call

  def initialize(current_user:, params:)
    @current_user = current_user
    @params       = params
  end

  def call
    contract_result = CreateSparkContract.new.call(@params)
    return Failure[:contract_invalid, contract_result] if contract_result.failure?

    attrs = contract_result.to_h.fetch(:spark, {})
    spark = @current_user.initiated_sparks.build(attrs)

    if spark.save
      Success[spark]
    else
      Failure[:validation_failed, spark.errors.full_messages.join(", ")]
    end
  end
end
