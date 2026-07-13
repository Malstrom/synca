# frozen_string_literal: true

module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        include Dry::Monads[:result]

        skip_before_action :authenticate_user!

        # POST /api/v1/auth/login
        def create
          case LoginService.call(params: params.to_unsafe_h)
          in Success(user)
            render_success(auth_response(user))
          in Failure[:validation_failed, contract]
            render_contract_errors(contract)
          in Failure[:invalid_credentials, message]
            render_error(code: "invalid_credentials", message: message, status: :unauthorized)
          end
        end
      end
    end
  end
end
