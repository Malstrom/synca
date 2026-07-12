# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MagicLinkResendsController < ApplicationController
        skip_before_action :authenticate_request

        def create
          user = User.find_by(email: params[:email])

          if user && user.guest? && user.magic_link_sent_at && user.magic_link_sent_at > 5.minutes.ago
            render json: { error: I18n.t("magic_link_resends.too_soon") }, status: :too_many_requests
            return
          end

          render json: { message: I18n.t("magic_link_resends.success") }, status: :ok

          return unless user && user.guest?

          begin
            MagicLinkService.call(user: user)
            GuestMailer.magic_link_email(user).deliver_later
          rescue StandardError => e
            Rails.logger.error("Failed to resend magic link to user #{user.id}: #{e.message}")
          end
        end
      end
    end
  end
end