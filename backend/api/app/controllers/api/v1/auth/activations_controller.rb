# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        skip_before_action :authenticate_request

        def create
          case ActivateAccountService.call(token: params[:token], display_name: params[:profile][:display_name])
          in Success(user)
            render json: {
              access_token: JwtService.access_token(user),
              refresh_token: JwtService.refresh_token(user),
              token_type: "Bearer",
              account_type: user.account_type
            }
          in Failure([:token_not_found, _])
            render json: { error: I18n.t("controllers.activations.token_not_found") }, status: :not_found
          in Failure([:account_already_active, _])
            render json: { error: I18n.t("controllers.activations.account_already_active") }, status: :unprocessable_entity
          in Failure([:token_expired, _])
            render json: { error: I18n.t("controllers.activations.token_expired") }, status: :unprocessable_entity
          in Failure([:token_already_used, _])
            render json: { error: I18n.t("controllers.activations.token_already_used") }, status: :unprocessable_entity
          in Failure([:validation_failed, _])
            render json: { error: I18n.t("controllers.activations.validation_failed") }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end