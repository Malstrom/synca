# frozen_string_literal: true

module Api
  module V1
    class SparkSessionsController < ApplicationController
      before_action :set_spark_session, only: [ :join, :submit_answers, :result ]
      before_action :authorize_participant!, only: [ :result ]

      # POST /api/v1/spark_sessions
      def create
        spark_session = current_user.initiated_spark_sessions.build(create_params)

        unless spark_session.save
          return render_validation_errors(spark_session)
        end

        render json: spark_session_payload(spark_session), status: :created
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

        render json: spark_session_payload(@spark_session)
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

        render json: { status: @spark_session.status }
      end

      # GET /api/v1/spark_sessions/:id/result
      def result
        unless @spark_session.completed?
          return render_error(code: "session_not_completed", message: "Session scoring is not yet complete", status: :unprocessable_entity)
        end

        rewards = SparkReward.where(spark_session: @spark_session)

        render json: {
          compatibility_score: @spark_session.compatibility_score,
          dimensions:          @spark_session.dimensions,
          rewards:             rewards.map { |reward| { type: reward.reward_type, status: reward.status } }
        }
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

        def create_params
          params.fetch(:spark_session, {}).permit(:lat, :lng)
            .then { |permitted| map_location_params(permitted) }
        end

        def map_location_params(permitted)
          result = {}
          result[:location_lat] = permitted[:lat] if permitted.key?(:lat)
          result[:location_lng] = permitted[:lng] if permitted.key?(:lng)
          result
        end

        def answers_param
          params.require(:spark_session).require(:answers)
        end

        def spark_session_payload(spark_session)
          {
            id:           spark_session.id,
            session_code: spark_session.session_code,
            qr_token:     spark_session.qr_token,
            status:       spark_session.status,
            started_at:   spark_session.started_at,
            location_lat: spark_session.location_lat,
            location_lng: spark_session.location_lng
          }
        end
    end
  end
end
