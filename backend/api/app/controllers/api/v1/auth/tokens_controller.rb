# frozen_string_literal: true

module Api
  module V1
    module Auth
      class TokensController < ApplicationController
        include Dry::Monads[:result]

        skip_before_action :authenticate_user!

        # POST /api/v1/auth/refresh
        def create
          case RefreshTokenService.call(params: params.to_unsafe_h)
          in Success(access_token)
            render_success({ access_token: access_token })
          in Failure[:invalid_token, message]
            render_error(code: "invalid_token", message: message, status: :unauthorized)
          in Failure[:user_not_found, message]
            render_error(code: "user_not_found", message: message, status: :unauthorized)
          end
        end
      end
    end
  end
end
