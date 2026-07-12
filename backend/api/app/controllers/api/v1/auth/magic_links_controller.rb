# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MagicLinksController < ApplicationController
        skip_before_action :authenticate_request

        def create
          user = User.find_by(email: params[:email])

          if user
            case MagicLinkService.call(user: user)
            in Success(_)
              render json: { message: I18n.t("controllers.magic_links.sent") }
            in Failure([:account_already_active, _])
              render json: { message: I18n.t("controllers.magic_links.sent") }
            in Failure([:rate_limited, _])
              render json: { error: I18n.t("controllers.magic_links.rate_limited") }, status: :too_many_requests
            in Failure([:email_delivery_failed, _])
              render json: { message: I18n.t("controllers.magic_links.sent") }
            end
          else
            render json: { message: I18n.t("controllers.magic_links.sent") }
          end
        end
      end
    end
  end
end
