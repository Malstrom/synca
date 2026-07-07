# frozen_string_literal: true

module Api
  module V1
    module Signals
      class SummaryController < ApplicationController
        include Dry::Monads[:result]

        # GET /api/v1/signals/me/summary
        def show
          signal = Signal.find_by(user: current_user)

          if signal.nil?
            return render_not_found(
              code: "no_signals",
              message: "No health data found. Connect Apple Health to see your profile."
            )
          end

          summary = build_summary(signal)
          render_success({ summary: summary })
        end

        private

          def build_summary(signal)
            {
              chronotype_label: chronotype_label(signal.chronotype),
              peak_energy_window: peak_energy_window(signal.peak_activity_window),
              routine_stability_tier: routine_stability_tier(signal.routine_stability_index),
              activity_tier: activity_tier(signal.activity_minutes_avg),
              avg_sleep_duration_minutes: (signal.sleep_duration_avg * 60).to_i,
              self_report_alignment: self_report_alignment(signal)
            }
          end

          def chronotype_label(chronotype)
            case chronotype
            when "early_bird" then "Early bird"
            when "intermediate" then "Flexible"
            when "night_owl" then "Night owl"
            else nil
            end
          end

          def peak_energy_window(window)
            window || nil
          end

          def routine_stability_tier(index)
            case index
            when nil then nil
            when 0.0..0.4 then "low"
            when 0.4..0.7 then "medium"
            else "high"
            end
          end

          def activity_tier(minutes)
            case minutes
            when nil then nil
            when 0..150 then "low"
            when 150..300 then "medium"
            else "high"
            end
          end

          def self_report_alignment(signal)
            return nil unless signal.user.preference_profile&.self_chronotype

            self_chronotype = signal.user.preference_profile.self_chronotype
            aligned = chronotype_aligned?(self_chronotype, signal.chronotype)

            {
              aligned: aligned,
              note: aligned ? nil : alignment_note(self_chronotype, signal.chronotype)
            }
          end

          def chronotype_aligned?(self_chronotype, chronotype)
            case self_chronotype
            when "morning" then chronotype == "early_bird"
            when "night" then chronotype == "night_owl"
            when "depends" then true
            else false
            end
          end

          def alignment_note(self_chronotype, chronotype)
            "You declared #{self_chronotype} but your data shows #{chronotype}."
          end
      end
    end
  end
end
