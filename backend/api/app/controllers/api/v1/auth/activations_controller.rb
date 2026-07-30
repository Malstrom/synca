# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        include Dry::Monads[:result]

        skip_before_action :authenticate_user!

        # POST /api/v1/auth/activate
        def create
          case ActivateUserService.call(params: params.to_unsafe_h)
          in Success(user)
            render_success(ActivateUserSerializer.new(user).serializable_hash)
          in Failure[:validation_failed, contract]
            render_contract_errors(contract)
          in Failure[:token_not_found]
            render_error(code: "token_not_found", message: "Magic link token not found", status: :not_found)
          in Failure[:token_expired]
            render_error(code: "token_expired", message: "Magic link token has expired", status: :unprocessable_entity)
          in Failure[:token_already_used]
            render_error(code: "token_already_used", message: "Magic link token has already been used", status: :unprocessable_entity)
          in Failure[:account_already_active]
            render_error(code: "account_already_active", message: "Account is already active", status: :unprocessable_entity)
          end
        end
      end
    end
  end
end