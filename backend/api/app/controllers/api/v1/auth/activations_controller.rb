# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        include Dry::Monads[:result]

        def create
          token = params[:token]
          display_name = params.dig(:profile, :display_name)

          result = ActivateAccountService.call(
            user: current_user,
            token: token,
            display_name: display_name
          )

          case result
          in Success(user)
            access_token = JwtService.access_token(user)
            refresh_token = JwtService.refresh_token(user)

            render json: {
              access_token: access_token,
              refresh_token: refresh_token,
              token_type: "Bearer",
              account_type: user.account_type
            }
          in Failure([:token_expired, _])
            render json: { error: I18n.t("errors.token_expired") }, status: :unprocessable_entity
          in Failure([:token_already_used, _])
            render json: { error: I18n.t("errors.token_already_used") }, status: :unprocessable_entity
          in Failure([:invalid_user, _])
            render json: { error: I18n.t("errors.account_already_active") }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
