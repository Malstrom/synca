# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MagicLinksController < ApplicationController
        skip_before_action :authenticate_user!

        def create
          user = User.find_by(email: params[:email])

          if user && user.guest?
            if user.magic_link_sent_at && user.magic_link_sent_at > 5.minutes.ago
              render_error(:too_many_requests, I18n.t("magic_links.rate_limited"))
            else
              MagicLinkService.call(user: user)
              GuestMailer.magic_link_email(user).deliver_later
            end
          end

          render_success({ message: I18n.t("magic_links.sent") })
        end
      end
    end
  end
end
