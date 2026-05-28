# frozen_string_literal: true

module Api
  module V1
    class MatchesController < ApplicationController
      # POST /api/v1/matches/simulate
      def simulate
        user_id       = params[:user_id]
        other_user_id = params[:other_user_id]

        unless user_id.present? && other_user_id.present?
          return render_error(code: "missing_params", message: "user_id and other_user_id are required", status: :unprocessable_entity)
        end

        if user_id.to_s == other_user_id.to_s
          return render_error(code: "same_user", message: "user_id and other_user_id must be different", status: :unprocessable_entity)
        end

        first_user  = User.find_by(id: user_id)
        second_user = User.find_by(id: other_user_id)

        unless first_user && second_user
          return render_error(code: "not_found", message: "One or both users not found", status: :not_found)
        end

        first_health  = first_user.health_summary
        second_health = second_user.health_summary

        result = if first_health && second_health
          CompatibilityService.call(first_health, second_health)
        else
          CompatibilityService::Result.new(
            total:       0.0,
            sleep:       0.0,
            activity:    0.0,
            lifestyle:   0.0,
            preferences: 0.0
          )
        end

        render json: {
          compatibility_score: result.total,
          dimensions: {
            sleep_rhythm:   result.sleep,
            energy_overlap: result.activity,
            lifestyle:      result.lifestyle
          }
        }
      end

      # GET /api/v1/matches
      def index
        matches = current_user.matches
          .includes(match_participants: { user: :profile })
          .order(created_at: :desc)

        render json: {
          matches: matches.map { |match| serialize_match(match) }
        }
      end

      private

        def serialize_match(match)
          {
            id:                  match.id,
            status:              match.status,
            compatibility_score: match.compatibility_score,
            accepted_at:         match.accepted_at,
            participants:        match.match_participants.map { |participant| serialize_participant(participant) }
          }
        end

        def serialize_participant(participant)
          profile = participant.user.profile
          {
            user_id: participant.user_id,
            role:    participant.role,
            profile: profile ? { display_name: profile.display_name } : nil
          }
        end
    end
  end
end
