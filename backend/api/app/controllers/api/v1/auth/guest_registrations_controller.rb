# frozen_string_literal: true

module Api
  module V1
    module Auth
      class GuestRegistrationsController < ApplicationController
        include Dry::Monads[:result]

        skip_before_action :authenticate_user!

        def create
          case RegisterGuestService.call(params: params.to_unsafe_h)
          in Success(user)
            render_created({
              access_token: JwtService.access_token(user),
              token_type:   "Bearer",
              expires_in:   Settings.auth.guest_token_ttl,
              account_type: user.account_type
            })
          in Failure[:email_already_active, message]
            render_error(code: "email_already_active", message: message, status: :unprocessable_entity)
          in Failure[:validation_failed, result]
            render_contract_errors(result)
          end
        end
      end
    end
  end
end
