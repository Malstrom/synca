# frozen_string_literal: true

module Api
  module V1
    module Signals
      class SummaryController < ApplicationController
        before_action :authenticate_user!

        def show
          case SignalsSummaryService.call(user: current_user)
          in Success[record]
            render_success(SignalsSummarySerializer.new(record).as_json)
          in Failure[:no_signals, message]
            render_error(:no_signals, message)
          end
        end
      end
    end
  end
end
