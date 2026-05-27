# frozen_string_literal: true

module Api
  module V1
    class HealthSummaryController < ApplicationController
      # PUT /api/v1/me/health_summary
      def update
        health_summary = current_user.health_summary || current_user.build_health_summary

        unless effective_from_present?
          return render_error(
            code: "validation_failed",
            message: "Effective from can't be blank",
            field: "effective_from",
            status: :unprocessable_entity
          )
        end

        begin
          saved = health_summary.update(health_summary_params)
        rescue ArgumentError => e
          return render_error(
            code: "validation_failed",
            message: e.message,
            status: :unprocessable_entity
          )
        end

        unless saved
          return render_validation_errors(health_summary)
        end

        render_success({ health_summary: health_summary_payload(health_summary) })
      end

      private

        def effective_from_present?
          params.dig(:health_summary, :effective_from).present?
        end

        def health_summary_params
          params.require(:health_summary).permit(
            :chronotype,
            :source,
            :effective_from,
            :effective_to,
            :avg_sleep_duration_minutes,
            :routine_stability_index,
            :activity_level,
            :recovery_score,
            :sleep_start_local,
            :sleep_end_local,
            :peak_energy_start_local,
            :peak_energy_end_local
          )
        end

        def health_summary_payload(health_summary)
          {
            chronotype:                 health_summary.chronotype,
            source:                     health_summary.source,
            effective_from:             health_summary.effective_from,
            effective_to:               health_summary.effective_to,
            avg_sleep_duration_minutes: health_summary.avg_sleep_duration_minutes,
            routine_stability_index:    health_summary.routine_stability_index,
            activity_level:             health_summary.activity_level,
            recovery_score:             health_summary.recovery_score,
            sleep_start_local:          health_summary.sleep_start_local,
            sleep_end_local:            health_summary.sleep_end_local,
            peak_energy_start_local:    health_summary.peak_energy_start_local,
            peak_energy_end_local:      health_summary.peak_energy_end_local
          }
        end
    end
  end
end
