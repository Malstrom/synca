# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        skip_before_action :authenticate_user!

        def create
          case MagicLinkService.activate(token: params[:token], display_name: params.dig(:profile, :display_name))
          in Success(user)
            render json: {
              access_token: JwtService.encode(user_id: user.id),
              refresh_token: JwtService.encode(user_id: user.id, type: :refresh),
              token_type: "Bearer",
              account_type: user.account_type
            }
          in Failure([:token_not_found, _])
            render json: { error: "Token not found" }, status: :not_found
          in Failure([:token_expired, _])
            render json: { error: "Token expired" }, status: :unprocessable_entity
          in Failure([:token_already_used, _])
            render json: { error: "Token already used" }, status: :unprocessable_entity
          in Failure([:account_already_active, _])
            render json: { error: "Account already active" }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
