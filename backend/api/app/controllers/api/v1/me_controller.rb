# frozen_string_literal: true

module Api
  module V1
    class MeController < ApplicationController
      # GET /api/v1/me
      def show
        render_success(me_response)
      end

      private

        def me_response
          {
            user:           UserSerializer.new(current_user).serializable_hash,
            profile:        profile_payload,
            health_summary: health_summary_payload
          }
        end

        def profile_payload
          profile = current_user.profile
          return nil unless profile

          ProfileSerializer.new(profile).serializable_hash
        end

        def health_summary_payload
          health_summary = current_user.health_summary
          return nil unless health_summary

          HealthSummarySerializer.new(health_summary).serializable_hash
        end
    end
  end
end
