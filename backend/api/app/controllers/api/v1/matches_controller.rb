# frozen_string_literal: true

module Api
  module V1
    class MatchesController < ApplicationController
      include Dry::Monads[:result]

      # POST /api/v1/matches/simulate
      def simulate
        contract_result = SimulateMatchContract.new.call(params.to_unsafe_h)

        if contract_result.failure?
          return render_error(
            code: "missing_params",
            message: I18n.t("errors.matches.missing_params"),
            status: :unprocessable_entity
          )
        end

        case SimulateMatchService.call(**contract_result.to_h.symbolize_keys)
        in Success(result)
          render_success(MatchSimulationSerializer.new(result).serialize)
        in Failure[:not_found, message]
          render_error(code: "not_found", message: message, status: :not_found)
        end
      end

      # GET /api/v1/matches
      def index
        matches = current_user.matches
          .includes(match_participants: { user: :profile })
          .order(created_at: :desc)

        render_success({ matches: serialize_collection(matches, MatchSerializer) })
      end
    end
  end
end
