# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        skip_before_action :authenticate_user!

        # POST /api/v1/auth/activate
        def create
          user = User.find_by(magic_link_token: params.dig(:token))

          unless user
            return render_error(
              code: "token_not_found",
              message: I18n.t("controllers.api.v1.auth.activations.token_not_found"),
              status: :not_found
            )
          end

          case ActivateUserService.call(user: user, display_name: params.dig(:profile, :display_name)) in
          in Success(user)
            render_success(auth_response(user))
          in Failure([:token_expired, message])
            render_error(code: "token_expired", message: message, status: :unprocessable_entity)
          in Failure([:token_already_used, message])
            render_error(code: "token_already_used", message: message, status: :unprocessable_entity)
          in Failure([:account_already_active, message])
            render_error(code: "account_already_active", message: message, status: :unprocessable_entity)
          end
        end
      end
    end
  end
end