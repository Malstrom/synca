# frozen_string_literal: true

class SubmitSparkAnswersService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(current_user:, spark:, answers:)
    unless spark.active?
      return Failure[:session_not_active, "Session is not active"]
    end

    if current_user.id == spark.initiator_id
      spark.update!(initiator_answers: answers)
    else
      spark.update!(partner_answers: answers)
    end

    if spark.reload.both_answered?
      SparkScoringJob.perform_later(spark.id)
    end

    Success(spark)
  end
end
