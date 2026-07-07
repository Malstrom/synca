# frozen_string_literal: true

module Api
  module V1
    module Signals
      class SummaryController < ApplicationController
        include Dry::Monads[:result]

        # GET /api/v1/signals/me/summary
        def show
          health_summary = current_user.health_summary

          return render_error(:no_signals, I18n.t("errors.no_signals")) unless health_summary

          case SignalsSummaryService.call(health_summary: health_summary)
          in Success[result]
            render_success(SignalsSummarySerializer.new(result).as_json)
          in Failure[:reason, message]
            render_error(reason, message)
          end
        end
      end
    end
  end
end
