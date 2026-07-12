# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        skip_before_action :authenticate_user!

        def create
          case MagicLinkService.validate_token(token: params[:token])
          in Success(user)
            case MagicLinkService.activate(user: user, display_name: params.dig(:profile, :display_name))
            in Success(user)
              render json: {
                access_token: JwtService.access_token(user),
                refresh_token: JwtService.refresh_token(user),
                token_type: "Bearer",
                account_type: user.account_type
              }
            in Failure([:account_already_active, _])
              render json: { error: I18n.t("services.magic_link.account_already_active") }, status: :unprocessable_entity
            in Failure([:error, _])
              render json: { error: I18n.t("errors.internal_server_error") }, status: :internal_server_error
            end
          in Failure([:token_not_found, _])
            render json: { error: I18n.t("services.magic_link.token_not_found") }, status: :not_found
          in Failure([:token_expired, _])
            render json: { error: I18n.t("services.magic_link.token_expired") }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end