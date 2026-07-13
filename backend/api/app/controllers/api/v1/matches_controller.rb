# frozen_string_literal: true

module Api
  module V1
    class MatchesController < ApplicationController
      include Dry::Monads[:result]

      def simulate
        case SimulateMatchService.call(params: params.to_unsafe_h)
        in Success[result]
          render_success(MatchSimulationSerializer.new(result).serialize)
        in Failure[:contract_invalid, result]
          render_contract_errors(result)
        in Failure[:not_found, message]
          render_error(code: "not_found", message: message, status: :not_found)
        end
      end

      def index
        case ListMatchesService.call(current_user: current_user)
        in Success[matches]
          render_success({ matches: MatchSerializer.new(matches).as_json })
        end
      end
    end
  end
end
