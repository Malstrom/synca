# frozen_string_literal: true

module Api
  module V1
    module Signals
      class SummaryController < ApplicationController
        include Dry::Monads[:result]

        def show
          case SignalsSummaryService.call(user: current_user)
          in Success[record]
            render_success({ summary: SignalsSummarySerializer.new(record).as_json })
          in Failure[:no_signals, message]
            render_error(code: "no_signals", message: message, status: :not_found)
          end
        end
      end
    end
  end
end
