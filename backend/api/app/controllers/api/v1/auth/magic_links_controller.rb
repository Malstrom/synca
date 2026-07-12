# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MagicLinksController < ApplicationController
        skip_before_action :authenticate_request

        def create
          email = params.require(:email)
          user = User.find_by(email: email)

          if user && user.guest? && user.magic_link_sent_at && user.magic_link_sent_at > 5.minutes.ago
            render json: { error: I18n.t("errors.rate_limited") }, status: :too_many_requests
            return
          end

          render json: { message: I18n.t("magic_link.resent") }, status: :ok

          return unless user && user.guest?

          case MagicLinkService.call(user: user)
          in Success(user)
            GuestMailer.magic_link_email(user).deliver_later
          in Failure([:account_already_active, _])
            # Skip already active accounts
          in Failure([:error, msg])
            Rails.logger.error("Failed to generate magic link for user #{user.id}: #{msg}")
          end
        end
      end
    end
  end
end