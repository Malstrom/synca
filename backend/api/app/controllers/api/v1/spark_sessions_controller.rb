# frozen_string_literal: true

module Api
  module V1
    class SparkSessionsController < ApplicationController
      include Dry::Monads[:result]

      before_action :set_spark_session, only: [ :join, :submit_answers, :result ]
      before_action :authorize_participant!, only: [ :result ]

      # POST /api/v1/spark_sessions
      def create
        contract_result = CreateSparkSessionContract.new.call(params.to_unsafe_h)

        if contract_result.failure?
          return render_contract_errors(contract_result)
        end

        case CreateSparkSessionService.call(current_user: current_user, attrs: contract_result.to_h.fetch(:spark_session, {}))
        in Success(spark_session)
          render_created(SparkSessionSerializer.new(spark_session).serialize)
        in Failure[:validation_failed, message]
          render_error(code: "validation_failed", message: message)
        end
      end

      # POST /api/v1/spark_sessions/:id/join
      def join
        if @spark_session.initiator_id == current_user.id
          return render_error(code: "cannot_join_own_session", message: "You cannot join your own session", status: :unprocessable_entity)
        end

        unless @spark_session.pending?
          return render_error(code: "session_not_joinable", message: "Session is no longer joinable", status: :unprocessable_entity)
        end

        provided_code  = params.dig(:spark_session, :session_code)
        provided_token = params.dig(:spark_session, :qr_token)

        valid_code  = provided_code.present?  && provided_code  == @spark_session.session_code
        valid_token = provided_token.present? && provided_token == @spark_session.qr_token

        unless valid_code || valid_token
          return render_error(code: "invalid_code", message: "Invalid session code or QR token", status: :unprocessable_entity)
        end

        @spark_session.update!(
          partner_id: current_user.id,
          status:     :active,
          started_at: Time.current
        )

        render_success(SparkSessionSerializer.new(@spark_session).serialize)
      end

      # POST /api/v1/spark_sessions/:id/submit_answers
      def submit_answers
        unless @spark_session.active?
          return render_error(code: "session_not_active", message: "Session is not active", status: :unprocessable_entity)
        end

        if current_user.id == @spark_session.initiator_id
          @spark_session.update!(initiator_answers: answers_param)
        else
          @spark_session.update!(partner_answers: answers_param)
        end

        if @spark_session.reload.both_answered?
          SparkScoringJob.perform_later(@spark_session.id)
        end

        render_success({ status: @spark_session.status })
      end

      # GET /api/v1/spark_sessions/:id/result
      def result
        unless @spark_session.completed?
          return render_error(code: "session_not_completed", message: "Session scoring is not yet complete", status: :unprocessable_entity)
        end

        rewards = SparkReward.where(spark_session: @spark_session)
        dimensions = build_dimensions

        render_success({
          compatibility_score: @spark_session.compatibility_score,
          dimensions:          dimensions,
          rewards:             rewards.map { |reward| { type: reward.reward_type, status: reward.status } }
        })
      end

      private

        def set_spark_session
          @spark_session = SparkSession.find(params[:id])
        end

        def authorize_participant!
          unless @spark_session.initiator_id == current_user.id ||
                 @spark_session.partner_id   == current_user.id
            render_error(code: "forbidden", message: "You are not a participant of this session", status: :forbidden)
          end
        end

        def answers_param
          params.require(:spark_session).require(:answers)
        end

        # Recomputes dimensions live from health summaries when both are available.
        # Falls back to an empty hash if health data is missing for either participant.
        def build_dimensions
          initiator_health = @spark_session.initiator.health_summary
          partner_health   = @spark_session.partner&.health_summary

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
