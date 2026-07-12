# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MagicLinksController < ApplicationController
        skip_before_action :authenticate_request

        def create
          user = User.find_by(email: params[:email])

          if user && user.magic_link_sent_at && user.magic_link_sent_at > 5.minutes.ago
            render json: { error: "Too many requests" }, status: :too_many_requests
            return
          end

          if user
            MagicLinkService.call(user: user)
            GuestMailer.magic_link_email(user).deliver_later
          end

          render json: { message: "If your email is registered, a new link has been sent." }, status: :ok
        end
      end
    end
  end
end
