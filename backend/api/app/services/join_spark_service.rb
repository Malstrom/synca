# frozen_string_literal: true

class JoinSparkService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(current_user:, spark:, params:)
    @current_user = current_user
    @spark        = spark
    @params       = params
  end

  def call
    contract_result = JoinSparkContract.new.call(@params)
    return Failure[:contract_invalid, contract_result] if contract_result.failure?

    return Failure[:cannot_join_own_spark, I18n.t("errors.sparks.cannot_join_own_spark")] \
      if @spark.initiator == @current_user

    return Failure[:spark_not_joinable, I18n.t("errors.sparks.not_joinable")] \
      unless @spark.pending?

    attrs = contract_result.to_h[:spark]
    return Failure[:invalid_code, I18n.t("errors.sparks.invalid_code")] \
      if attrs[:code].present? && @spark.code != attrs[:code]

    @spark.update!(partner: @current_user, status: :active)
    Success[@spark]
  end
end
