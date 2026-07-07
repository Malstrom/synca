# frozen_string_literal: true

module Api
  module V1
    module Signals
      class SummaryController < ApplicationController
        include Dry::Monads[:result]

        # GET /api/v1/signals/me/summary
        def show
          health_summary = current_user.health_summary&.active

          if health_summary.nil?
            return render_error(
              code: "no_signals",
              message: "No health data found. Connect Apple Health to see your profile."
            )
          end

          preference_profile = current_user.preference_profile

          presenter = Signals::SummaryPresenter.new(
            health_summary: health_summary,
            preference_profile: preference_profile
          )

          render_success(presenter.call)
        end
      end
    end
  end
end
