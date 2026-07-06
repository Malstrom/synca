# frozen_string_literal: true

module Api
  module V1
    class HealthSummaryController < ApplicationController
      include Dry::Monads[:result]

      # PUT /api/v1/me/health_summary
      def update
        contract_result = HealthSummaryContract.new.call(
          params.to_unsafe_h.deep_symbolize_keys
        )

        return render_contract_errors(contract_result) if contract_result.failure?

        result = UpdateHealthSummaryService.call(
          current_user: current_user,
          attrs: contract_result.to_h[:health_summary]
        )

        case result
        in Success[ health_summary ]
          render_success({ health_summary: HealthSummarySerializer.new(health_summary).serializable_hash })
        in Failure[ :validation_failed, message ]
          render_error(code: "validation_failed", message: message)
        end
      end
    end
  end
end
