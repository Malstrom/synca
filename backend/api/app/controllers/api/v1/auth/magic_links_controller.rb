# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MagicLinksController < ApplicationController
        skip_before_action :authenticate_user!

        # POST /api/v1/auth/resend_magic_link
        def create
          case MagicLinkService.call(user: User.find_by(email: params[:email]&.downcase))
          in Success(_)
            render_success({ message: I18n.t("controllers.magic_links.resend_success") })
          in Failure([:rate_limited, _])
            render_error(
              code: "rate_limited",
              message: I18n.t("controllers.magic_links.rate_limited"),
              status: :too_many_requests
            )
          in Failure([:already_active, _])
            render_success({ message: I18n.t("controllers.magic_links.resend_success") })
          in Failure([:error, _])
            render_success({ message: I18n.t("controllers.magic_links.resend_success") })
          end
        end
      end
    end
  end
end