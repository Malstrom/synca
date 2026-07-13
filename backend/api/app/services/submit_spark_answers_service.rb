# frozen_string_literal: true

# Submits answers for a Spark session.
# Runs SubmitSparkAnswersContract internally — callers pass raw params.
class SubmitSparkAnswersService
  include Dry::Monads[:result]

  def self.call(**args) = new(**args).call

  def initialize(current_user:, spark:, params:)
    @current_user = current_user
    @spark        = spark
    @params       = params
  end

  def call
    contract_result = SubmitSparkAnswersContract.new.call(@params)
    return Failure[:contract_invalid, contract_result] if contract_result.failure?

    return Failure[:session_not_active, I18n.t("errors.sparks.session_not_active")] \
      unless @spark.active?

    answers = contract_result.to_h[:spark][:answers]
    record_answers(answers)

    if both_answered?
      SparkScoringJob.perform_later(@spark.id)
    end

    Success[@spark]
  end

  private

    def record_answers(answers)
      answers.each do |answer|
        @spark.spark_answers.find_or_create_by!(
          user: @current_user,
          question_key: answer[:question_key]
        ) do |a|
          a.value = answer[:value]
        end
      end
    end

    def both_answered?
      answered_users = @spark.spark_answers.select(:user_id).distinct.count
      answered_users >= 2
    end
end
