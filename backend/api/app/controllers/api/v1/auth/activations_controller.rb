# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        skip_before_action :authenticate_user!

        def create
          case MagicLinkService.activate(token: params[:token], display_name: params.dig(:profile, :display_name))
          in Success(user)
            render json: JwtService.encode(user_id: user.id), status: :ok
          in Failure([:not_found, _])
            render json: { error: I18n.t("services.magic_link.not_found") }, status: :not_found
          in Failure([:token_expired, _])
            render json: { error: I18n.t("services.magic_link.token_expired") }, status: :unprocessable_entity
          in Failure([:token_already_used, _])
            render json: { error: I18n.t("services.magic_link.token_already_used") }, status: :unprocessable_entity
          in Failure([:account_already_active, _])
            render json: { error: I18n.t("services.magic_link.account_already_active") }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end