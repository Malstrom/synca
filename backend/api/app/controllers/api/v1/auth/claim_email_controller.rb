# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ClaimEmailController < ApplicationController
        include Dry::Monads[:result]

        # POST /api/v1/auth/guest/claim_email
        def create
          case ClaimEmailService.call(user: current_user, params: params.to_unsafe_h)
          in Success(user)
            render_success(UserSerializer.new(user).serializable_hash)
          in Failure[:email_taken, message]
            render_error(code: "email_taken", message: message, field: "email", status: :unprocessable_entity)
          in Failure[:validation_failed, result]
            render_contract_errors(result)
          end
        end
      end
    end
  end
end
