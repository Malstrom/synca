# frozen_string_literal: true

module Api
  module V1
    class HealthSummaryController < ApplicationController
      include Dry::Monads[:result]

      # PUT /api/v1/me/health_summary
      def update
        result = HealthSummaryContract.new.call(params.to_unsafe_h)
        return render_contract_errors(result) if result.failure?

        case UpdateHealthSummaryService.call(current_user: current_user, attrs: result.to_h[:health_summary])
        in Success(health_summary)
          render_success({ health_summary: HealthSummarySerializer.new(health_summary).serialize })
        in Failure[:validation_failed, message]
          render_error(code: "validation_failed", message: message)
        end
      end
    end
  end
end
