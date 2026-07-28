# frozen_string_literal: true

# Joins a pending Spark, either already resolved by id (server-to-server/
# testing use, `POST /sparks/:id/join`) or looked up here by session_code/
# qr_token (the real QR-scan/manual-code UX, `POST /sparks/join` — see
# docs/product/decisions.md#spark-join-by-code-without-id). Pass `spark: nil`
# for the latter; the contract-validated code resolves it.
#
# @example
#   case JoinSparkService.call(current_user: current_user, spark: @spark, params: params.to_unsafe_h)
#   in Success(spark)                        then render_success(SparkSerializer.new(spark).serialize)
#   in Failure[:contract_invalid, result]    then render_contract_errors(result)
#   in Failure[:not_found, message]          then render_not_found("Spark")
#   in Failure[:cannot_join_own_spark, msg]  then render_error(code: "cannot_join_own_spark", message: msg, status: :unprocessable_entity)
#   in Failure[:spark_not_joinable, msg]     then render_error(code: "spark_not_joinable", message: msg, status: :unprocessable_entity)
#   in Failure[:invalid_code, msg]           then render_error(code: "invalid_code", message: msg, status: :unprocessable_entity)
#   end
class JoinSparkService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(current_user:, params:, spark: nil)
    @current_user = current_user
    @spark        = spark
    @params       = params
  end

  def call
    contract_result = JoinSparkContract.new.call(@params)
    return Failure[:contract_invalid, contract_result] if contract_result.failure?

    attrs = contract_result.to_h[:spark]
    spark = @spark || find_spark(attrs)
    return Failure[:not_found, I18n.t("errors.spark.not_found")] unless spark

    return Failure[:cannot_join_own_spark, I18n.t("errors.spark.cannot_join_own_spark")] \
      if spark.initiator == @current_user

    return Failure[:spark_not_joinable, I18n.t("errors.spark.spark_not_joinable")] \
      unless spark.pending?

    session_code = attrs[:session_code]
    qr_token     = attrs[:qr_token]

    if session_code.present?
      return Failure[:invalid_code, I18n.t("errors.spark.invalid_code")] \
        if spark.session_code != session_code
    elsif qr_token.present?
      return Failure[:invalid_code, I18n.t("errors.spark.invalid_code")] \
        if spark.qr_token != qr_token
    end

    spark.update!(partner: @current_user, status: :active, started_at: Time.current)
    Success(spark)
  end

  private

  # Only reached when the caller didn't already resolve `spark:` by id — the
  # contract already guarantees at least one of these is present.
  def find_spark(attrs)
    return Spark.find_by(session_code: attrs[:session_code]) if attrs[:session_code].present?
    Spark.find_by(qr_token: attrs[:qr_token])
  end
end
