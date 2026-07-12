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
            in Success(user)
              GuestMailer.magic_link_email(user).deliver_later
            in Failure([:rate_limited, _])
              render_too_many_requests(I18n.t("controllers.auth.magic_links.rate_limited"))
            in Failure([:error, msg])
              render_unprocessable_entity(msg)
            end
          end

          render_success({ message: I18n.t("controllers.auth.magic_links.success") })
        end
      end
    end
  end
end
