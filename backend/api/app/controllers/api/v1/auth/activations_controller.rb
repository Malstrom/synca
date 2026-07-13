# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        include Dry::Monads[:result]

        skip_before_action :authenticate_user!

        # POST /api/v1/auth/activate
        def create
          case MagicLinkService.activate(params: params.to_unsafe_h)
          in Success(user)
            render_success(MagicLinkSerializer.new(user).auth_response)
          in Failure[:validation_failed, contract]
            render_contract_errors(contract)
          in Failure[:token_expired]
            render_error(code: "token_expired", message: I18n.t("errors.auth.token_expired"), status: :unprocessable_entity)
          in Failure[:token_already_used]
            render_error(code: "token_already_used", message: I18n.t("errors.auth.token_already_used"), status: :unprocessable_entity)
          in Failure[:account_already_active]
            render_error(code: "account_already_active", message: I18n.t("errors.auth.account_already_active"), status: :unprocessable_entity)
          in Failure[:token_not_found]
            render_error(code: "token_not_found", message: I18n.t("errors.auth.token_not_found"), status: :not_found)
          end
        end
      end
    end
  end
end
