# frozen_string_literal: true

class JoinSparkService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(current_user:, spark:, attrs:)
    if spark.initiator_id == current_user.id
      return Failure[:cannot_join_own_spark, "You cannot join your own spark"]
    end

    unless spark.pending?
      return Failure[:spark_not_joinable, "Spark is no longer joinable"]
    end

    provided_code  = attrs[:session_code]
    provided_token = attrs[:qr_token]

    valid_code  = provided_code.present?  && provided_code  == spark.session_code
    valid_token = provided_token.present? && provided_token == spark.qr_token

    unless valid_code || valid_token
      return Failure[:invalid_code, "Invalid session code or QR token"]
    end

    spark.update!(
      partner_id: current_user.id,
      status:     :active,
      started_at: Time.current
    )

    Success(spark)
  end
end
