# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MagicLinksController < ApplicationController
        skip_before_action :authenticate_user!

        def create
          user = User.find_by(email: params[:email])

          if user
            case MagicLinkService.call(user: user)
            in Success(_)
              # Always return success to prevent email enumeration
            in Failure([:account_already_active, _])
              # Always return success to prevent email enumeration
            in Failure([:rate_limited, _])
              render json: { error: I18n.t("services.magic_link.rate_limited") }, status: :too_many_requests
            in Failure([:error, _])
              render json: { error: I18n.t("errors.internal_server_error") }, status: :internal_server_error
            end
          end

          render json: { message: I18n.t("services.magic_link.resend_success") }
        end
      end
    end
  end
end