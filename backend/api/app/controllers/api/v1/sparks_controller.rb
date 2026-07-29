# frozen_string_literal: true

module Api
  module V1
    class SparksController < ApplicationController
      include Dry::Monads[:result]

      before_action :set_spark, only: [ :show, :join, :submit_answers, :result ]

      def index
        case ListSparksService.call(current_user: current_user)
        in Success[sparks]
          render_success({ sparks: sparks.map { |s| SparkHistorySerializer.new(s).serializable_hash } })
        end
      end

      # Lets the initiator poll for a partner joining while the QR is on screen.
      def show
        case ShowSparkService.call(current_user: current_user, spark: @spark)
        in Success(spark)
          render_success(SparkSerializer.new(spark).serialize)
        in Failure[:not_participant, message]
          render_error(code: "forbidden", message: message, status: :forbidden)
        end
      end

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
        in Failure[:not_found, _message]
          render_not_found("Spark")
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

        # `POST /sparks/:id/join` (id known — server-to-server/testing use) and
        # `POST /sparks/join` (id unknown — the real QR-scan/manual-code UX,
        # see docs/product/decisions.md#spark-join-by-code-without-id) both
        # route to this same `join` action. Without an id, `@spark` stays nil
        # and `JoinSparkService` resolves it from the contract-validated
        # session_code/qr_token instead.
        def set_spark
          @spark = Spark.find(params[:id]) if params[:id]
        rescue ActiveRecord::RecordNotFound
          render_not_found("Spark")
        end
    end
  end
end
