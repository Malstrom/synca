# frozen_string_literal: true

class SubmitSparkAnswersService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

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

    answers = contract_result.to_h.dig(:spark, :answers)
    store_answers(answers)

    SparkScoringJob.perform_later(@spark.id) if @spark.reload.both_answered?

    Success[@spark]
  end

  private

    def store_answers(answers)
      if @spark.initiator == @current_user
        @spark.update!(initiator_answers: answers)
      else
        @spark.update!(partner_answers: answers)
      end
    end
end
