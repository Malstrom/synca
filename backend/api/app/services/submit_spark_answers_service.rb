# frozen_string_literal: true

class SubmitSparkAnswersService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(current_user:, spark_session:, answers:)
    unless spark_session.active?
      return Failure[:session_not_active, "Session is not active"]
    end

    if current_user.id == spark_session.initiator_id
      spark_session.update!(initiator_answers: answers)
    else
      spark_session.update!(partner_answers: answers)
    end

    if spark_session.reload.both_answered?
      SparkScoringJob.perform_later(spark_session.id)
    end

    Success(spark_session)
  end
end
