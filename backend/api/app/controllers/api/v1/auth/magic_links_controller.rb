# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MagicLinksController < ApplicationController
        skip_before_action :authenticate_user!

        # POST /api/v1/auth/resend_magic_link
        def create
          user = User.find_by(email: params.dig(:email)&.downcase)

          case MagicLinkService.call(user: user) in
          in Success(user)
            GuestMailer.magic_link_email(user).deliver_later
            render_success({ message: I18n.t("controllers.api.v1.auth.magic_links.resend_success") })
          in Failure([:rate_limited, message])
            render_error(code: "rate_limited", message: message, status: :too_many_requests)
          in Failure([:account_already_active, message])
            render_success({ message: I18n.t("controllers.api.v1.auth.magic_links.resend_success") })
          end
        end
      end
    end
  end
end