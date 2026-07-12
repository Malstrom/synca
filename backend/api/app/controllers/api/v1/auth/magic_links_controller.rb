# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MagicLinksController < ApplicationController
        skip_before_action :authenticate_user!

        def create
          case MagicLinkService.resend(email: params[:email])
          in Success(_)
            render json: { message: I18n.t("services.magic_link.resend_success") }, status: :ok
          in Failure([:rate_limited, _])
            render json: { error: I18n.t("services.magic_link.rate_limited") }, status: :too_many_requests
          end
        end
      end
    end
  end
end
