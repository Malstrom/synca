# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        def create
          result = MagicLinkService.activate(
            token: params[:token],
            profile: params[:profile]
          )

          case result
          in Success(user)
            render json: MagicLinkSerializer.new(user).serializable_hash, status: :ok
          in Failure([:not_found, _])
            render json: { error: I18n.t("services.magic_link.token_not_found") }, status: :not_found
          in Failure([:token_expired, _])
            render json: { error: I18n.t("services.magic_link.token_expired") }, status: :unprocessable_entity
          in Failure([:token_already_used, _])
            render json: { error: I18n.t("services.magic_link.token_already_used") }, status: :unprocessable_entity
          in Failure([:account_already_active, _])
            render json: { error: I18n.t("services.magic_link.account_already_active") }, status: :unprocessable_entity
          in Failure([:invalid_profile, _])
            render json: { error: I18n.t("services.magic_link.invalid_profile") }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
