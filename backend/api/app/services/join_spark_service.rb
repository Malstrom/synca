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
    session_code = attrs[:session_code]
    qr_token     = attrs[:qr_token]

    if session_code.present?
      return Failure[:invalid_code, I18n.t("errors.sparks.invalid_code")] \
        if @spark.session_code != session_code
    elsif qr_token.present?
      return Failure[:invalid_code, I18n.t("errors.sparks.invalid_code")] \
        if @spark.qr_token != qr_token
    end

    @spark.update!(partner: @current_user, status: :active, started_at: Time.current)
    Success(@spark)
  end
end
