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
          p = current_user.profile
          return nil unless p

          {
            display_name:   p.display_name,
            bio:            p.bio,
            city:           p.city,
            photo_url_main: p.photo_url_main,
            trust_score:    p.trust_score,
            spark_verified: p.spark_verified
          }
        end

        def health_summary_payload
          hs = current_user.health_summary
          return nil unless hs

          {
            chronotype:                 hs.chronotype,
            sleep_start_local:          hs.sleep_start_local,
            sleep_end_local:            hs.sleep_end_local,
            avg_sleep_duration_minutes: hs.avg_sleep_duration_minutes,
            routine_stability_index:    hs.routine_stability_index,
            activity_level:             hs.activity_level,
            peak_energy_start_local:    hs.peak_energy_start_local,
            peak_energy_end_local:      hs.peak_energy_end_local,
            recovery_score:             hs.recovery_score,
            source:                     hs.source
          }
        end
    end
  end
end
