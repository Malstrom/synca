# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        skip_before_action :authenticate_user!

        # POST /api/v1/auth/activate
        def create
          user = User.find_by(magic_link_token: params.dig(:activation, :token))

          unless user
            return render_error(
              code: "not_found",
              message: I18n.t("services.magic_link.token_not_found"),
              status: :not_found
            )
          end

          case ActivateUserService.call(user: user, display_name: params.dig(:activation, :profile, :display_name))
          in Success(user)
            render_success(
              auth_response(user)
            )
          in Failure([:token_expired, _])
            render_error(
              code: "token_expired",
              message: I18n.t("services.magic_link.token_expired"),
              status: :unprocessable_entity
            )
          in Failure([:token_already_used, _])
            render_error(
              code: "token_already_used",
              message: I18n.t("services.magic_link.token_already_used"),
              status: :unprocessable_entity
            )
          in Failure([:account_already_active, _])
            render_error(
              code: "account_already_active",
              message: I18n.t("services.magic_link.account_already_active"),
              status: :unprocessable_entity
            )
          in Failure([:validation_failed, msg])
            render_error(
              code: "validation_failed",
              message: msg,
              status: :unprocessable_entity
            )
          end
        end
      end
    end
  end
end