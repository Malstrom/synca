# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        skip_before_action :authenticate_user!

        def create
          case ActivateAccountService.call(token: params[:token], display_name: params.dig(:profile, :display_name))
          in Success(user)
            render_success({
              access_token: JwtService.access_token(user),
              refresh_token: JwtService.refresh_token(user),
              token_type: "Bearer",
              account_type: user.account_type
            })
          in Failure([:token_not_found, _])
            render_error(:not_found, I18n.t("activations.token_not_found"))
          in Failure([:token_expired, _])
            render_error(:unprocessable_entity, I18n.t("activations.token_expired"))
          in Failure([:token_already_used, _])
            render_error(:unprocessable_entity, I18n.t("activations.token_already_used"))
          in Failure([:account_already_active, _])
            render_error(:unprocessable_entity, I18n.t("activations.account_already_active"))
          end
        end
      end
    end
  end
end