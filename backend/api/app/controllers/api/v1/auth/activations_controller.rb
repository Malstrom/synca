# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        skip_before_action :authenticate_user!

        # POST /api/v1/auth/activate
        def create
          user = User.find_by(magic_link_token: params[:token])

          unless user
            return render_error(
              code: "not_found",
              message: I18n.t("controllers.activations.not_found"),
              status: :not_found
            )
          end

          if user.active?
            return render_error(
              code: "account_already_active",
              message: I18n.t("controllers.activations.account_already_active"),
              status: :unprocessable_entity
            )
          end

          if user.magic_link_expired?
            return render_error(
              code: "token_expired",
              message: I18n.t("controllers.activations.token_expired"),
              status: :unprocessable_entity
            )
          end

          if user.magic_link_token != params[:token]
            return render_error(
              code: "token_already_used",
              message: I18n.t("controllers.activations.token_already_used"),
              status: :unprocessable_entity
            )
          end

          user.profile.update!(display_name: params.dig(:profile, :display_name))
          user.update!(account_type: :active)
          user.clear_magic_link_token!

          render_success(auth_response(user))
        end
      end
    end
  end
end