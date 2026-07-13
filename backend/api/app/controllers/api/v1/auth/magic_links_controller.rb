# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MagicLinksController < ApplicationController
        skip_before_action :authenticate_user!

        # POST /api/v1/auth/resend_magic_link
        def create
          user = User.find_by(email: params.dig(:magic_link, :email)&.downcase)

          case MagicLinkService.call(user: user) if user&.guest?
          in Success(user)
            GuestMailer.magic_link_email(user).deliver_later
            render_success({ message: I18n.t("controllers.magic_links.resend_success") })
          in Failure([:rate_limited, _])
            render_error(
              code: "rate_limited",
              message: I18n.t("controllers.magic_links.rate_limited"),
              status: :too_many_requests
            )
          end
        end
      end
    end
  end
end