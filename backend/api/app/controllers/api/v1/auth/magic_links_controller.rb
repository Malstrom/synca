# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MagicLinksController < ApplicationController
        include Dry::Monads[:result]

        def create
          email = params[:email]
          user = User.find_by(email: email)

          if user.present?
            result = ResendMagicLinkService.call(user: user)

            case result
            in Failure([:rate_limited, _])
              render json: { error: I18n.t("errors.rate_limited") }, status: :too_many_requests
            end
          end

          render json: { message: I18n.t("magic_link.sent") }
        end
      end
    end
  end
end