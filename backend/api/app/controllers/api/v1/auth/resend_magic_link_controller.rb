# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ResendMagicLinkController < ApplicationController
        include Dry::Monads[:result]

        def create
          user = User.find_by(email: params[:email])

          if user && user.guest? && !rate_limited?(user)
            case MagicLinkService.call(user: user)
            in Success(user)
              GuestMailer.magic_link_email(user).deliver_later
            in Failure([:account_already_active, _])
              # Do nothing, return success to prevent email enumeration
            end
          end

          render_success({ message: I18n.t("resend_magic_link.success") })
        end

        private

        def rate_limited?(user)
          user.magic_link_sent_at && user.magic_link_sent_at > 5.minutes.ago
        end
      end
    end
  end
end