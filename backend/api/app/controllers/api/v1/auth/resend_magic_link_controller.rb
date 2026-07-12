# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ResendMagicLinkController < Api::V1::BaseController
        include Dry::Monads[:result]

        def create
          result = ResendMagicLinkContract.new.call(params)

          case result
          in Success
            user = User.find_by(email: params[:email])
            if user && user.account_type == "guest" && user.magic_link_sent_at.nil? || user.magic_link_sent_at < 5.minutes.ago
              MagicLinkService.call(user: user)
              GuestMailer.magic_link_email(user).deliver_later
            end

            render_success({ message: I18n.t("resend_magic_link.success") })
          in Failure(errors)
            render_error(errors, status: :unprocessable_entity)
          end
        end
      end
    end
  end
end