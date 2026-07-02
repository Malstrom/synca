# frozen_string_literal: true

class JoinSparkSessionService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(current_user:, spark_session:, attrs:)
    if spark_session.initiator_id == current_user.id
      return Failure[:cannot_join_own_session, "You cannot join your own session"]
    end

    unless spark_session.pending?
      return Failure[:session_not_joinable, "Session is no longer joinable"]
    end

    provided_code  = attrs[:session_code]
    provided_token = attrs[:qr_token]

    valid_code  = provided_code.present?  && provided_code  == spark_session.session_code
    valid_token = provided_token.present? && provided_token == spark_session.qr_token

    unless valid_code || valid_token
      return Failure[:invalid_code, "Invalid session code or QR token"]
    end

    spark_session.update!(
      partner_id: current_user.id,
      status:     :active,
      started_at: Time.current
    )

    Success(spark_session)
  end
end
