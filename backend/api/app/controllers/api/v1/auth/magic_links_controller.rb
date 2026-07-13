# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MagicLinksController < ApplicationController
        skip_before_action :authenticate_user!

        # POST /api/v1/auth/resend_magic_link
        def create
          user = User.find_by(email: params.dig(:magic_link, :email)&.downcase)

          if user&.guest?
            case MagicLinkService.call(user: user)
            in Success(_)
              GuestMailer.with(user: user).magic_link_email.deliver_later
            in Failure([:rate_limited, _])
              return render_error(
                code: "rate_limited",
                message: I18n.t("services.magic_link.rate_limited"),
                status: :too_many_requests
              )
            in Failure([:error, msg])
              Rails.logger.error("Failed to generate magic link: #{msg}")
            end
          end

          render_success(
            message: I18n.t("services.magic_link.resend_success")
          )
        end
      end
    end
  end
end