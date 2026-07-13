# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        include Dry::Monads[:result]

        skip_before_action :authenticate_user!

        # POST /api/v1/auth/activate
        def create
          case ActivateService.call(token: params[:token], display_name: params.dig(:profile, :display_name))
          in Success(user)
            render_success(auth_response(user))
          in Failure([:token_expired, message])
            render_error(code: "token_expired", message: message, status: :unprocessable_entity)
          in Failure([:token_already_used, message])
            render_error(code: "token_already_used", message: message, status: :unprocessable_entity)
          in Failure([:account_already_active, message])
            render_error(code: "account_already_active", message: message, status: :unprocessable_entity)
          in Failure([:not_found, message])
            render_error(code: "not_found", message: message, status: :not_found)
          end
        end
      end
    end
  end
end