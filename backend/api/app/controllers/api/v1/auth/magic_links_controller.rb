# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MagicLinksController < ApplicationController
        include Dry::Monads[:result]

        skip_before_action :authenticate_user!

        # POST /api/v1/auth/resend_magic_link
        def create
          case MagicLinkService.resend(email: params[:email])
          in Success(_)
            render_success({ message: I18n.t("services.magic_link.resend_success") })
          in Failure([:rate_limited, message])
            render_error(code: "rate_limited", message: message, status: :too_many_requests)
          end
        end
      end
    end
  end
end