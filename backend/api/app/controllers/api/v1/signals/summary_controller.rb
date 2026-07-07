# frozen_string_literal: true

module Api
  module V1
    module Signals
      class SummaryController < ApplicationController
        include Dry::Monads[:result]

        # GET /api/v1/signals/me/summary
        def show
          health_summary = current_user.health_summary

          if health_summary.nil?
            return render_not_found(:no_signals, I18n.t("errors.no_signals"))
          end

          summary = SignalsSummaryService.call(health_summary: health_summary).value!

          render_success({ summary: summary })
        end
      end
    end
  end
end