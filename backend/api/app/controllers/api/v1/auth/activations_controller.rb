# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        skip_before_action :authenticate_user!

        def create
          case MagicLinkService.activate(token: params[:token], display_name: params[:profile][:display_name])
          in Success(user)
            render json: {
              access_token:  JwtService.access_token(user),
              refresh_token: JwtService.refresh_token(user),
              token_type:    "Bearer",
              account_type:  user.account_type
            }
          in Failure([:token_not_found, _])
            render json: { error: I18n.t("controllers.auth.activations.token_not_found") }, status: :not_found
          in Failure([:token_expired, _])
            render json: { error: I18n.t("controllers.auth.activations.token_expired") }, status: :unprocessable_entity
          in Failure([:account_already_active, _])
            render json: { error: I18n.t("controllers.auth.activations.account_already_active") }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end