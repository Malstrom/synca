# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ResendMagicLinkController < ApplicationController
        include Dry::Monads[:result]

        def create
          case ResendMagicLinkService.call(email: params[:email])
          in Success
            render_success({ message: I18n.t("resend_magic_link.success") })
          in Failure([:rate_limited, _])
            render_error(status: :too_many_requests, code: :rate_limited)
          end
        end
      end
    end
  end
end