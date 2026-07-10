# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        include Dry::Monads[:result]

        def activate
          case ActivateGuestService.call(user: current_user, token: params[:token], display_name: params.dig(:profile, :display_name))
          in Success({ access_token:, refresh_token:, account_type: })
            render_success({
              access_token: access_token,
              refresh_token: refresh_token,
              token_type: "Bearer",
              account_type: account_type
            })
          in Failure([:account_already_active, _])
            render_error(code: "account_already_active", message: I18n.t("errors.account_already_active"), status: :unprocessable_entity)
          in Failure([:invalid_token, _])
            render_error(code: "invalid_token", message: I18n.t("errors.invalid_token"), status: :unprocessable_entity)
          in Failure([:invalid_purpose, _])
            render_error(code: "invalid_purpose", message: I18n.t("errors.invalid_purpose"), status: :unprocessable_entity)
          in Failure([:token_expired, _])
            render_error(code: "token_expired", message: I18n.t("errors.token_expired"), status: :unprocessable_entity)
          in Failure([:token_mismatch, _])
            render_error(code: "token_mismatch", message: I18n.t("errors.token_mismatch"), status: :unprocessable_entity)
          in Failure([:token_already_used, _])
            render_error(code: "token_already_used", message: I18n.t("errors.token_already_used"), status: :unprocessable_entity)
          in Failure([:validation_failed, message])
            render_error(code: "validation_failed", message: message, status: :unprocessable_entity)
          end
        end

        def resend_magic_link
          case ResendMagicLinkService.call(email: params[:email])
          in Success(message)
            render_success({ message: message })
          in Failure([:rate_limited, _])
            render_error(code: "rate_limited", message: I18n.t("errors.rate_limited"), status: :too_many_requests)
          end
        end
      end
    end
  end
end