# frozen_string_literal: true

module Api
  module V1
    class SparksController < ApplicationController
      include Dry::Monads[:result]

      before_action :set_spark, only: [ :join, :submit_answers, :result ]
      before_action :authorize_participant!, only: [ :result ]

      # POST /api/v1/sparks
      def create
        contract_result = CreateSparkContract.new.call(params.to_unsafe_h)

        if contract_result.failure?
          return render_contract_errors(contract_result)
        end

        case CreateSparkService.call(current_user: current_user, attrs: contract_result.to_h.fetch(:spark, {}))
        in Success(spark)
          render_created(SparkSerializer.new(spark).serialize)
        in Failure[ :validation_failed, message ]
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
        in Failure[ :cannot_join_own_spark, message ]
          render_error(code: "cannot_join_own_spark", message: message, status: :unprocessable_entity)
        in Failure[ :spark_not_joinable, message ]
          render_error(code: "spark_not_joinable", message: message, status: :unprocessable_entity)
        in Failure[ :invalid_code, message ]
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
        in Failure[ :session_not_active, message ]
          render_error(code: "session_not_active", message: message, status: :unprocessable_entity)
        end
      end

      # GET /api/v1/sparks/:id/result
      def result
        unless @spark.completed?
          return render_error(code: "spark_not_completed", message: "Spark scoring is not yet complete", status: :unprocessable_entity)
        end

        rewards = SparkReward.where(spark: @spark)
        dimensions = build_dimensions

        render_success({
          compatibility_score: @spark.compatibility_score,
          dimensions:          dimensions,
          rewards:             rewards.map { |reward| { type: reward.reward_type, status: reward.status } }
        })
      end

      private

        def set_spark
          @spark = Spark.find(params[:id])
        end

        def authorize_participant!
          unless @spark.initiator_id == current_user.id ||
                 @spark.partner_id   == current_user.id
            render_error(code: "forbidden", message: "You are not a participant of this spark", status: :forbidden)
          end
        end

        # Recomputes dimensions live from health summaries when both are available.
        # Falls back to an empty hash if health data is missing for either participant.
        def build_dimensions
          initiator_health = @spark.initiator.health_summary
          partner_health   = @spark.partner&.health_summary

          return {} unless initiator_health && partner_health

          result = CompatibilityService.call(initiator_health, partner_health)
          {
            sleep_rhythm:    result.sleep,
            energy_overlap:  result.activity,
            lifestyle:       result.lifestyle
          }
        end
    end
  end
end
