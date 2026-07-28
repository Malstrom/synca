# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        include Dry::Monads[:result]

        # POST /api/v1/auth/activate
        def create
          case ActivateAccountService.call(user: current_user, params: params.to_unsafe_h)
          in Success(user)
            render_success(auth_response(user))
          in Failure[:validation_failed, result]
            render_contract_errors(result)
          end
        end
      end
    end
  end
end
