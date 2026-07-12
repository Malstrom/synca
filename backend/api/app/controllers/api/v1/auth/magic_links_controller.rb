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
              # Always return 200 to prevent email enumeration
            in Failure([:error, msg])
              # Log but don't fail the job
              Rails.logger.error("Failed to send magic link to #{user.email}: #{msg}")
            end
          end

          render json: { message: I18n.t("controllers.auth.magic_links.sent") }, status: :ok
        end
      end
    end
  end
end
