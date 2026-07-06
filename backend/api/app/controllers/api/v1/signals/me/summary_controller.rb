# frozen_string_literal: true

module Api
  module V1
    module Signals
      module Me
        class SummaryController < ApplicationController
          # GET /api/v1/signals/me/summary
          def show
            health_summary = current_user.health_summary.active.first

            if health_summary.nil?
              render_error(code: "no_signals", message: "No health data found. Connect Apple Health to see your profile.")
              return
            end

            presenter = Signals::SummaryPresenter.new(health_summary: health_summary, user: current_user)
            render_success({ summary: presenter.as_json })
          end
        end
      end
    end
  end
end
