# frozen_string_literal: true

module Api
  module V1
    module Signals
      class MeController < ApplicationController
        # GET /api/v1/signals/me/summary
        def summary
          health_summary = current_user.health_summary.active.first
          if health_summary
            presenter = Signals::SummaryPresenter.new(health_summary, current_user.preference_profile)
            render_success(presenter.as_json)
          else
            render_not_found('no_signals', 'No health data found. Connect Apple Health to see your profile.')
          end
        end
      end
    end
  end
end
