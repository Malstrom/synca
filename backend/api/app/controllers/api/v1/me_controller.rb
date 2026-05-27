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
            user: {
              id:            current_user.id,
              email:         current_user.email,
              phone:         current_user.phone,
              auth_provider: current_user.auth_provider
            },
            profile:        profile_payload,
            health_summary: health_summary_payload
          }
        end

        def profile_payload
          profile = current_user.profile
          return nil unless profile

          {
            display_name:   profile.display_name,
            bio:            profile.bio,
            city:           profile.city,
            photo_url_main: profile.photo_url_main,
            trust_score:    profile.trust_score,
            spark_verified: profile.spark_verified
          }
        end

        def health_summary_payload
          health_summary = current_user.health_summary
          return nil unless health_summary

          {
            chronotype:                 health_summary.chronotype,
            sleep_start_local:          health_summary.sleep_start_local,
            sleep_end_local:            health_summary.sleep_end_local,
            avg_sleep_duration_minutes: health_summary.avg_sleep_duration_minutes,
            routine_stability_index:    health_summary.routine_stability_index,
            activity_level:             health_summary.activity_level,
            peak_energy_start_local:    health_summary.peak_energy_start_local,
            peak_energy_end_local:      health_summary.peak_energy_end_local,
            recovery_score:             health_summary.recovery_score,
            source:                     health_summary.source
          }
        end
    end
  end
end
