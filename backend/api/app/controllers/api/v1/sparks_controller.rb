# frozen_string_literal: true

module Api
  module V1
    class SparksController < ApplicationController
      include Dry::Monads[:result]

      before_action :set_spark, only: [ :join, :submit_answers, :result ]

      def create
        case CreateSparkService.call(current_user: current_user, params: params.to_unsafe_h)
        in Success(spark)
          render_created(SparkSerializer.new(spark).serialize)
        in Failure[:contract_invalid, result]
          render_contract_errors(result)
        in Failure[:validation_failed, message]
          render_error(code: "validation_failed", message: message)
        end
      end

      def join
        case JoinSparkService.call(current_user: current_user, spark: @spark, params: params.to_unsafe_h)
        in Success(spark)
          render_success(SparkSerializer.new(spark).serialize)
        in Failure[:contract_invalid, result]
          render_contract_errors(result)
        in Failure[:cannot_join_own_spark, message]
          render_error(code: "cannot_join_own_spark", message: message, status: :unprocessable_entity)
        in Failure[:spark_not_joinable, message]
          render_error(code: "spark_not_joinable", message: message, status: :unprocessable_entity)
        in Failure[:invalid_code, message]
          render_error(code: "invalid_code", message: message, status: :unprocessable_entity)
        end
      end

      def submit_answers
        case SubmitSparkAnswersService.call(current_user: current_user, spark: @spark, params: params.to_unsafe_h)
        in Success(spark)
          render_success({ status: spark.status })
        in Failure[:contract_invalid, result]
          render_contract_errors(result)
        in Failure[:session_not_active, message]
          render_error(code: "session_not_active", message: message, status: :unprocessable_entity)
        end
      end

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
