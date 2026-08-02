# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ResendMagicLinkController < ApplicationController
        include Dry::Monads[:result]

        skip_before_action :authenticate_user!

        # POST /api/v1/auth/resend_magic_link
        def create
          case ResendMagicLinkService.call(params: params.to_unsafe_h)
          in Success
            render_success({ message: "If your email is registered, a new link has been sent." })
          in Failure[:validation_failed, contract]
            render_contract_errors(contract)
          in Failure[:rate_limited]
            render_error(code: "rate_limited", message: "Please wait before requesting another magic link", status: :too_many_requests)
          end
        end
      end
    end
  end
end
