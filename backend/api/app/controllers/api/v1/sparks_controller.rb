# frozen_string_literal: true

module Api
  module V1
    class SparksController < ApplicationController
      include Dry::Monads[:result]

      before_action :set_spark, only: [ :join, :submit_answers, :result ]

      # POST /api/v1/sparks
      def create
        contract_result = CreateSparkContract.new.call(params.to_unsafe_h)
        return render_contract_errors(contract_result) if contract_result.failure?

        case CreateSparkService.call(current_user: current_user, attrs: contract_result.to_h.fetch(:spark, {}))
        in Success(spark)
          render_created(SparkSerializer.new(spark).serialize)
        in Failure[:validation_failed, message]
          render_error(code: "validation_failed", message: message)
        end
      end

      # POST /api/v1/sparks/:id/join
      def join
        contract_result = JoinSparkContract.new.call(params.to_unsafe_h)
        return render_contract_errors(contract_result) if contract_result.failure?

        case JoinSparkService.call(
          current_user: current_user,
          spark: @spark,
          attrs: contract_result.to_h[:spark]
        )
        in Success(spark)
          render_success(SparkSerializer.new(spark).serialize)
        in Failure[:cannot_join_own_spark, message]
          render_error(code: "cannot_join_own_spark", message: message, status: :unprocessable_entity)
        in Failure[:spark_not_joinable, message]
          render_error(code: "spark_not_joinable", message: message, status: :unprocessable_entity)
        in Failure[:invalid_code, message]
          render_error(code: "invalid_code", message: message, status: :unprocessable_entity)
        end
      end

      # POST /api/v1/sparks/:id/submit_answers
      def submit_answers
        contract_result = SubmitSparkAnswersContract.new.call(params.to_unsafe_h)
        return render_contract_errors(contract_result) if contract_result.failure?

        case SubmitSparkAnswersService.call(
          current_user: current_user,
          spark: @spark,
          answers: contract_result.to_h[:spark][:answers]
        )
        in Success(spark)
          render_success({ status: spark.status })
        in Failure[:session_not_active, message]
          render_error(code: "session_not_active", message: message, status: :unprocessable_entity)
        end
      end

      # GET /api/v1/sparks/:id/result
      def result
        case SparkResultService.call(spark: @spark, current_user: current_user)
        in Success(data)
          render_success(data)
        in Failure[:spark_not_completed, message]
          render_error(code: "spark_not_completed", message: message, status: :unprocessable_entity)
        in Failure[:not_participant, message]
          render_error(code: "forbidden", message: message, status: :forbidden)
        end
      end

      private

        def set_spark
          @spark = Spark.find(params[:id])
        end
    end
  end
end
