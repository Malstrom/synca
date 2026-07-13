# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MagicLinkResendController < ApplicationController
        include Dry::Monads[:result]

        skip_before_action :authenticate_user!

        # POST /api/v1/auth/resend_magic_link
        def create
          case MagicLinkService.resend(params: params.to_unsafe_h)
          in Success
            render_success({ message: I18n.t("magic_link.resend_success") })
          in Failure[:validation_failed, contract]
            render_contract_errors(contract)
          in Failure[:rate_limited]
            render_error(code: "rate_limited", message: I18n.t("errors.auth.rate_limited"), status: :too_many_requests)
          end
        end
      end
    end
  end
end