# frozen_string_literal: true

module Api
  module V1
    module Signals
      class SummaryController < ApplicationController
        include Dry::Monads[:result]

        # GET /api/v1/signals/me/summary
        def show
          health_summary = HealthSummary.find_by(user: current_user, effective_to: nil)

          if health_summary.nil?
            return render_error(
              code: "no_signals",
              message: "No health data found. Connect Apple Health to see your profile."
            )
          end

          preference_profile = PreferenceProfile.find_by(user: current_user)

          presenter = SummaryPresenter.new(
            health_summary: health_summary,
            preference_profile: preference_profile
          )

          render_success(summary: presenter.call)
        end
      end
    end
  end
end

---