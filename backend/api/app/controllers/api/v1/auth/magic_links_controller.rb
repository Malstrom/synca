# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MagicLinksController < ApplicationController
        skip_before_action :authenticate_user!

        def create
          user = User.find_by(email: params[:email])

          if user && user.guest?
            case MagicLinkService.call(user: user)
            in Success(user)
              GuestMailer.magic_link_email(user).deliver_later
            in Failure([:error, msg])
              Rails.logger.error("Failed to send magic link: #{msg}")
            end
          end

          render json: { message: I18n.t("magic_link.resend_success") }
        end
      end
    end
  end
end