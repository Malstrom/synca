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

          if user.magic_link_expired?
            return render_error(
              code: "token_expired",
              message: I18n.t("services.magic_link.token_expired"),
              status: :unprocessable_entity
            )
          end

          if user.magic_link_already_used?
            return render_error(
              code: "token_already_used",
              message: I18n.t("services.magic_link.token_already_used"),
              status: :unprocessable_entity
            )
          end

          if user.active?
            return render_error(
              code: "account_already_active",
              message: I18n.t("services.magic_link.account_already_active"),
              status: :unprocessable_entity
            )
          end

          case UpdateProfileService.call(
            user: user,
            attrs: { display_name: params.dig(:activation, :profile, :display_name) }
          )
          in Success(profile)
            user.update!(
              magic_link_token: nil,
              account_type: :active
            )

            render_success(
              AuthTokenSerializer.new(
                user: user,
                access_token: AuthTokenService.generate_access_token(user),
                refresh_token: AuthTokenService.generate_refresh_token(user)
              ).serializable_hash
            )
          in Failure([:validation_failed, msg])
            render_error(
              code: "validation_failed",
              message: msg,
              status: :unprocessable_entity
            )
          in Failure([:error, msg])
            render_error(
              code: "internal_error",
              message: msg,
              status: :internal_server_error
            )
          end
        end
      end
    end
  end
end