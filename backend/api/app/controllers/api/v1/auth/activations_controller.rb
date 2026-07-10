# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        include Dry::Monads[:result]

        def activate
          result = ActivateGuestService.call(
            token: params[:token],
            display_name: params.dig(:profile, :display_name)
          )

          case result
          in Success({ access_token:, refresh_token:, account_type: })
            render_success(
              {
                access_token: access_token,
                refresh_token: refresh_token,
                token_type: "Bearer",
                account_type: account_type
              }
            )
          in Failure[:invalid_token, _]
            render_error(
              code: "invalid_token",
              message: I18n.t("contracts.errors.token.invalid"),
              status: :unprocessable_entity
            )
          in Failure[:token_already_used, _]
            render_error(
              code: "token_already_used",
              message: I18n.t("contracts.errors.token.already_used"),
              status: :unprocessable_entity
            )
          in Failure[:account_already_active, _]
            render_error(
              code: "account_already_active",
              message: I18n.t("contracts.errors.account.already_active"),
              status: :unprocessable_entity
            )
          in Failure[:validation_failed, message]
            render_error(
              code: "validation_failed",
              message: message,
              status: :unprocessable_entity
            )
          end
        end

        def resend_magic_link
          result = ResendMagicLinkService.call(email: params[:email])

          case result
          in Success
            render_success(
              { message: I18n.t("auth.magic_link.resent") }
            )
          in Failure[:rate_limit_exceeded, _]
            render_error(
              code: "rate_limit_exceeded",
              message: I18n.t("contracts.errors.magic_link.rate_limit"),
              status: :too_many_requests
            )
          in Failure[:validation_failed, message]
            render_error(
              code: "validation_failed",
              message: message,
              status: :unprocessable_entity
            )
          end
        end
      end
    end
  end
end

---